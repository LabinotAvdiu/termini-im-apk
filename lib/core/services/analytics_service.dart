import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wrapper typé autour de [FirebaseAnalytics].
///
/// Toutes les méthodes sont fire-and-forget et ne lèvent jamais d'exception
/// visible — les erreurs Firebase sont absorbées et loggées via [debugPrint].
/// Sur le web, les appels sont passés directement à Firebase Analytics (web SDK
/// supporté). Sur desktop hors Firebase, les appels sont no-op car [_safe]
/// attrape l'exception.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics get _fa => FirebaseAnalytics.instance;

  // ---------------------------------------------------------------------------
  // Safety wrapper
  // ---------------------------------------------------------------------------

  Future<void> _safe(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      debugPrint('[Analytics] erreur: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // User identity
  // ---------------------------------------------------------------------------

  Future<void> setUserId(String userId) => _safe(
        () => _fa.setUserId(id: userId),
      );

  Future<void> clearUserId() => _safe(
        () => _fa.setUserId(id: null),
      );

  Future<void> setUserRole(String role) => _safe(
        () => _fa.setUserProperty(name: 'role', value: role),
      );

  Future<void> setUserLocale(String locale) => _safe(
        () => _fa.setUserProperty(name: 'locale', value: locale),
      );

  Future<void> setOnboardingVariant(String variant) => _safe(
        () => _fa.setUserProperty(name: 'onboarding_variant', value: variant),
      );

  // ---------------------------------------------------------------------------
  // Auth events
  // ---------------------------------------------------------------------------

  /// Appelé dès que l'utilisateur déclenche le flow signup (premier bouton).
  /// [method] : 'email' | 'google' | 'facebook' | 'apple'
  Future<void> logSignupStarted({required String method}) => _safe(
        () => _fa.logEvent(
          name: 'signup_started',
          parameters: {'method': method},
        ),
      );

  /// Appelé après un signup réussi côté backend.
  /// [method] : 'email' | 'google' | 'facebook' | 'apple'
  /// [role]   : 'client' | 'owner' | 'employee'
  Future<void> logSignupCompleted({
    required String method,
    required String role,
  }) =>
      _safe(
        () => _fa.logEvent(
          name: 'signup_completed',
          parameters: {'method': method, 'role': role},
        ),
      );

  Future<void> logEmailVerified() => _safe(
        () => _fa.logEvent(name: 'email_verified'),
      );

  Future<void> logProfileCompleted() => _safe(
        () => _fa.logEvent(name: 'profile_completed'),
      );

  // ---------------------------------------------------------------------------
  // Discovery / search
  // ---------------------------------------------------------------------------

  Future<void> logSearchPerformed({
    String? city,
    String? gender,
    DateTime? date,
  }) =>
      _safe(
        () => _fa.logEvent(
          name: 'search_performed',
          parameters: {
            if (city != null) 'city': city,
            if (gender != null) 'gender': gender,
            if (date != null) 'date': date.toIso8601String().substring(0, 10),
          },
        ),
      );

  Future<void> logSalonViewed({required String salonId}) => _safe(
        () => _fa.logEvent(
          name: 'salon_viewed',
          parameters: {'salon_id': salonId},
        ),
      );

  Future<void> logFavoriteAdded({required String salonId}) => _safe(
        () => _fa.logEvent(
          name: 'favorite_added',
          parameters: {'salon_id': salonId},
        ),
      );

  Future<void> logShareLinkCopied({
    required String salonId,
    String? employeeId,
  }) =>
      _safe(
        () => _fa.logEvent(
          name: 'share_link_copied',
          parameters: {
            'salon_id': salonId,
            if (employeeId != null) 'employee_id': employeeId,
          },
        ),
      );

  // ---------------------------------------------------------------------------
  // Booking funnel
  // ---------------------------------------------------------------------------

  Future<void> logBookingStarted({required String salonId}) => _safe(
        () => _fa.logEvent(
          name: 'booking_started',
          parameters: {'salon_id': salonId},
        ),
      );

  Future<void> logBookingSlotSelected({
    required String salonId,
    required String serviceId,
  }) =>
      _safe(
        () => _fa.logEvent(
          name: 'booking_slot_selected',
          parameters: {'salon_id': salonId, 'service_id': serviceId},
        ),
      );

  Future<void> logBookingConfirmed({
    required String salonId,
    required String serviceId,
    required int durationMinutes,
  }) =>
      _safe(
        () => _fa.logEvent(
          name: 'booking_confirmed',
          parameters: {
            'salon_id': salonId,
            'service_id': serviceId,
            'duration_minutes': durationMinutes,
          },
        ),
      );

  Future<void> logBookingCancelled({required String reason}) => _safe(
        () => _fa.logEvent(
          name: 'booking_cancelled',
          parameters: {'reason': reason},
        ),
      );

  Future<void> logBookingRescheduled() => _safe(
        () => _fa.logEvent(name: 'booking_rescheduled'),
      );

  // ---------------------------------------------------------------------------
  // Owner / employee actions
  // ---------------------------------------------------------------------------

  /// Appelé quand un owner reçoit son tout premier RDV confirmé.
  Future<void> logSalonActivated({required String salonId}) => _safe(
        () => _fa.logEvent(
          name: 'salon_activated',
          parameters: {'salon_id': salonId},
        ),
      );

  Future<void> logTeamInviteSent() => _safe(
        () => _fa.logEvent(name: 'team_invite_sent'),
      );

  Future<void> logWalkInCreated() => _safe(
        () => _fa.logEvent(name: 'walk_in_created'),
      );

  Future<void> logGalleryPhotoUploaded() => _safe(
        () => _fa.logEvent(name: 'gallery_photo_uploaded'),
      );
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final analyticsProvider = Provider<AnalyticsService>(
  (_) => AnalyticsService.instance,
);
