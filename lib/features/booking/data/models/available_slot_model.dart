class AvailableSlotModel {
  final DateTime dateTime;
  final String? employeeId;
  final int? remaining;
  final int? max;
  final bool available;

  const AvailableSlotModel({
    required this.dateTime,
    this.employeeId,
    this.remaining,
    this.max,
    this.available = true,
  });

  factory AvailableSlotModel.fromJson(Map<String, dynamic> json) {
    return AvailableSlotModel(
      dateTime: DateTime.parse(json['dateTime'] as String? ?? DateTime.now().toIso8601String()),
      employeeId: json['employeeId'] as String?,
      remaining: json['remaining'] as int?,
      max: json['max'] as int?,
      available: json['available'] as bool? ?? true,
    );
  }
}
