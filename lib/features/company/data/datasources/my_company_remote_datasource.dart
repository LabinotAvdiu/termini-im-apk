import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/gallery_photo_model.dart';
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

  /// Owner planning — fetch a single day.
  /// Default status filter covers every state that occupies or recently
  /// occupied the slot, so the owner keeps an honest timeline. `rejected`
  /// is included because it still blocks capacity and shows the motif +
  /// the "Free the slot" action.
  Future<List<PlanningAppointmentModel>> listCompanyAppointments(
    String date, {
    List<String> statuses = const [
      'confirmed',
      'pending',
      'no_show',
      'cancelled',
      'rejected',
    ],
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

  /// Owner planning — fetch a date range (week / month views). Same status
  /// default as `listCompanyAppointments` so the month grid counts reflect
  /// the real activity including no-shows, cancellations and rejections.
  Future<List<PlanningAppointmentModel>> listCompanyAppointmentsRange(
    String start,
    String end, {
    List<String> statuses = const [
      'confirmed',
      'pending',
      'no_show',
      'cancelled',
      'rejected',
    ],
  }) async {
    try {
      final response = await _client.get(
        '/my-company/appointments',
        queryParameters: {
          'start': start,
          'end': end,
          if (statuses.isNotEmpty) 'status': statuses.join(','),
        },
      );
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
    String id,
    String status, {
    String? reason,
  }) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (reason != null && reason.trim().isNotEmpty) {
        body['reason'] = reason.trim();
      }
      await _client.put(
        ApiConstants.myCompanyAppointmentStatus(id),
        data: body,
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

  // ── Gallery ───────────────────────────────────────────────────────────────

  Future<List<GalleryPhotoModel>> listGallery() async {
    try {
      final response = await _client.get(ApiConstants.myCompanyGallery);
      final body = response.data as Map<String, dynamic>;
      final data = (body['data'] ?? body) as List<dynamic>? ?? [];
      return data
          .map((e) => GalleryPhotoModel.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Uploads a gallery photo from raw bytes. Works on both mobile (dart:io
  /// File can't be used on Flutter Web) and web (XFile.readAsBytes).
  Future<GalleryPhotoModel> uploadGalleryPhoto({
    required Uint8List bytes,
    required String filename,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          bytes,
          filename: filename,
        ),
      });
      final response = await _client.dio.post(
        '${_client.dio.options.baseUrl}${ApiConstants.myCompanyGallery}',
        data: formData,
        // Do NOT set Content-Type manually — Dio adds the correct boundary.
        onSendProgress: onSendProgress,
      );
      final body = response.data as Map<String, dynamic>;
      return GalleryPhotoModel.fromJson(
        (body['data'] ?? body) as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> deleteGalleryPhoto(String id) async {
    try {
      await _client.delete(ApiConstants.myCompanyGalleryPhoto(id));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> reorderGalleryPhotos(List<String> orderedIds) async {
    try {
      await _client.post(
        ApiConstants.myCompanyGalleryReorder,
        data: {'ids': orderedIds},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Error mapping ─────────────────────────────────────────────────────────

  ApiException _mapDioException(DioException e) => mapDioException(e);
}
