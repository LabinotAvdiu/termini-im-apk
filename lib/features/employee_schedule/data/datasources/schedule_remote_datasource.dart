import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/schedule_models.dart';
import '../models/schedule_settings_models.dart';

/// Remote datasource for the employee daily schedule.
///
/// All methods throw on non-2xx responses — the notifier layer catches them.
class ScheduleRemoteDatasource {
  final DioClient _client;

  const ScheduleRemoteDatasource({required DioClient client}) : _client = client;

  // ---------------------------------------------------------------------------
  // GET /my-schedule?date=YYYY-MM-DD
  // ---------------------------------------------------------------------------

  Future<DayScheduleData> getMySchedule({String? date}) async {
    final response = await _client.get(
      ApiConstants.mySchedule,
      queryParameters: date != null ? {'date': date} : null,
    );
    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] ?? body) as Map<String, dynamic>;
    return DayScheduleData.fromJson(data);
  }

  // ---------------------------------------------------------------------------
  // PATCH /my-schedule/appointments/{id}/status
  // ---------------------------------------------------------------------------

  /// Cancel or mark no-show on one of the employee's own appointments.
  /// [status] must be 'cancelled' or 'no_show'. [reason] is optional free
  /// text stored as the cancellation reason.
  Future<void> updateMyAppointmentStatus(
    String id,
    String status, {
    String? reason,
  }) async {
    await _client.put(
      ApiConstants.myScheduleAppointmentStatus(id),
      data: {
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // GET /my-schedule/upcoming
  // ---------------------------------------------------------------------------

  /// Returns the closest future appointment across all days (or null when
  /// the employee has no upcoming bookings). The `date` field is populated
  /// so the UI can render a "tomorrow / X jours" variant when it's not today.
  Future<ScheduleAppointment?> getUpcomingAppointment() async {
    final response = await _client.get(ApiConstants.myScheduleUpcoming);
    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    if (data == null) return null;
    return ScheduleAppointment.fromJson(data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // POST /my-schedule/walk-in
  // ---------------------------------------------------------------------------

  /// Registers a walk-in client and returns the refreshed full schedule.
  Future<DayScheduleData> addWalkIn(WalkInRequest request) async {
    final response = await _client.post(
      ApiConstants.myScheduleWalkIn,
      data: request.toJson(),
    );
    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] ?? body) as Map<String, dynamic>;
    return DayScheduleData.fromJson(data);
  }

  // ---------------------------------------------------------------------------
  // GET /my-schedule/settings
  // ---------------------------------------------------------------------------

  Future<ScheduleSettings> getSettings() async {
    final response = await _client.get(ApiConstants.myScheduleSettings);
    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] ?? body) as Map<String, dynamic>;
    return ScheduleSettings.fromJson(data);
  }

  // ---------------------------------------------------------------------------
  // PUT /my-schedule/hours
  // ---------------------------------------------------------------------------

  Future<void> updateHours(List<WorkHour> hours) async {
    await _client.put(
      ApiConstants.myScheduleHours,
      data: {'hours': hours.map((h) => h.toJson()).toList()},
    );
  }

  // ---------------------------------------------------------------------------
  // POST /my-schedule/breaks
  // ---------------------------------------------------------------------------

  Future<BreakModel> addBreak(AddBreakRequest request) async {
    final response = await _client.post(
      ApiConstants.myScheduleBreaks,
      data: request.toJson(),
    );
    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] ?? body) as Map<String, dynamic>;
    return BreakModel.fromJson(data);
  }

  // ---------------------------------------------------------------------------
  // DELETE /my-schedule/breaks/{id}
  // ---------------------------------------------------------------------------

  Future<void> deleteBreak(String id) async {
    await _client.delete(ApiConstants.myScheduleBreak(id));
  }

  // ---------------------------------------------------------------------------
  // POST /my-schedule/days-off
  // ---------------------------------------------------------------------------

  Future<DayOffModel> addDayOff(AddDayOffRequest request) async {
    final response = await _client.post(
      ApiConstants.myScheduleDaysOff,
      data: request.toJson(),
    );
    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] ?? body) as Map<String, dynamic>;
    return DayOffModel.fromJson(data);
  }

  // ---------------------------------------------------------------------------
  // DELETE /my-schedule/days-off/{id}
  // ---------------------------------------------------------------------------

  Future<void> deleteDayOff(String id) async {
    await _client.delete(ApiConstants.myScheduleDayOff(id));
  }
}
