import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

abstract class ApiConstants {
  // Override via --dart-define=API_BASE_URL=http://localhost:8080/api at build
  // time for local dev. Release builds (including those uploaded to Play
  // Store / TestFlight) resolve to the production API unless overridden.
  static const String _envBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Set to true only during local development. When true and no
  /// `API_BASE_URL` override is provided, falls back to `10.0.2.2`
  /// (Android emulator) or `localhost` (iOS simulator / web).
  static const bool _useLocalInDev =
      bool.fromEnvironment('USE_LOCAL_API', defaultValue: false);

  static final String baseUrl = _resolveBaseUrl();

  static String _resolveBaseUrl() {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    if (_useLocalInDev) {
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2:8080/api';
      }
      return 'http://localhost:8080/api';
    }
    // Production default — Play Store / TestFlight AABs hit this path.
    return 'https://api.termini-im.com/api';
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------
  static const String login               = '/auth/login';
  static const String register            = '/auth/register';
  static const String googleAuth          = '/auth/google';
  static const String facebookAuth        = '/auth/facebook';
  static const String appleAuth           = '/auth/apple';
  static const String completeCompany     = '/auth/complete-company';
  static const String refreshToken        = '/auth/refresh';
  static const String logout              = '/auth/logout';
  static const String profile             = '/auth/profile';

  // Password reset flow
  static const String forgotPassword      = '/auth/forgot-password';
  static const String resetPassword       = '/auth/reset-password';

  // Email verification
  static const String verifyEmail         = '/auth/verify-email';
  static const String resendVerification  = '/auth/resend-verification';

  // Account deletion (required by App Store / Play Store)
  static const String deleteAccount       = '/auth/account';

  // ---------------------------------------------------------------------------
  // Companies
  // ---------------------------------------------------------------------------
  static const String companies = '/companies';
  static String companyDetail(String id)    => '/companies/$id';
  static String companyServices(String id)  => '/companies/$id/services';
  static String companyEmployees(String id) => '/companies/$id/employees';
  static String companySlots(String id)     => '/companies/$id/slots';
  static String companyAvailability(String id) => '/companies/$id/availability';

  // ---------------------------------------------------------------------------
  // Favorites
  // ---------------------------------------------------------------------------
  static String companyFavorite(String id) => '/companies/$id/favorite';

  // ---------------------------------------------------------------------------
  // Share QR — owner / employee emails own salon QR
  // ---------------------------------------------------------------------------
  static const String shareQrEmail = '/share/qr-email';

  // ---------------------------------------------------------------------------
  // Bookings (client)
  // ---------------------------------------------------------------------------
  static const String bookings = '/bookings';
  static String bookingDetail(String id) => '/bookings/$id';
  static String appointmentCancel(String id) => '/appointments/$id/cancel';
  static String appointmentReview(String id) => '/appointments/$id/review';

  // ---------------------------------------------------------------------------
  // Reviews (public)
  // ---------------------------------------------------------------------------
  static String companyReviews(String id) => '/companies/$id/reviews';

  // ---------------------------------------------------------------------------
  // My Company (authenticated owner endpoints)
  // ---------------------------------------------------------------------------
  static const String myCompany             = '/my-company';
  static const String myCompanyCategories   = '/my-company/categories';
  static const String myCompanyServices     = '/my-company/services';
  static const String myCompanyEmployees    = '/my-company/employees';
  static const String myCompanyEmployeesInvite  = '/my-company/employees/invite';
  static const String myCompanyEmployeesCreate  = '/my-company/employees/create';
  static const String myCompanyHours        = '/my-company/hours';

  static String myCompanyCategory(String id)  => '/my-company/categories/$id';
  static String myCompanyService(String id)   => '/my-company/services/$id';
  static String myCompanyEmployee(String id)  => '/my-company/employees/$id';

  static const String myCompanyBookingSettings  = '/my-company/booking-settings';
  static const String myCompanyBreaks           = '/my-company/breaks';
  static const String myCompanyCapacityOverrides = '/my-company/capacity-overrides';
  static const String myCompanyPendingAppointments = '/my-company/appointments/pending';
  static const String myCompanyWalkIn = '/my-company/walk-in';
  static String myCompanyPlanningOverlays(String start, String end) =>
      '/my-company/planning-overlays?start=$start&end=$end';
  static const String myCompanyPlanningSettings =
      '/my-company/planning-settings';
  static String myCompanyAppointments(String date, List<String> statuses) {
    final statusParam = statuses.join(',');
    return '/my-company/appointments?date=$date&status=$statusParam';
  }

  static String myCompanyAppointmentStatus(String id) =>
      '/my-company/appointments/$id/status';
  static String myCompanyBreak(String id) => '/my-company/breaks/$id';
  static String myCompanyCapacityOverride(String id) =>
      '/my-company/capacity-overrides/$id';

  // Reviews (owner)
  static const String myCompanyReviews         = '/my-company/reviews';
  static String myCompanyReviewHide(String id)   => '/my-company/reviews/$id/hide';
  static String myCompanyReviewUnhide(String id) => '/my-company/reviews/$id/unhide';

  // Gallery
  static const String myCompanyGallery         = '/my-company/gallery';
  static const String myCompanyGalleryReorder  = '/my-company/gallery/reorder';
  static String myCompanyGalleryPhoto(String id) => '/my-company/gallery/$id';

  // ---------------------------------------------------------------------------
  // Avatar (user profile photo)
  // ---------------------------------------------------------------------------
  static const String meAvatar = '/me/avatar';

  // ---------------------------------------------------------------------------
  // Support (public — guest or authenticated)
  // ---------------------------------------------------------------------------
  static const String supportTickets = '/support-tickets';

  // ---------------------------------------------------------------------------
  // E28 — Client error reporting (public POST, auth:sanctum GET)
  // ---------------------------------------------------------------------------
  static const String clientErrors = '/errors';

  // ---------------------------------------------------------------------------
  // Notifications push
  // ---------------------------------------------------------------------------
  static const String myDevices                  = '/me/devices';
  static const String myNotificationPreferences  = '/me/notification-preferences';
  // D19 — Granular notification preferences (all users, channel × type)
  static const String myNotificationPreferencesGranular = '/me/notification-preferences/granular';
  // D20 — Notifications log (inbox)
  static const String myNotificationsLog = '/me/notifications-log';
  static String myNotificationsLogMarkRead(int id) =>
      '/me/notifications-log/$id/read';
  static const String myNotificationsLogReadAll =
      '/me/notifications-log/read-all';

  // ---------------------------------------------------------------------------
  // My Schedule (authenticated employee endpoints)
  // ---------------------------------------------------------------------------
  static const String mySchedule         = '/my-schedule';
  static const String myScheduleUpcoming = '/my-schedule/upcoming';
  static const String myScheduleWalkIn   = '/my-schedule/walk-in';
  static String myScheduleAppointmentStatus(String id) =>
      '/my-schedule/appointments/$id/status';
  static const String myScheduleSettings = '/my-schedule/settings';
  static const String myScheduleHours    = '/my-schedule/hours';
  static const String myScheduleBreaks   = '/my-schedule/breaks';
  static const String myScheduleDaysOff  = '/my-schedule/days-off';

  static String myScheduleBreak(String id)  => '/my-schedule/breaks/$id';
  static String myScheduleDayOff(String id) => '/my-schedule/days-off/$id';
}
