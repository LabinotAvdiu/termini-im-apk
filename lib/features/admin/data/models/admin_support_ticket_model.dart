class AdminSupportTicket {
  final int id;
  final String firstName;
  final String phone;
  final String? email;
  final String message;
  final String sourcePage;
  final String status;
  final List<String> attachmentUrls;
  final DateTime createdAt;

  const AdminSupportTicket({
    required this.id,
    required this.firstName,
    required this.phone,
    this.email,
    required this.message,
    required this.sourcePage,
    required this.status,
    required this.attachmentUrls,
    required this.createdAt,
  });

  bool get isResolved => status == 'resolved';

  factory AdminSupportTicket.fromJson(Map<String, dynamic> json) {
    return AdminSupportTicket(
      id: (json['id'] as num).toInt(),
      firstName: json['first_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      message: json['message'] as String,
      sourcePage: json['source_page'] as String,
      status: json['status'] as String? ?? 'open',
      attachmentUrls: (json['attachment_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  AdminSupportTicket copyWith({String? status}) {
    return AdminSupportTicket(
      id: id,
      firstName: firstName,
      phone: phone,
      email: email,
      message: message,
      sourcePage: sourcePage,
      status: status ?? this.status,
      attachmentUrls: attachmentUrls,
      createdAt: createdAt,
    );
  }
}
