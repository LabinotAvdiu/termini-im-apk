class AppointmentModel {
  final String id;
  final String companyId;
  final String companyName;
  final String? companyAddress;
  final String? companyPhotoUrl;
  final String serviceName;
  final String? employeeName;
  final DateTime dateTime;
  final int durationMinutes;
  final double price;
  // confirmed | pending | completed | cancelled
  final String status;

  const AppointmentModel({
    required this.id,
    required this.companyId,
    required this.companyName,
    this.companyAddress,
    this.companyPhotoUrl,
    required this.serviceName,
    this.employeeName,
    required this.dateTime,
    required this.durationMinutes,
    required this.price,
    required this.status,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;

    return AppointmentModel(
      id: data['id']?.toString() ?? '',
      companyId: data['companyId']?.toString() ??
          data['company_id']?.toString() ??
          '',
      companyName: data['companyName']?.toString() ??
          data['company_name']?.toString() ??
          '',
      companyAddress: data['companyAddress']?.toString() ??
          data['company_address']?.toString(),
      companyPhotoUrl: data['companyPhotoUrl']?.toString() ??
          data['company_photo_url']?.toString(),
      serviceName: data['serviceName']?.toString() ??
          data['service_name']?.toString() ??
          '',
      employeeName: data['employeeName']?.toString() ??
          data['employee_name']?.toString(),
      dateTime: DateTime.parse(data['dateTime'] as String? ??
          data['date_time'] as String? ??
          data['datetime'] as String? ??
          DateTime.now().toIso8601String()),
      durationMinutes: (data['durationMinutes'] ??
              data['duration_minutes'] ??
              data['duration'] ??
              0) as int,
      price: ((data['price'] ?? 0) as num).toDouble(),
      status: data['status']?.toString() ?? 'pending',
    );
  }
}
