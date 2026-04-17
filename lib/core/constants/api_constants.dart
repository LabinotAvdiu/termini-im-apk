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
  static String companyAvailability(String id) => '/companies/$id/availability';

  // ---------------------------------------------------------------------------
  // Bookings
  // ---------------------------------------------------------------------------
  static const String bookings = '/bookings';
  static String bookingDetail(String id) => '/bookings/$id';

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

  // ---------------------------------------------------------------------------
  // My Schedule (authenticated employee endpoints)
  // ---------------------------------------------------------------------------
  static const String mySchedule         = '/my-schedule';
  static const String myScheduleWalkIn   = '/my-schedule/walk-in';
  static const String myScheduleSettings = '/my-schedule/settings';
  static const String myScheduleHours    = '/my-schedule/hours';
  static const String myScheduleBreaks   = '/my-schedule/breaks';
  static const String myScheduleDaysOff  = '/my-schedule/days-off';

  static String myScheduleBreak(String id)  => '/my-schedule/breaks/$id';
  static String myScheduleDayOff(String id) => '/my-schedule/days-off/$id';
}
