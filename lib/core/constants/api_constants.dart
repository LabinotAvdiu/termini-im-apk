abstract class ApiConstants {
  static const String baseUrl = 'http://localhost:8080/api';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------
  static const String login               = '/auth/login';
  static const String register            = '/auth/register';
  static const String googleAuth          = '/auth/google';
  static const String facebookAuth        = '/auth/facebook';
  static const String refreshToken        = '/auth/refresh';
  static const String logout              = '/auth/logout';
  static const String profile             = '/auth/profile';

  // Password reset flow
  static const String forgotPassword      = '/auth/forgot-password';
  static const String resetPassword       = '/auth/reset-password';

  // Email verification
  static const String verifyEmail         = '/auth/verify-email';
  static const String resendVerification  = '/auth/resend-verification';

  // ---------------------------------------------------------------------------
  // Companies
  // ---------------------------------------------------------------------------
  static const String companies = '/companies';
  static String companyDetail(String id)    => '/companies/$id';
  static String companyServices(String id)  => '/companies/$id/services';
  static String companyEmployees(String id) => '/companies/$id/employees';
  static String companySlots(String id)     => '/companies/$id/slots';

  // ---------------------------------------------------------------------------
  // Bookings
  // ---------------------------------------------------------------------------
  static const String bookings = '/bookings';
  static String bookingDetail(String id) => '/bookings/$id';
}
