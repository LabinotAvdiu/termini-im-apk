class PlanningAppointmentServiceModel {
  final String id;
  final String name;
  final int durationMinutes;
  final double price;

  const PlanningAppointmentServiceModel({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
  });

  factory PlanningAppointmentServiceModel.fromJson(Map<String, dynamic> json) {
    return PlanningAppointmentServiceModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? 30,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Capability flags computed server-side (see docs/PLANNING_CONTRACT.md).
/// The UI renders a button ssi the matching flag is true — no role/status/
/// time checks live on the client.
class AppointmentCapabilities {
  final bool accept;
  final bool reject;
  final bool cancel;
  final bool markNoShow;
  final bool freeSlot;

  const AppointmentCapabilities({
    this.accept = false,
    this.reject = false,
    this.cancel = false,
    this.markNoShow = false,
    this.freeSlot = false,
  });

  factory AppointmentCapabilities.fromJson(Map<String, dynamic> json) {
    return AppointmentCapabilities(
      accept: json['accept'] as bool? ?? false,
      reject: json['reject'] as bool? ?? false,
      cancel: json['cancel'] as bool? ?? false,
      markNoShow: json['markNoShow'] as bool? ?? false,
      freeSlot: json['freeSlot'] as bool? ?? false,
    );
  }
}

class PlanningAppointmentModel {
  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String clientFirstName;
  final String clientLastName;
  final String? clientPhone;
  final PlanningAppointmentServiceModel service;
  final String? employeeName;
  final bool isWalkIn;
  // Feature 4 — No-show: number of past no-shows for this client
  final int clientNoShowCount;
  /// Reason the client wrote when they cancelled the appointment themselves
  /// (null when still active, cancelled by the owner, or no reason given).
  final String? cancellationReason;
  /// ISO timestamp of the client-initiated cancellation (null otherwise).
  final String? cancelledByClientAt;
  /// Reason the owner provided when rejecting the appointment (pending → rejected).
  final String? rejectionReason;
  /// ISO timestamp when the owner rejected the appointment (null otherwise).
  final String? rejectedByOwnerAt;
  /// Capability flags — source of truth is the backend. See PLANNING_CONTRACT.md.
  final AppointmentCapabilities can;

  const PlanningAppointmentModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.clientFirstName,
    required this.clientLastName,
    this.clientPhone,
    required this.service,
    this.employeeName,
    this.isWalkIn = false,
    this.clientNoShowCount = 0,
    this.cancellationReason,
    this.cancelledByClientAt,
    this.rejectionReason,
    this.rejectedByOwnerAt,
    this.can = const AppointmentCapabilities(),
  });

  String get clientFullName =>
      '$clientFirstName $clientLastName'.trim();

  /// Parsed start datetime (null if the stored strings can't be parsed).
  /// Kept for display-only computations (e.g. "in 2 hours" formatting) —
  /// never gate actions on this, the backend `can.*` flags are authoritative.
  DateTime? get startDateTime {
    try {
      return DateTime.parse('${date}T$startTime:00');
    } catch (_) {
      return null;
    }
  }

  PlanningAppointmentModel copyWith({
    String? status,
    String? rejectionReason,
    String? rejectedByOwnerAt,
    AppointmentCapabilities? can,
  }) {
    return PlanningAppointmentModel(
      id: id,
      date: date,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
      clientFirstName: clientFirstName,
      clientLastName: clientLastName,
      clientPhone: clientPhone,
      service: service,
      employeeName: employeeName,
      isWalkIn: isWalkIn,
      clientNoShowCount: clientNoShowCount,
      cancellationReason: cancellationReason,
      cancelledByClientAt: cancelledByClientAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rejectedByOwnerAt: rejectedByOwnerAt ?? this.rejectedByOwnerAt,
      can: can ?? this.can,
    );
  }

  factory PlanningAppointmentModel.fromJson(Map<String, dynamic> json) {
    return PlanningAppointmentModel(
      id: json['id']?.toString() ?? '',
      date: json['date'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      status: json['status'] as String? ?? 'confirmed',
      clientFirstName: json['clientFirstName'] as String? ?? '',
      clientLastName: json['clientLastName'] as String? ?? '',
      clientPhone: json['clientPhone'] as String?,
      service: PlanningAppointmentServiceModel.fromJson(
        json['service'] as Map<String, dynamic>? ?? {},
      ),
      employeeName: json['employeeName'] as String?,
      isWalkIn: json['isWalkIn'] as bool? ?? false,
      clientNoShowCount: json['clientNoShowCount'] as int? ??
          json['client_no_show_count'] as int? ??
          0,
      cancellationReason: json['cancellationReason'] as String? ??
          json['cancellation_reason'] as String?,
      cancelledByClientAt: json['cancelledByClientAt'] as String? ??
          json['cancelled_by_client_at'] as String?,
      rejectionReason: json['rejectionReason'] as String? ??
          json['rejection_reason'] as String?,
      rejectedByOwnerAt: json['rejectedByOwnerAt'] as String? ??
          json['rejected_by_owner_at'] as String?,
      can: json['can'] is Map<String, dynamic>
          ? AppointmentCapabilities.fromJson(json['can'] as Map<String, dynamic>)
          : const AppointmentCapabilities(),
    );
  }
}
