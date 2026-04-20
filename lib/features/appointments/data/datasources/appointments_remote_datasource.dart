import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/appointment_model.dart';

class AppointmentsRemoteDatasource {
  final DioClient _client;

  const AppointmentsRemoteDatasource({required DioClient client})
      : _client = client;

  /// GET /bookings — returns the authenticated user's appointments.
  Future<List<AppointmentModel>> getMyAppointments() async {
    try {
      final response = await _client.get(ApiConstants.bookings);

      // The API may return { data: [...] } or a bare list.
      final raw = response.data;
      final List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic> && raw['data'] is List) {
        list = raw['data'] as List<dynamic>;
      } else {
        list = [];
      }

      return list
          .cast<Map<String, dynamic>>()
          .map(AppointmentModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// POST /appointments/{id}/cancel
  Future<AppointmentModel> cancelAppointment(
    String id, {
    String? reason,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (reason != null && reason.trim().isNotEmpty) {
        data['reason'] = reason.trim();
      }
      final response = await _client.post(
        ApiConstants.appointmentCancel(id),
        data: data,
      );
      final body = response.data as Map<String, dynamic>;
      return AppointmentModel.fromJson(body);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
