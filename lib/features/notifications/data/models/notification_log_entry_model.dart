/// D20-inbox — Entrée du journal de notifications.
///
/// Le payload JSON enregistré par [NotificationLogger::log] côté backend
/// contient au minimum `title` et `body`. Si ces clés sont absentes
/// (anciens logs avant la phase inbox), on retombe sur des chaînes vides.
class NotificationLogEntry {
  const NotificationLogEntry({
    required this.id,
    required this.channel,
    required this.type,
    required this.title,
    required this.body,
    required this.sentAt,
    this.readAt,
    this.clickedAt,
    this.refType,
    this.refId,
  });

  final int id;

  /// Canal d'envoi : 'push' | 'email' | 'in-app'
  final String channel;

  /// Type métier — correspond aux valeurs de [NotificationType] côté backend
  /// et aux clés du switch dans [variantForType].
  final String type;

  /// Titre humain extrait depuis payload.title.
  final String title;

  /// Corps court extrait depuis payload.body.
  final String body;

  final DateTime sentAt;
  final DateTime? readAt;
  final DateTime? clickedAt;

  /// 'appointment' | 'review' | 'walk_in' | null
  final String? refType;
  final int? refId;

  bool get isRead => readAt != null;

  factory NotificationLogEntry.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? {};

    return NotificationLogEntry(
      id:         (json['id'] as num).toInt(),
      channel:    (json['channel'] as String?) ?? 'push',
      type:       (json['type'] as String?) ?? '',
      title:      (payload['title'] as String?) ?? '',
      body:       (payload['body'] as String?) ?? '',
      sentAt:     DateTime.parse(json['sent_at'] as String),
      readAt:     json['read_at'] != null
                    ? DateTime.parse(json['read_at'] as String)
                    : null,
      clickedAt:  json['clicked_at'] != null
                    ? DateTime.parse(json['clicked_at'] as String)
                    : null,
      refType:    json['ref_type'] as String?,
      refId:      json['ref_id'] != null ? (json['ref_id'] as num).toInt() : null,
    );
  }

  NotificationLogEntry copyWith({DateTime? readAt}) {
    return NotificationLogEntry(
      id:        id,
      channel:   channel,
      type:      type,
      title:     title,
      body:      body,
      sentAt:    sentAt,
      readAt:    readAt ?? this.readAt,
      clickedAt: clickedAt,
      refType:   refType,
      refId:     refId,
    );
  }
}
