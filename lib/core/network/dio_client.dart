import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../services/error_reporter_service.dart';
import '../services/models/error_report.dart';
import 'api_interceptor.dart';

class DioClient {
  late final Dio _dio;

  DioClient({required ApiInterceptor apiInterceptor}) {
    _dio = Dio(
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
    _dio.interceptors.add(apiInterceptor);
    _dio.interceptors.add(_buildErrorReporterInterceptor());
  }

  /// E28 — Capture les DioException et les envoie au backend.
  ///
  /// L'endpoint /errors lui-même est exclu pour éviter les boucles infinies :
  /// si l'upload d'une erreur échoue, on ne génère pas une nouvelle erreur
  /// à uploader.
  InterceptorsWrapper _buildErrorReporterInterceptor() {
    return InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) {
        final path = error.requestOptions.path;
        // Exclure les appels à /errors pour éviter les cycles.
        if (!path.contains(ApiConstants.clientErrors)) {
          ErrorReporterService.instance.report(ErrorReport(
            platform: detectPlatform(),
            appVersion: ErrorReporterService.instance.appVersion,
            errorType: 'DioException',
            message: error.message ?? error.type.name,
            stackTrace: error.stackTrace.toString(),
            httpStatus: error.response?.statusCode,
            httpUrl: '${error.requestOptions.baseUrl}${error.requestOptions.path}',
            occurredAt: DateTime.now(),
          ));
        }
        handler.next(error);
      },
    );
  }

  Dio get dio => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.put(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.delete(path, data: data, queryParameters: queryParameters);
  }
}
