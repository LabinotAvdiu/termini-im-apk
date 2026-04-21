/// Overlays drawn on top of the planning grid besides appointments:
///   - [PlanningBreakModel]  : recurring (dayOfWeek=null → every day) or
///                             weekly (dayOfWeek=0..6) break windows
///   - [PlanningDayOffModel] : concrete dates where the timeline is closed
///
/// Scoped server-side by role (employee → own / owner capacity → company).
/// Deserialized from `GET /my-company/planning-overlays`.
class PlanningBreakModel {
  final String id;
  /// null = break applies every day.
  final int? dayOfWeek;
  /// "HH:mm"
  final String startTime;
  /// "HH:mm"
  final String endTime;
  final String? label;

  const PlanningBreakModel({
    required this.id,
    this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.label,
  });

  factory PlanningBreakModel.fromJson(Map<String, dynamic> json) {
    return PlanningBreakModel(
      id: json['id']?.toString() ?? '',
      dayOfWeek: json['dayOfWeek'] as int?,
      startTime: (json['startTime'] as String?) ?? '12:00',
      endTime: (json['endTime'] as String?) ?? '13:00',
      label: json['label'] as String?,
    );
  }

  /// True when this break applies on [weekday] (1=Mon … 7=Sun ISO-8601).
  bool appliesOn(int weekday) {
    if (dayOfWeek == null) return true;
    // Backend uses enum 0=Mon … 6=Sun; ISO uses 1=Mon … 7=Sun.
    return dayOfWeek == weekday - 1;
  }
}

class PlanningDayOffModel {
  final String id;
  /// "YYYY-MM-DD"
  final String date;
  final String? reason;

  const PlanningDayOffModel({
    required this.id,
    required this.date,
    this.reason,
  });

  factory PlanningDayOffModel.fromJson(Map<String, dynamic> json) {
    return PlanningDayOffModel(
      id: json['id']?.toString() ?? '',
      date: (json['date'] as String?) ?? '',
      reason: json['reason'] as String?,
    );
  }
}

class PlanningOverlaysModel {
  final List<PlanningBreakModel> breaks;
  final List<PlanningDayOffModel> daysOff;

  const PlanningOverlaysModel({
    this.breaks = const [],
    this.daysOff = const [],
  });

  factory PlanningOverlaysModel.fromJson(Map<String, dynamic> json) {
    return PlanningOverlaysModel(
      breaks: (json['breaks'] as List<dynamic>? ?? [])
          .map((e) => PlanningBreakModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      daysOff: (json['daysOff'] as List<dynamic>? ?? [])
          .map((e) => PlanningDayOffModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Quick lookup for the day-view renderer.
  bool isDayOff(String isoDate) => daysOff.any((d) => d.date == isoDate);
}

/// UI-driving flags returned by `GET /my-company/planning-settings`.
/// The frontend switches sections on these flags and never reads the booking
/// mode or user role directly. See docs/PLANNING_CONTRACT.md.
class PlanningSettingsModel {
  final bool showPendingApprovalsPanel;
  final bool showNextAppointmentBanner;
  final bool showAllStatuses;
  final bool allowOverlappingWalkIns;
  final List<String> visibleStatuses;

  const PlanningSettingsModel({
    this.showPendingApprovalsPanel = false,
    this.showNextAppointmentBanner = false,
    this.showAllStatuses = false,
    this.allowOverlappingWalkIns = false,
    this.visibleStatuses = const ['confirmed'],
  });

  factory PlanningSettingsModel.fromJson(Map<String, dynamic> json) {
    return PlanningSettingsModel(
      showPendingApprovalsPanel:
          json['showPendingApprovalsPanel'] as bool? ?? false,
      showNextAppointmentBanner:
          json['showNextAppointmentBanner'] as bool? ?? false,
      showAllStatuses: json['showAllStatuses'] as bool? ?? false,
      allowOverlappingWalkIns:
          json['allowOverlappingWalkIns'] as bool? ?? false,
      visibleStatuses: (json['visibleStatuses'] as List<dynamic>? ?? const ['confirmed'])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
