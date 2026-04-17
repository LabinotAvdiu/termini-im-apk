class DayAvailability {
  final String date;
  final String dayName;
  final String status; // available, closed, day_off, not_working, full
  final int? slotsCount;

  const DayAvailability({
    required this.date,
    required this.dayName,
    required this.status,
    this.slotsCount,
  });

  bool get isAvailable => status == 'available';
  bool get isDisabled => status != 'available';

  factory DayAvailability.fromJson(Map<String, dynamic> json) {
    return DayAvailability(
      date: json['date'] as String? ?? '',
      dayName: json['dayName'] as String? ?? '',
      status: json['status'] as String? ?? 'closed',
      slotsCount: json['slotsCount'] as int?,
    );
  }
}
