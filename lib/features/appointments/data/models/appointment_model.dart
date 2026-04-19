import '../../../reviews/data/models/review_model.dart';

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

  // Feature 1 — Cancellation
  final bool canCancel;
  final int minCancelHours;
  final DateTime? cancelsBeforeAt;

  // Feature 2 — Reminder
  final int? minutesUntilStart;

  // Feature 3 — Reviews
  final ReviewModel? review;
  final bool canReview;

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
    this.canCancel = false,
    this.minCancelHours = 2,
    this.cancelsBeforeAt,
    this.minutesUntilStart,
    this.review,
    this.canReview = false,
  });

  AppointmentModel copyWith({
    String? status,
    bool? canCancel,
    ReviewModel? review,
    bool? canReview,
  }) {
    return AppointmentModel(
      id: id,
      companyId: companyId,
      companyName: companyName,
      companyAddress: companyAddress,
      companyPhotoUrl: companyPhotoUrl,
      serviceName: serviceName,
      employeeName: employeeName,
      dateTime: dateTime,
      durationMinutes: durationMinutes,
      price: price,
      status: status ?? this.status,
      canCancel: canCancel ?? this.canCancel,
      minCancelHours: minCancelHours,
      cancelsBeforeAt: cancelsBeforeAt,
      minutesUntilStart: minutesUntilStart,
      review: review ?? this.review,
      canReview: canReview ?? this.canReview,
    );
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;

    final reviewJson = data['review'] as Map<String, dynamic>?;
    final cancelsBeforeRaw = data['cancelsBeforeAt'] as String? ??
        data['cancels_before_at'] as String?;

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
      canCancel: data['canCancel'] as bool? ??
          data['can_cancel'] as bool? ??
          false,
      minCancelHours: data['minCancelHours'] as int? ??
          data['min_cancel_hours'] as int? ??
          2,
      cancelsBeforeAt: cancelsBeforeRaw != null
          ? DateTime.tryParse(cancelsBeforeRaw)
          : null,
      minutesUntilStart: data['minutesUntilStart'] as int? ??
          data['minutes_until_start'] as int?,
      review: reviewJson != null ? ReviewModel.fromJson(reviewJson) : null,
      canReview: data['canReview'] as bool? ??
          data['can_review'] as bool? ??
          false,
    );
  }
}
