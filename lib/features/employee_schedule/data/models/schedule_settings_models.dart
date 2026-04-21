// Data models for the employee schedule-settings feature.
//
// The GET /my-schedule/settings response shape:
// {
//   "companyHours": [ WorkHour... ],
//   "employeeHours": [ WorkHour... ],
//   "breaks": [ BreakModel... ],
//   "daysOff": [ DayOffModel... ]
// }

// ---------------------------------------------------------------------------
// WorkHour
// ---------------------------------------------------------------------------

class WorkHour {
  final int dayOfWeek; // 1 = Monday … 7 = Sunday (ISO 8601)
  final String startTime; // "09:00"
  final String endTime; // "19:00"
  final bool isWorking; // false when the day is marked closed/off

  const WorkHour({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isWorking,
  });

  factory WorkHour.fromJson(Map<String, dynamic> json) {
    return WorkHour(
      dayOfWeek: (json['dayOfWeek'] as int?) ?? 1,
      startTime: (json['startTime'] as String?) ?? '09:00',
      endTime:   (json['endTime']   as String?) ?? '18:00',
      // Accept both "isClosed" (company hours) and "isWorking" (employee hours)
      isWorking: json.containsKey('isWorking')
          ? ((json['isWorking'] as bool?) ?? true)
          : !((json['isClosed'] as bool?) ?? false),
    );
  }

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'start_time':  startTime,
        'end_time':    endTime,
        'is_working':  isWorking,
      };

  WorkHour copyWith({
    int?    dayOfWeek,
    String? startTime,
    String? endTime,
    bool?   isWorking,
  }) =>
      WorkHour(
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        startTime: startTime ?? this.startTime,
        endTime:   endTime   ?? this.endTime,
        isWorking: isWorking ?? this.isWorking,
      );
}

// ---------------------------------------------------------------------------
// BreakModel
// ---------------------------------------------------------------------------

class BreakModel {
  final String id;
  // null means the break applies every day
  final int? dayOfWeek;
  final String startTime; // "12:00"
  final String endTime;   // "13:00"
  final String? label;

  const BreakModel({
    required this.id,
    this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.label,
  });

  factory BreakModel.fromJson(Map<String, dynamic> json) {
    return BreakModel(
      id:        json['id'] as String,
      dayOfWeek: json['dayOfWeek'] as int?,
      startTime: (json['startTime'] as String?) ?? '12:00',
      endTime:   (json['endTime']   as String?) ?? '13:00',
      label:     json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'start_time': startTime,
      'end_time':   endTime,
    };
    if (dayOfWeek != null) map['day_of_week'] = dayOfWeek;
    if (label != null && label!.isNotEmpty) map['label'] = label;
    return map;
  }
}

// ---------------------------------------------------------------------------
// DayOffModel
// ---------------------------------------------------------------------------

class DayOffModel {
  final String id;
  final String date;   // "2026-04-20"
  final String? reason;

  const DayOffModel({
    required this.id,
    required this.date,
    this.reason,
  });

  factory DayOffModel.fromJson(Map<String, dynamic> json) {
    return DayOffModel(
      id:     json['id']   as String,
      date:   json['date'] as String,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'date': date};
    if (reason != null && reason!.isNotEmpty) map['reason'] = reason;
    return map;
  }
}

// ---------------------------------------------------------------------------
// ScheduleSettings — root response model
// ---------------------------------------------------------------------------

class ScheduleSettings {
  final List<WorkHour>   companyHours;
  final List<WorkHour>   employeeHours;
  final List<BreakModel> breaks;
  final List<DayOffModel> daysOff;

  const ScheduleSettings({
    required this.companyHours,
    required this.employeeHours,
    required this.breaks,
    required this.daysOff,
  });

  factory ScheduleSettings.fromJson(Map<String, dynamic> json) {
    return ScheduleSettings(
      companyHours: (json['companyHours'] as List<dynamic>? ?? [])
          .map((e) => WorkHour.fromJson(e as Map<String, dynamic>))
          .toList(),
      employeeHours: (json['employeeHours'] as List<dynamic>? ?? [])
          .map((e) => WorkHour.fromJson(e as Map<String, dynamic>))
          .toList(),
      breaks: (json['breaks'] as List<dynamic>? ?? [])
          .map((e) => BreakModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      daysOff: (json['daysOff'] as List<dynamic>? ?? [])
          .map((e) => DayOffModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// AddBreakRequest
// ---------------------------------------------------------------------------

class AddBreakRequest {
  final String startTime;
  final String endTime;
  final String? label;
  final int? dayOfWeek; // null = every day
  /// When true, the backend skips the conflict check and saves the break even
  /// if live appointments start during the window. Set by the frontend after
  /// the user confirmed the soft-conflict dialog.
  final bool force;

  const AddBreakRequest({
    required this.startTime,
    required this.endTime,
    this.label,
    this.dayOfWeek,
    this.force = false,
  });

  AddBreakRequest copyWith({bool? force}) => AddBreakRequest(
        startTime: startTime,
        endTime: endTime,
        label: label,
        dayOfWeek: dayOfWeek,
        force: force ?? this.force,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'start_time': startTime,
      'end_time':   endTime,
    };
    if (dayOfWeek != null) map['day_of_week'] = dayOfWeek;
    if (label != null && label!.isNotEmpty) map['label'] = label;
    if (force) map['force'] = true;
    return map;
  }
}

// ---------------------------------------------------------------------------
// AddDayOffRequest
// ---------------------------------------------------------------------------

class AddDayOffRequest {
  /// Start of the range (YYYY-MM-DD).
  final String date;
  /// End of the range inclusive (YYYY-MM-DD). null → single-day close
  /// (backend defaults to `date`).
  final String? untilDate;
  final String? reason;

  const AddDayOffRequest({
    required this.date,
    this.untilDate,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'date': date};
    if (untilDate != null && untilDate != date) {
      map['until_date'] = untilDate;
    }
    if (reason != null && reason!.isNotEmpty) map['reason'] = reason;
    return map;
  }
}

// ---------------------------------------------------------------------------
// Conflict payloads — returned on 409 from POST /breaks or /days-off
// ---------------------------------------------------------------------------

/// One conflicting appointment surfaced by the backend's conflict check.
/// Used to populate the "these RDVs block your action" list in the UI.
class ScheduleConflictAppointment {
  final String id;
  final String date; // YYYY-MM-DD
  final String startTime; // HH:MM
  final String endTime;
  final String? clientFirstName;
  final String? clientLastName;
  final bool isWalkIn;
  final String? serviceName;

  const ScheduleConflictAppointment({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.clientFirstName,
    this.clientLastName,
    this.isWalkIn = false,
    this.serviceName,
  });

  factory ScheduleConflictAppointment.fromJson(Map<String, dynamic> json) {
    return ScheduleConflictAppointment(
      id: json['id']?.toString() ?? '',
      date: (json['date'] as String?) ?? '',
      startTime: (json['startTime'] as String?) ?? '',
      endTime: (json['endTime'] as String?) ?? '',
      clientFirstName: json['clientFirstName'] as String?,
      clientLastName: json['clientLastName'] as String?,
      isWalkIn: (json['isWalkIn'] as bool?) ?? false,
      serviceName: json['serviceName'] as String?,
    );
  }

  String get clientFullName =>
      '${clientFirstName ?? ''} ${clientLastName ?? ''}'.trim();
}

/// Thrown by the datasource on 409 so the UI can render the conflict list.
class ScheduleConflictException implements Exception {
  /// 'break_conflict' | 'day_off_conflict'
  final String code;
  final String message;
  final List<ScheduleConflictAppointment> conflicts;

  const ScheduleConflictException({
    required this.code,
    required this.message,
    required this.conflicts,
  });
}

// ---------------------------------------------------------------------------
// Result sealed-types — shared between individual (my-schedule) and capacity
// (my-company) flows so the modal widgets can be used identically on both
// screens. success | conflict(conflicts) | error(message).
// ---------------------------------------------------------------------------

sealed class AddBreakResult {
  const AddBreakResult();
  const factory AddBreakResult.success() = AddBreakSuccess;
  const factory AddBreakResult.conflict(
      List<ScheduleConflictAppointment> conflicts) = AddBreakConflict;
  const factory AddBreakResult.error(String message) = AddBreakError;
}

class AddBreakSuccess extends AddBreakResult {
  const AddBreakSuccess();
}

class AddBreakConflict extends AddBreakResult {
  final List<ScheduleConflictAppointment> conflicts;
  const AddBreakConflict(this.conflicts);
}

class AddBreakError extends AddBreakResult {
  final String message;
  const AddBreakError(this.message);
}

sealed class AddDayOffResult {
  const AddDayOffResult();
  const factory AddDayOffResult.success() = AddDayOffSuccess;
  const factory AddDayOffResult.conflict(
      List<ScheduleConflictAppointment> conflicts) = AddDayOffConflict;
  const factory AddDayOffResult.error(String message) = AddDayOffError;
}

class AddDayOffSuccess extends AddDayOffResult {
  const AddDayOffSuccess();
}

class AddDayOffConflict extends AddDayOffResult {
  final List<ScheduleConflictAppointment> conflicts;
  const AddDayOffConflict(this.conflicts);
}

class AddDayOffError extends AddDayOffResult {
  final String message;
  const AddDayOffError(this.message);
}
