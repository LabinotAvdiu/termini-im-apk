import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show VoidCallback, debugPrint;
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
  Completer<_RefreshResult>? _refreshCompleter;

  /// In-memory fallback for the refresh token when the user signed in with
  /// rememberMe=false (nothing persisted to secure storage). Set by the
  /// AuthRepository whenever a session is established.
  String? _memoryRefreshToken;

  /// Callback fired when the refresh token is rejected by the server (i.e.
  /// the user's session is genuinely over — not a transient network error).
  /// Wired in dio_provider.dart to flip `AuthState.sessionExpired` so the
  /// global overlay can show the "vous n'êtes pas connecté" modal.
  VoidCallback? _onSessionExpired;

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

  /// Wire the session-expired callback from a Riverpod provider. Called once
  /// during dio_provider construction.
  void setOnSessionExpired(VoidCallback? callback) {
    _onSessionExpired = callback;
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
      final result = await _refreshAccessToken();

      if (result.token != null) {
        try {
          // Replay the original request with the fresh token. Use the
          // dedicated _refreshDio so we don't re-enter this interceptor.
          final retried = await _refreshDio.fetch(
            err.requestOptions
              ..headers['Authorization'] = 'Bearer ${result.token}',
          );
          handler.resolve(retried);
          return;
        } on DioException catch (retryErr) {
          handler.reject(retryErr);
          return;
        }
      }

      // Refresh failed. Three cases:
      //
      //  1. The refresh token was actually rejected by the server (real 401
      //     on /auth/refresh). The session is genuinely over -> wipe local
      //     state, fire the session-expired callback so the global overlay
      //     can show the modal.
      //
      //  2. Refresh failed because of a transient error (network blip,
      //     timeout, 5xx, server briefly down). The refresh token is still
      //     valid, the user is still logged in — we MUST NOT wipe the
      //     session, or every brief offline moment would force a re-login.
      //     Just bubble up the original 401 as a NetworkException.
      //
      //  3. There was no refresh token to attempt with (guest browsing or
      //     in-flight request racing a fresh login). Bubble up Unauthorized
      //     but DO NOT show the modal — there's no session to expire.
      debugPrint('[interceptor] 401 on $path — refresh result: '
          'rejected=${result.rejected} noSession=${result.noSession} '
          'tokenNull=${result.token == null}');
      if (result.rejected) {
        debugPrint('[interceptor] refresh REJECTED → wipe + onSessionExpired');
        await _clearLocalSession();
        if (_onSessionExpired == null) {
          debugPrint('[interceptor] WARNING: _onSessionExpired callback is NULL '
              '(wiring failed in main.dart?)');
        } else {
          debugPrint('[interceptor] calling _onSessionExpired callback');
          _onSessionExpired!.call();
        }
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const UnauthorizedException(),
          ),
        );
      } else if (result.noSession) {
        debugPrint('[interceptor] noSession → reject with Unauthorized, no modal');
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const UnauthorizedException(),
          ),
        );
      } else {
        debugPrint('[interceptor] transient → reject with Network');
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const NetworkException(),
          ),
        );
      }
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

  /// Single-flight refresh: concurrent callers share the same future. The
  /// returned [_RefreshResult] tells the caller whether the refresh
  /// succeeded, was rejected by the server (real expired/revoked token), or
  /// failed for transient reasons (network/timeout/5xx) — the caller acts
  /// differently in each case (only the `rejected` case wipes the session).
  Future<_RefreshResult> _refreshAccessToken() async {
    final inflight = _refreshCompleter;
    if (inflight != null) return inflight.future;

    final completer = Completer<_RefreshResult>();
    _refreshCompleter = completer;

    try {
      final refreshToken =
          await _storage.read(key: AppConstants.refreshTokenKey) ??
              _memoryRefreshToken;

      if (refreshToken == null || refreshToken.isEmpty) {
        // No refresh token at all — either the user is browsing as a guest
        // (never had a session) or they're in the middle of a fresh login
        // and an in-flight request from before is racing the login. Either
        // way, don't fire the session-expired modal: there's no session to
        // expire. Just bubble the 401 up as Unauthorized.
        completer.complete(const _RefreshResult.noSession());
        return completer.future;
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
        // Server replied 200 but with no token? Treat as transient — the
        // refresh token is still recorded as valid on the backend.
        completer.complete(const _RefreshResult.transient());
        return completer.future;
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

      completer.complete(_RefreshResult.success(newAccess));
      return completer.future;
    } on DioException catch (e) {
      // 401 on /auth/refresh = the refresh token itself is rejected. Real
      // logout. Anything else (timeout, no network, 5xx, etc.) is transient
      // and must NOT clear the user's session.
      final isRejection = e.response?.statusCode == 401;
      completer.complete(
        isRejection
            ? const _RefreshResult.rejected()
            : const _RefreshResult.transient(),
      );
      return completer.future;
    } catch (_) {
      completer.complete(const _RefreshResult.transient());
      return completer.future;
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

/// Outcome of a refresh attempt — drives whether we wipe the session and/or
/// fire the "session expired" modal.
///   * [_RefreshResult.success]    — refresh succeeded, replay the request.
///   * [_RefreshResult.rejected]   — /auth/refresh returned 401, the user's
///                                   session is genuinely over → wipe the
///                                   local session AND show the modal.
///   * [_RefreshResult.transient]  — network/timeout/5xx during refresh →
///                                   keep the session intact, surface a
///                                   NetworkException so the user can retry.
///   * [_RefreshResult.noSession]  — no refresh token to attempt with (guest
///                                   browsing, or in-flight request from a
///                                   logged-out screen) → bubble up as
///                                   Unauthorized but DO NOT show the modal,
///                                   there's no session to expire.
class _RefreshResult {
  final String? token;
  final bool rejected;
  final bool noSession;

  const _RefreshResult.success(String this.token)
      : rejected = false,
        noSession = false;
  const _RefreshResult.rejected()
      : token = null,
        rejected = true,
        noSession = false;
  const _RefreshResult.transient()
      : token = null,
        rejected = false,
        noSession = false;
  const _RefreshResult.noSession()
      : token = null,
        rejected = false,
        noSession = true;
}
