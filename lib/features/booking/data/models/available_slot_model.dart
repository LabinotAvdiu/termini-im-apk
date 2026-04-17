class AvailableSlotModel {
  final DateTime dateTime;
  final String? employeeId;

  const AvailableSlotModel({
    required this.dateTime,
    this.employeeId,
  });

  factory AvailableSlotModel.fromJson(Map<String, dynamic> json) {
    return AvailableSlotModel(
      dateTime: DateTime.parse(json['dateTime'] as String? ?? DateTime.now().toIso8601String()),
      employeeId: json['employeeId'] as String?,
    );
  }
}
