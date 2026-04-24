import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Variants sémantiques
// ---------------------------------------------------------------------------

/// Trois variants qui couvrent tous les cas métier.
///
/// - [positive] : transaction réussie (confirmé, rappel…). Accent or.
/// - [info]     : information éditoriale (avis, walk-in…). Accent bordeaux doux.
/// - [attention]: action requise ou alerte (annulé, capacité pleine…). Bordeaux plein.
enum InAppNotificationVariant { positive, info, attention }

extension InAppNotificationVariantX on InAppNotificationVariant {
  /// Durée d'auto-dismiss par défaut.
  Duration get defaultDuration => switch (this) {
        InAppNotificationVariant.positive => const Duration(seconds: 5),
        InAppNotificationVariant.info => const Duration(seconds: 4),
        InAppNotificationVariant.attention => const Duration(seconds: 8),
      };
}

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class InAppNotification {
  InAppNotification({
    required this.title,
    required this.body,
    required this.variant,
    required this.icon,
    this.onTap,
    this.deepLinkAppointmentId,
    this.deepLinkCompanyId,
    Duration? duration,
    String? id,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        duration = duration ?? variant.defaultDuration;

  final String id;
  final String title;
  final String body;
  final InAppNotificationVariant variant;
  final IconData icon;
  final Duration duration;
  final VoidCallback? onTap;
  final String? deepLinkAppointmentId;
  final String? deepLinkCompanyId;
}

// ---------------------------------------------------------------------------
// Helper — mapping type backend → variant + icône
// ---------------------------------------------------------------------------

/// Mappe les valeurs de `message.data['type']` vers un variant et une icône.
/// Appelé par [NotificationService._onForegroundMessage].
({InAppNotificationVariant variant, IconData icon}) variantForType(
  String? type,
) {
  return switch (type) {
    // ── Transactions positives ──────────────────────────────────────────────
    'appointment.confirmed' => (
        variant: InAppNotificationVariant.positive,
        icon: Icons.event_available_rounded,
      ),
    'appointment.rescheduled_by_owner' ||
    'appointment.rescheduled_by_client' => (
        variant: InAppNotificationVariant.positive,
        icon: Icons.edit_calendar_rounded,
      ),
    'appointment.reminder.evening' ||
    'appointment.reminder.2h' => (
        variant: InAppNotificationVariant.positive,
        icon: Icons.access_time_rounded,
      ),
    'appointment.review_request' => (
        variant: InAppNotificationVariant.positive,
        icon: Icons.star_outline_rounded,
      ),

    // ── Informationnelles ───────────────────────────────────────────────────
    'new_review' => (
        variant: InAppNotificationVariant.info,
        icon: Icons.star_rounded,
      ),
    'walk_in_created' => (
        variant: InAppNotificationVariant.info,
        icon: Icons.person_add_rounded,
      ),
    'support.reply' => (
        variant: InAppNotificationVariant.info,
        icon: Icons.support_agent_rounded,
      ),
    'test.manual' => (
        variant: InAppNotificationVariant.info,
        icon: Icons.notifications_active_rounded,
      ),

    // ── Attention requise ───────────────────────────────────────────────────
    'appointment.created' => (
        variant: InAppNotificationVariant.attention,
        icon: Icons.calendar_today_rounded,
      ),
    'appointment.cancelled_by_client' ||
    'appointment.cancelled_by_owner' => (
        variant: InAppNotificationVariant.attention,
        icon: Icons.event_busy_rounded,
      ),
    'capacity_full' => (
        variant: InAppNotificationVariant.attention,
        icon: Icons.group_off_rounded,
      ),

    // ── Fallback ────────────────────────────────────────────────────────────
    _ => (
        variant: InAppNotificationVariant.info,
        icon: Icons.notifications_rounded,
      ),
  };
}
