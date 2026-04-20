// Data models for the employee daily schedule feature.
// The API returns raw schedule data (work hours, breaks, appointments)
// and the UI builds the 15-minute grid from these values.

// ---------------------------------------------------------------------------
// Supporting value objects
// ---------------------------------------------------------------------------

class EmployeeInfo {
  final String id;
  final String firstName;
  final String lastName;

  const EmployeeInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  String get fullName =>
      [firstName, lastName].where((p) => p.isNotEmpty).join(' ');

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeInfo(
      id:        json['id'] as String,
      firstName: (json['firstName'] as String?) ?? '',
      lastName:  (json['lastName'] as String?) ?? '',
    );
  }
}

class CompanyInfo {
  final String id;
  final String name;

  const CompanyInfo({required this.id, required this.name});

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      id:   json['id'] as String,
      name: (json['name'] as String?) ?? '',
    );
  }
}

class WorkTimeRange {
  /// "HH:mm" strings, e.g. "09:00"
  final String startTime;
  final String endTime;

  const WorkTimeRange({required this.startTime, required this.endTime});

  factory WorkTimeRange.fromJson(Map<String, dynamic> json) {
    return WorkTimeRange(
      startTime: json['startTime'] as String,
      endTime:   json['endTime'] as String,
    );
  }
}

class BreakTimeRange {
  final String startTime;
  final String endTime;
  final String? label;

  const BreakTimeRange({
    required this.startTime,
    required this.endTime,
    this.label,
  });

  factory BreakTimeRange.fromJson(Map<String, dynamic> json) {
    return BreakTimeRange(
      startTime: json['startTime'] as String,
      endTime:   json['endTime'] as String,
      label:     json['label'] as String?,
    );
  }
}

class ScheduleAppointment {
  final String id;
  /// Only populated when the payload can return appts from multiple days
  /// (e.g. GET /my-schedule/upcoming). Null for the daily list — the
  /// caller already knows the date at that level.
  final String? date;
  final String startTime;
  final String endTime;
  /// Appointment status — 'confirmed' | 'pending' | 'cancelled' | 'no_show'.
  /// The daily list now includes cancelled / no-show so the employee keeps
  /// visual context of what happened that day; UI renders those muted.
  final String status;
  final String clientFirstName;
  final String? clientLastName;
  final String? clientPhone;
  final String serviceName;
  final int durationMinutes;
  final double price;
  final bool isWalkIn;

  const ScheduleAppointment({
    required this.id,
    this.date,
    required this.startTime,
    required this.endTime,
    this.status = 'confirmed',
    required this.clientFirstName,
    this.clientLastName,
    this.clientPhone,
    required this.serviceName,
    required this.durationMinutes,
    required this.price,
    required this.isWalkIn,
  });

  bool get isCancelled => status == 'cancelled' || status == 'no_show';

  String get clientFullName =>
      [clientFirstName, clientLastName]
          .where((p) => p != null && p.isNotEmpty)
          .join(' ');

  factory ScheduleAppointment.fromJson(Map<String, dynamic> json) {
    return ScheduleAppointment(
      id:               json['id'] as String,
      date:             json['date'] as String?,
      startTime:        json['startTime'] as String,
      endTime:          json['endTime'] as String,
      status:           (json['status'] as String?) ?? 'confirmed',
      clientFirstName:  (json['clientFirstName'] as String?) ?? '',
      clientLastName:   json['clientLastName'] as String?,
      clientPhone:      json['clientPhone'] as String?,
      serviceName:      (json['serviceName'] as String?) ?? '',
      durationMinutes:  (json['durationMinutes'] as int?) ?? 0,
      price:            ((json['price'] as num?) ?? 0).toDouble(),
      isWalkIn:         (json['isWalkIn'] as bool?) ?? false,
    );
  }
}

// ---------------------------------------------------------------------------
// Root schedule payload
// ---------------------------------------------------------------------------

class DayScheduleData {
  final String date;
  final bool isDayOff;
  final String? dayOffReason;
  // null when isDayOff == true
  final WorkTimeRange? workHours;
  final List<BreakTimeRange> breaks;
  final List<ScheduleAppointment> appointments;
  final EmployeeInfo employee;
  final CompanyInfo company;

  const DayScheduleData({
    required this.date,
    required this.isDayOff,
    this.dayOffReason,
    this.workHours,
    required this.breaks,
    required this.appointments,
    required this.employee,
    required this.company,
  });

  factory DayScheduleData.fromJson(Map<String, dynamic> json) {
    final rawWork = json['workHours'] as Map<String, dynamic>?;
    return DayScheduleData(
      date:          json['date'] as String,
      isDayOff:      (json['isDayOff'] as bool?) ?? false,
      dayOffReason:  json['dayOffReason'] as String?,
      workHours:     rawWork != null ? WorkTimeRange.fromJson(rawWork) : null,
      breaks:        (json['breaks'] as List<dynamic>? ?? [])
          .map((b) => BreakTimeRange.fromJson(b as Map<String, dynamic>))
          .toList(),
      appointments:  (json['appointments'] as List<dynamic>? ?? [])
          .map((a) => ScheduleAppointment.fromJson(a as Map<String, dynamic>))
          .toList(),
      employee:      EmployeeInfo.fromJson(
          json['employee'] as Map<String, dynamic>),
      company:       CompanyInfo.fromJson(
          json['company'] as Map<String, dynamic>),
    );
  }

  /// Returns the next appointment whose startTime is >= [nowTime] (HH:mm),
  /// or the first one for today if none is upcoming. Returns null when empty.
  ScheduleAppointment? nextAppointment({String? nowTime}) {
    if (appointments.isEmpty) return null;
    final sorted = List<ScheduleAppointment>.from(appointments)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (nowTime == null) return sorted.first;
    final upcoming =
        sorted.where((a) => a.startTime.compareTo(nowTime) >= 0).toList();
    return upcoming.isNotEmpty ? upcoming.first : sorted.last;
  }
}

// ---------------------------------------------------------------------------
// Walk-in request payload
// ---------------------------------------------------------------------------

class WalkInRequest {
  final String time;
  final String date;
  final String clientFirstName;
  final String? clientLastName;
  final String? clientPhone;
  final String serviceId;

  const WalkInRequest({
    required this.time,
    required this.date,
    required this.clientFirstName,
    this.clientLastName,
    this.clientPhone,
    required this.serviceId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'time':       time,
      'date':       date,
      'first_name': clientFirstName,
      'service_id': serviceId,
    };
    if (clientLastName != null && clientLastName!.isNotEmpty) {
      map['last_name'] = clientLastName;
    }
    if (clientPhone != null && clientPhone!.isNotEmpty) {
      map['phone'] = clientPhone;
    }
    return map;
  }
}
