import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/my_company_model.dart';

/// Remote datasource for all authenticated owner operations on /my-company.
class MyCompanyRemoteDatasource {
  final DioClient _client;

  const MyCompanyRemoteDatasource({required DioClient client})
      : _client = client;

  // ── Company ───────────────────────────────────────────────────────────────

  Future<MyCompanyModel> getMyCompany() async {
    try {
      final response = await _client.get(ApiConstants.myCompany);
      return MyCompanyModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<MyCompanyModel> updateCompany(Map<String, dynamic> data) async {
    try {
      final response = await _client.put(ApiConstants.myCompany, data: data);
      return MyCompanyModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Categories ────────────────────────────────────────────────────────────

  Future<List<MyCategoryModel>> getCategories() async {
    try {
      final response = await _client.get(ApiConstants.myCompanyCategories);
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => MyCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<MyCategoryModel> createCategory(String name) async {
    try {
      final response = await _client.post(
        ApiConstants.myCompanyCategories,
        data: {'name': name},
      );
      return MyCategoryModel.fromJson(
        (response.data['data'] ?? response.data) as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<MyCategoryModel> updateCategory(String id, String name) async {
    try {
      final response = await _client.put(
        ApiConstants.myCompanyCategory(id),
        data: {'name': name},
      );
      return MyCategoryModel.fromJson(
        (response.data['data'] ?? response.data) as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _client.delete(ApiConstants.myCompanyCategory(id));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Services ──────────────────────────────────────────────────────────────

  Future<MyServiceModel> createService(Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        ApiConstants.myCompanyServices,
        data: data,
      );
      return MyServiceModel.fromJson(
        (response.data['data'] ?? response.data) as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<MyServiceModel> updateService(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _client.put(
        ApiConstants.myCompanyService(id),
        data: data,
      );
      return MyServiceModel.fromJson(
        (response.data['data'] ?? response.data) as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> deleteService(String id) async {
    try {
      await _client.delete(ApiConstants.myCompanyService(id));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Employees ─────────────────────────────────────────────────────────────

  Future<List<MyEmployeeModel>> getEmployees() async {
    try {
      final response = await _client.get(ApiConstants.myCompanyEmployees);
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => MyEmployeeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<MyEmployeeModel> inviteEmployee({
    required String email,
    required List<String> specialties,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.myCompanyEmployeesInvite,
        data: {'email': email, 'specialties': specialties},
      );
      return MyEmployeeModel.fromJson(
        (response.data['data'] ?? response.data) as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<MyEmployeeModel> createEmployee(Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        ApiConstants.myCompanyEmployeesCreate,
        data: data,
      );
      return MyEmployeeModel.fromJson(
        (response.data['data'] ?? response.data) as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<MyEmployeeModel> updateEmployee(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _client.put(
        ApiConstants.myCompanyEmployee(id),
        data: data,
      );
      return MyEmployeeModel.fromJson(
        (response.data['data'] ?? response.data) as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> removeEmployee(String id) async {
    try {
      await _client.delete(ApiConstants.myCompanyEmployee(id));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Opening hours ─────────────────────────────────────────────────────────

  Future<List<OpeningHourModel>> updateHours(
      List<OpeningHourModel> hours) async {
    try {
      final response = await _client.put(
        ApiConstants.myCompanyHours,
        data: {'hours': hours.map((h) => h.toJson()).toList()},
      );
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body['hours']) as List<dynamic>? ?? [];
      return data
          .map((e) => OpeningHourModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Error mapping ─────────────────────────────────────────────────────────

  ApiException _mapDioException(DioException e) {
    final wrapped = e.error;
    if (wrapped is ApiException) return wrapped;
    final statusCode = e.response?.statusCode;
    String? msg;
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      msg = data['message'] as String?;
    }
    if (statusCode == 401) {
      return UnauthorizedException(message: msg ?? 'Non autorisé');
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
