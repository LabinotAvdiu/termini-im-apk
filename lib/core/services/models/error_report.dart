/// Représente une erreur Flutter à remonter au backend.
///
/// Sérialisé en JSON pour l'endpoint POST /errors.
class ErrorReport {
  const ErrorReport({
    required this.platform,
    required this.appVersion,
    required this.errorType,
    required this.message,
    required this.occurredAt,
    this.stackTrace,
    this.route,
    this.httpStatus,
    this.httpUrl,
    this.context,
  });

  /// Plateforme de l'appareil : android | ios | web.
  final String platform;

  /// Version de l'app, ex: 1.0.0+2 (via package_info_plus).
  final String appVersion;

  /// Catégorie technique : FlutterError | DioException | AsyncError |
  /// PlatformException | HttpException.
  final String errorType;

  /// Message brut de l'exception (tronqué à 5000 chars avant envoi).
  final String message;

  /// Stack trace Dart (tronquée à 20 000 chars avant envoi).
  final String? stackTrace;

  /// Route GoRouter active au moment de l'erreur.
  final String? route;

  /// Code HTTP — rempli uniquement pour les DioException.
  final int? httpStatus;

  /// URL de la requête qui a échoué — pour les DioException.
  final String? httpUrl;

  /// Métadonnées libres : appointmentId, locale, userId, etc.
  final Map<String, dynamic>? context;

  /// Timestamp client, fidèle même si l'upload est différé.
  final DateTime occurredAt;

  Map<String, dynamic> toJson() => {
    'platform': platform,
    'app_version': appVersion,
    'error_type': errorType,
    'message': message.length > 5000 ? message.substring(0, 5000) : message,
    if (stackTrace != null)
      'stack_trace': stackTrace!.length > 20000
          ? stackTrace!.substring(0, 20000)
          : stackTrace,
    if (route != null) 'route': route,
    if (httpStatus != null) 'http_status': httpStatus,
    if (httpUrl != null)
      'http_url': httpUrl!.length > 2000
          ? httpUrl!.substring(0, 2000)
          : httpUrl,
    if (context != null) 'context': context,
    'occurred_at': occurredAt.toIso8601String(),
  };
}
