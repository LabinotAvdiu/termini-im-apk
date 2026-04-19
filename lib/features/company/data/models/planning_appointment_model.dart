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
  });

  String get clientFullName =>
      '$clientFirstName $clientLastName'.trim();

  /// Parsed start datetime (null if the stored strings can't be parsed).
  DateTime? get startDateTime {
    try {
      return DateTime.parse('${date}T$startTime:00');
    } catch (_) {
      return null;
    }
  }

  /// Returns true when the appointment start time is in the past. Used to
  /// hide confirm/reject actions on stale appointments — an owner shouldn't
  /// be able to approve a slot that already happened.
  bool get isPast {
    final dt = startDateTime;
    return dt != null && dt.isBefore(DateTime.now());
  }

  /// Window during which the owner can still mark this appointment as
  /// a no-show. Starts once the slot begins, closes 24h later. After that
  /// the no-show action is no longer offered — keeps the planning UI focused
  /// on fresh events rather than historical bookkeeping.
  bool get canMarkNoShow {
    final dt = startDateTime;
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.isBefore(now) && now.difference(dt).inHours < 24;
  }

  PlanningAppointmentModel copyWith({String? status}) {
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
    );
  }
}
