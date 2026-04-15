class BookingModel {
  final String id;
  final String companyId;
  final String serviceId;
  final String? employeeId;
  final DateTime dateTime;
  final String status;

  const BookingModel({
    required this.id,
    required this.companyId,
    required this.serviceId,
    this.employeeId,
    required this.dateTime,
    required this.status,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    return BookingModel(
      id: data['id']?.toString() ?? '',
      companyId: data['companyId']?.toString() ?? '',
      serviceId: data['serviceId']?.toString() ?? '',
      employeeId: data['employeeId']?.toString(),
      dateTime: DateTime.parse(data['dateTime'] as String),
      status: data['status'] as String? ?? 'pending',
    );
  }
}
