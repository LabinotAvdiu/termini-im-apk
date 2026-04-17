import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/my_company_model.dart';
import '../models/planning_appointment_model.dart';

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

  // ── Booking settings ──────────────────────────────────────────────────────

  Future<void> updateBookingSettings(String bookingMode) async {
    try {
      await _client.put(
        ApiConstants.myCompanyBookingSettings,
        data: {'booking_mode': bookingMode},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Company breaks ────────────────────────────────────────────────────────

  Future<List<CompanyBreakModel>> getBreaks() async {
    try {
      final response = await _client.get(ApiConstants.myCompanyBreaks);
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as List<dynamic>? ?? [];
      return data
          .map((e) => CompanyBreakModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<CompanyBreakModel> createBreak(Map<String, dynamic> data) async {
    try {
      final response =
          await _client.post(ApiConstants.myCompanyBreaks, data: data);
      final body = response.data as Map<String, dynamic>;
      return CompanyBreakModel.fromJson(
          (body['data'] ?? body) as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> deleteBreak(String id) async {
    try {
      await _client.delete(ApiConstants.myCompanyBreak(id));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Capacity overrides ────────────────────────────────────────────────────

  Future<List<CapacityOverrideModel>> getCapacityOverrides() async {
    try {
      final response =
          await _client.get(ApiConstants.myCompanyCapacityOverrides);
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as List<dynamic>? ?? [];
      return data
          .map((e) =>
              CapacityOverrideModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<CapacityOverrideModel> createCapacityOverride(
      Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
          ApiConstants.myCompanyCapacityOverrides,
          data: data);
      final body = response.data as Map<String, dynamic>;
      return CapacityOverrideModel.fromJson(
          (body['data'] ?? body) as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> deleteCapacityOverride(String id) async {
    try {
      await _client.delete(ApiConstants.myCompanyCapacityOverride(id));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Company planning appointments ────────────────────────────────────────

  Future<List<PlanningAppointmentModel>> listCompanyAppointments(
    String date, {
    List<String> statuses = const ['confirmed', 'pending'],
  }) async {
    try {
      final url = ApiConstants.myCompanyAppointments(date, statuses);
      final response = await _client.get(url);
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as List<dynamic>? ?? [];
      return data
          .map((e) =>
              PlanningAppointmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Walk-in (owner creates confirmed appointment on-the-spot) ────────────

  Future<Map<String, dynamic>> storeCompanyWalkIn(
      Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        ApiConstants.myCompanyWalkIn,
        data: data,
      );
      final body = response.data as Map<String, dynamic>;
      return (body['data'] ?? body) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Pending appointments ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPendingAppointments() async {
    try {
      final response =
          await _client.get(ApiConstants.myCompanyPendingAppointments);
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as List<dynamic>? ?? [];
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> updateAppointmentStatus(
      String id, String status) async {
    try {
      await _client.put(
        ApiConstants.myCompanyAppointmentStatus(id),
        data: {'status': status},
      );
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
