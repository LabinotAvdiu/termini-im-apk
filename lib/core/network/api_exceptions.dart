class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({super.message = 'Non autorisé'})
      : super(statusCode: 401);
}

class NotFoundException extends ApiException {
  const NotFoundException({super.message = 'Ressource introuvable'})
      : super(statusCode: 404);
}

class ServerException extends ApiException {
  const ServerException({super.message = 'Erreur serveur'})
      : super(statusCode: 500);
}

class NetworkException extends ApiException {
  const NetworkException({super.message = 'Erreur réseau'});
}
