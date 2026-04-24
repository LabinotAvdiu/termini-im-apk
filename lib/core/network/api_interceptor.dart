import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import 'api_exceptions.dart';

/// HTTP interceptor for the app-wide Dio client.
///
/// Responsibilities:
/// 1. Attach the current Bearer token to outgoing requests.
/// 2. On a 401 response, transparently refresh the access token using the
///    stored refresh token, then replay the original request. Concurrent
///    401s are coalesced into a single refresh (single-flight pattern).
/// 3. Map typed errors (401/404/5xx/network) to [ApiException] subclasses.
///
/// If the refresh token itself is missing, expired, or rejected, the
/// interceptor clears local session storage and bubbles up an
/// [UnauthorizedException] so the auth layer can redirect to login.
class ApiInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  /// Separate Dio instance used *only* for the refresh call, so the refresh
  /// request itself never goes through this interceptor (which would cause
  /// infinite recursion on a 401-on-refresh).
  late final Dio _refreshDio;

  /// In-flight refresh; when non-null, every concurrent 401 awaits this same
  /// future instead of triggering parallel /auth/refresh calls.
  Completer<String?>? _refreshCompleter;

  /// In-memory fallback for the refresh token when the user signed in with
  /// rememberMe=false (nothing persisted to secure storage). Set by the
  /// AuthRepository whenever a session is established.
  String? _memoryRefreshToken;

  ApiInterceptor({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// Called by AuthRepository when a session without rememberMe is
  /// established, so the interceptor can still refresh while the app is
  /// running (nothing was persisted to secure storage in that mode).
  void setMemoryRefreshToken(String? token) {
    _memoryRefreshToken = token;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;

    // Try a transparent refresh on 401 — except on auth endpoints themselves,
    // where a 401 means "bad credentials / expired refresh", not "access
    // token expired". That avoids an infinite refresh loop.
    if (statusCode == 401 && !_isAuthEndpoint(path)) {
      final newToken = await _refreshAccessToken();

      if (newToken != null) {
        try {
          // Replay the original request with the fresh token. Use the
          // dedicated _refreshDio so we don't re-enter this interceptor.
          final retried = await _refreshDio.fetch(
            err.requestOptions..headers['Authorization'] = 'Bearer $newToken',
          );
          handler.resolve(retried);
          return;
        } on DioException catch (retryErr) {
          handler.reject(retryErr);
          return;
        }
      }

      // Refresh failed — wipe local session and surface an unauthorized
      // error so the auth layer can redirect to /login.
      await _clearLocalSession();
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const UnauthorizedException(),
        ),
      );
      return;
    }

    switch (statusCode) {
      case 401:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const UnauthorizedException(),
          ),
        );
        return;
      case 404:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const NotFoundException(),
          ),
        );
        return;
      case final code when code != null && code >= 500:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const ServerException(),
          ),
        );
        return;
      default:
        if (err.type == DioExceptionType.connectionError ||
            err.type == DioExceptionType.connectionTimeout) {
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: const NetworkException(),
            ),
          );
          return;
        }
    }

    handler.next(err);
  }

  /// Single-flight refresh: concurrent callers share the same future.
  /// Returns the new access token, or null when refresh is not possible
  /// (no refresh token, or refresh rejected by the server).
  Future<String?> _refreshAccessToken() async {
    final inflight = _refreshCompleter;
    if (inflight != null) return inflight.future;

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    try {
      final refreshToken =
          await _storage.read(key: AppConstants.refreshTokenKey) ??
              _memoryRefreshToken;

      if (refreshToken == null || refreshToken.isEmpty) {
        completer.complete(null);
        return null;
      }

      final response = await _refreshDio.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final raw = response.data;
      final payload = raw is Map<String, dynamic>
          ? (raw['data'] is Map<String, dynamic>
              ? raw['data'] as Map<String, dynamic>
              : raw)
          : const <String, dynamic>{};

      final newAccess = payload['token'] as String?;
      final newRefresh = payload['refresh_token'] as String?;

      if (newAccess == null || newAccess.isEmpty) {
        completer.complete(null);
        return null;
      }

      // Persist the new pair. For rememberMe=false sessions, secure storage
      // is empty — we still update the in-memory copy so the app keeps
      // functioning until it's killed.
      final wasPersisted =
          await _storage.read(key: AppConstants.refreshTokenKey) != null;

      if (wasPersisted) {
        await _storage.write(key: AppConstants.tokenKey, value: newAccess);
        if (newRefresh != null && newRefresh.isNotEmpty) {
          await _storage.write(
            key: AppConstants.refreshTokenKey,
            value: newRefresh,
          );
        }
        await _storage.write(
          key: AppConstants.lastRefreshKey,
          value: DateTime.now().toIso8601String(),
        );
      } else {
        // Non-persistent session: update memory only.
        if (newRefresh != null && newRefresh.isNotEmpty) {
          _memoryRefreshToken = newRefresh;
        }
        // onRequest reads the access token from secure storage, so in the
        // non-persistent case we intentionally do NOT write the access
        // token there — instead the next request will rely on the explicit
        // Authorization header set during replay, and subsequent requests
        // will 401-refresh again. This is a deliberate trade-off: no token
        // ever touches disk when the user chose "don't remember me".
      }

      completer.complete(newAccess);
      return newAccess;
    } catch (_) {
      completer.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Wipe every session-related key so the next app launch starts clean.
  Future<void> _clearLocalSession() async {
    _memoryRefreshToken = null;
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userRoleKey);
    await _storage.delete(key: AppConstants.rememberMeKey);
    await _storage.delete(key: AppConstants.lastRefreshKey);
  }

  bool _isAuthEndpoint(String path) {
    // A 401 on any of these means "credentials are bad" or "refresh itself
    // expired" — retrying via refresh would just loop.
    const noRetryPaths = [
      '/auth/login',
      '/auth/refresh',
      '/auth/register',
      '/auth/google',
      '/auth/facebook',
      '/auth/apple',
      '/auth/forgot-password',
      '/auth/reset-password',
      '/auth/verify-email',
      '/auth/resend-verification',
    ];
    return noRetryPaths.any(path.endsWith);
  }
}
