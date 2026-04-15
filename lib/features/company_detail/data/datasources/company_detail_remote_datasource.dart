import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/company_detail_model.dart';

class CompanyDetailRemoteDatasource {
  final DioClient _client;

  const CompanyDetailRemoteDatasource({required DioClient client})
      : _client = client;

  Future<CompanyDetailModel> getCompanyDetail(String companyId) async {
    try {
      final response = await _client.get(
        ApiConstants.companyDetail(companyId),
      );
      return CompanyDetailModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<List<EmployeeModel>> getEmployees(String companyId) async {
    try {
      final response = await _client.get(
        ApiConstants.companyEmployees(companyId),
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  ApiException _mapDioException(DioException e) {
    final wrapped = e.error;
    if (wrapped is ApiException) return wrapped;
    final statusCode = e.response?.statusCode;
    String? msg;
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      msg = data['message'] as String?;
    }
    if (statusCode == 404) {
      return NotFoundException(message: msg ?? 'Salon introuvable');
    }
    if (statusCode != null && statusCode >= 500) {
      return ServerException(message: msg ?? 'Erreur serveur');
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkException();
    }
    return ApiException(
      message: msg ?? e.message ?? 'Erreur inconnue',
      statusCode: statusCode,
    );
  }
}
