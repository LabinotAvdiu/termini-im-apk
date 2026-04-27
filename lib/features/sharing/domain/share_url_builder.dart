/// Base URL pointing at the Flutter Web deployment. All shared links resolve
/// to the web app, which then either serves the booking flow directly (web
/// recipient) or — once App Links / Universal Links are configured — opens
/// the native app on Android/iOS.
const String kShareBaseUrl = 'https://www.termini-im.com';

/// Build the canonical "share salon" URL. The link always points at the
/// salon detail page (NOT the booking flow) so the recipient can pick a
/// service first — booking can't start without one.
///
/// When [employeeId] is provided, the salon detail filters services to
/// those that employee can perform and forwards the employee through to
/// the booking screen on "Choisir".
///
/// When [autoFavorite] is true, the URL carries `fav=1` which signals to
/// the company detail screen that the visitor arrived via a QR scan and
/// the salon should be auto-added to favorites (with the optional
/// preferred employee). Used for the Settings → Partage QR flow only.
///
/// Shape:
///   https://www.termini-im.com/company/{companyId}
///   https://www.termini-im.com/company/{companyId}?employee={employeeId}
///   https://www.termini-im.com/company/{companyId}?employee={employeeId}&fav=1
String buildSalonShareUrl(
  String companyId, {
  String? employeeId,
  bool autoFavorite = false,
}) {
  final base = Uri.parse('$kShareBaseUrl/company/$companyId');
  final params = <String, String>{
    if (employeeId != null && employeeId.isNotEmpty) 'employee': employeeId,
    if (autoFavorite) 'fav': '1',
  };
  if (params.isEmpty) return base.toString();
  return base.replace(queryParameters: params).toString();
}
