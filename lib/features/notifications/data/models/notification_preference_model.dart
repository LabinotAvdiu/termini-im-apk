/// D19 — Modèle granulaire : une préférence par (channel, type).
///
/// Les valeurs de channel et type correspondent exactement aux constantes
/// Laravel [NotificationType] côté backend.
class NotificationPreferenceModel {
  final String channel; // push | email | in-app
  final String type; // reminder_evening | marketing | new_review…
  final bool enabled;

  const NotificationPreferenceModel({
    required this.channel,
    required this.type,
    required this.enabled,
  });

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceModel(
      channel: json['channel'] as String,
      type: json['type'] as String,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'channel': channel,
        'type': type,
        'enabled': enabled,
      };

  NotificationPreferenceModel copyWith({bool? enabled}) {
    return NotificationPreferenceModel(
      channel: channel,
      type: type,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationPreferenceModel &&
      channel == other.channel &&
      type == other.type;

  @override
  int get hashCode => Object.hash(channel, type);
}

// ---------------------------------------------------------------------------
// Types configurables (doit être synchronisé avec NotificationType PHP)
// ---------------------------------------------------------------------------

abstract class NotificationTypes {
  // Rappels RDV
  static const reminderEvening = 'reminder_evening';
  static const reminder2h = 'reminder_2h';
  static const reviewRequest = 'review_request';

  // Communauté (owner)
  static const newReview = 'new_review';
  static const capacityFull = 'capacity_full';
  static const weeklyDigest = 'weekly_digest';
  static const monthlyReport = 'monthly_report';

  // Favoris (client)
  static const favoriteNewPhotos = 'favorite_new_photos';
  static const favoriteNewSlots = 'favorite_new_slots';

  // Marketing
  static const marketing = 'marketing';

  /// Types appartenant à la catégorie RDV dans l'UI settings.
  static const appointmentTypes = [
    reminderEvening,
    reminder2h,
    reviewRequest,
  ];

  /// Types appartenant à la catégorie Communauté dans l'UI settings.
  static const communityTypes = [
    newReview,
    capacityFull,
    weeklyDigest,
    monthlyReport,
    favoriteNewPhotos,
    favoriteNewSlots,
  ];

  /// Types appartenant à la catégorie Marketing dans l'UI settings.
  static const marketingTypes = [
    marketing,
  ];
}
