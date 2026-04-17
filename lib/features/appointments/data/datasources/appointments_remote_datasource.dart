import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/appointment_model.dart';

class AppointmentsRemoteDatasource {
  final DioClient _client;

  const AppointmentsRemoteDatasource({required DioClient client})
      : _client = client;

  /// GET /bookings — returns the authenticated user's appointments.
  Future<List<AppointmentModel>> getMyAppointments() async {
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
  }
}
