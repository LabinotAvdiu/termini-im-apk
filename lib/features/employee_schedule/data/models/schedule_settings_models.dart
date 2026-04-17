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

  const AddBreakRequest({
    required this.startTime,
    required this.endTime,
    this.label,
    this.dayOfWeek,
  });

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
// AddDayOffRequest
// ---------------------------------------------------------------------------

class AddDayOffRequest {
  final String date;    // "2026-04-20"
  final String? reason;

  const AddDayOffRequest({required this.date, this.reason});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'date': date};
    if (reason != null && reason!.isNotEmpty) map['reason'] = reason;
    return map;
  }
}
