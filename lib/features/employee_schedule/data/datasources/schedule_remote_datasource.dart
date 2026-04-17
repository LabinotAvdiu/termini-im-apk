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
