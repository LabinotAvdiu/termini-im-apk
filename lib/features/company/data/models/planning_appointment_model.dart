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
  });

  String get clientFullName =>
      '$clientFirstName $clientLastName'.trim();

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
    );
  }
}
