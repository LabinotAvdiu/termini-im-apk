import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'api_exceptions.dart';

class ApiInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  ApiInterceptor({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

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
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;

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
}
