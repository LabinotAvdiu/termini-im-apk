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

  ApiException _mapDioException(DioException e) => mapDioException(e);
}
