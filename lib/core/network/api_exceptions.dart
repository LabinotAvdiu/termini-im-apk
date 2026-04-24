/// High-level error categories that can be localized at the UI layer.
enum ApiErrorKind {
  network,
  unauthorized,
  notFound,
  server,
  validation,
  unknown,
}

/// Exception carrying a stable [kind] plus the raw server message.
///
/// Never expose [message] directly to the user — use [errorMessage] from the
/// BuildContext extension to look up a localized string based on [kind].
/// [message] is kept only for logs / developer tooling and for validation
/// errors where the backend message is already user-facing.
class ApiException implements Exception {
  final ApiErrorKind kind;
  final String message;
  final int? statusCode;

  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ApiException(${kind.name}, $statusCode): $message';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({super.message = 'unauthorized'})
      : super(kind: ApiErrorKind.unauthorized, statusCode: 401);
}

class NotFoundException extends ApiException {
  const NotFoundException({super.message = 'not_found'})
      : super(kind: ApiErrorKind.notFound, statusCode: 404);
}

class ServerException extends ApiException {
  const ServerException({super.message = 'server_error'})
      : super(kind: ApiErrorKind.server, statusCode: 500);
}

class NetworkException extends ApiException {
  const NetworkException({super.message = 'network_error'})
      : super(kind: ApiErrorKind.network);
}

/// Backend-provided validation error where [message] is already user-facing
/// text (e.g. "Email already taken"). The UI may choose to show it as-is.
class ValidationException extends ApiException {
  const ValidationException({required super.message, super.statusCode = 422})
      : super(kind: ApiErrorKind.validation);
}

/// Thrown when the server rejects account deletion because the user is an
/// active owner of a salon. The UI should surface a specific blocking dialog.
class OwnerHasSalonException extends ApiException {
  const OwnerHasSalonException()
      : super(
          kind: ApiErrorKind.validation,
          message: 'owner_has_active_salon',
          statusCode: 422,
        );
}

// ---------------------------------------------------------------------------
// Dio → ApiException mapper
// ---------------------------------------------------------------------------

/// Use this from every datasource `on DioException catch (e)` block.
///
/// The interceptor may have already wrapped the exception in a typed
/// [ApiException] — we unwrap it here. For other status codes we pick the
/// right typed subclass and keep the server's user-facing message where
/// available (validation errors).
ApiException mapDioException(Object error) {
  // Lazy-type the argument as Object so datasources don't need dio imports
  // in signatures. We only read fields that DioException provides via
  // dynamic access.
  final dynamic e = error;
  final inner = e.error;
  if (inner is ApiException) return inner;

  final int? statusCode = e.response?.statusCode as int?;
  final data = e.response?.data;
  String? serverMessage;
  if (data is Map<String, dynamic>) {
    serverMessage =
        data['message'] as String? ?? data['error'] as String?;
  }

  switch (statusCode) {
    case 401:
      return UnauthorizedException(
        message: serverMessage ?? 'unauthorized',
      );
    case 404:
      return NotFoundException(
        message: serverMessage ?? 'not_found',
      );
    case 422:
    case 423:
      return ValidationException(
        message: serverMessage ?? 'validation_error',
        statusCode: statusCode!,
      );
  }

  if (statusCode != null && statusCode >= 500) {
    return ServerException(message: serverMessage ?? 'server_error');
  }

  // Connection-level failure (no response at all)
  final type = e.type?.toString() ?? '';
  if (type.contains('connectionError') ||
      type.contains('connectionTimeout') ||
      type.contains('receiveTimeout') ||
      type.contains('sendTimeout')) {
    return const NetworkException();
  }

  return ApiException(
    kind: ApiErrorKind.unknown,
    message: serverMessage ?? e.message?.toString() ?? 'unknown',
    statusCode: statusCode,
  );
}
