/// Base URL pointing at the Flutter Web deployment. All shared links resolve
/// to the web app, which then either serves the booking flow directly (web
/// recipient) or — once App Links / Universal Links are configured — opens
/// the native app on Android/iOS.
const String kShareBaseUrl = 'https://app.termini-im.com';

/// Build the canonical "share salon" URL. The link always points at the
/// salon detail page (NOT the booking flow) so the recipient can pick a
/// service first — booking can't start without one.
///
/// When [employeeId] is provided, the salon detail filters services to
/// those that employee can perform and forwards the employee through to the
/// booking screen on "Choisir".
///
/// Shape:
///   https://app.termini-im.com/company/{companyId}
///   https://app.termini-im.com/company/{companyId}?employee={employeeId}
String buildSalonShareUrl(String companyId, {String? employeeId}) {
  final base = Uri.parse('$kShareBaseUrl/company/$companyId');
  if (employeeId == null || employeeId.isEmpty) return base.toString();
  return base.replace(queryParameters: {'employee': employeeId}).toString();
}
