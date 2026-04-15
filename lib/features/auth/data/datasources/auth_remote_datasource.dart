import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

/// Raw response from the Laravel auth endpoints.
///
/// Laravel returns the shape:
/// {
///   "success": true,
///   "message": "...",
///   "data": {
///     "token":         "...",
///     "refresh_token": "...",
///     "user":          { UserResource },
///     "role":          "user|company"
///   }
/// }
class AuthResponse {
  final String token;
  final String? refreshToken;
  final UserModel user;
  final String role; // 'user' | 'company'

  const AuthResponse({
    required this.token,
    this.refreshToken,
    required this.user,
    required this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Unwrap the `data` envelope that all Laravel responses use
    final data = (json['data'] ?? json) as Map<String, dynamic>;

    return AuthResponse(
      token:        data['token'] as String,
      refreshToken: data['refresh_token'] as String?,
      user:         UserModel.fromJson(data['user'] as Map<String, dynamic>),
      role:         (data['role'] as String?) ?? 'user',
    );
  }
}

class AuthRemoteDatasource {
  final DioClient _client;

  const AuthRemoteDatasource({required DioClient client}) : _client = client;

  // ---------------------------------------------------------------------------
  // login
  // ---------------------------------------------------------------------------
  Future<AuthResponse> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.login,
        data: {
          'email':       email,
          'password':    password,
          'remember_me': rememberMe,
        },
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // register
  // ---------------------------------------------------------------------------
  Future<AuthResponse> register({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.register,
        data: data,
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Google OAuth
  // ---------------------------------------------------------------------------
  Future<AuthResponse> googleLogin({required String idToken}) async {
    try {
      final response = await _client.post(
        ApiConstants.googleAuth,
        data: {'id_token': idToken},
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Facebook OAuth
  // ---------------------------------------------------------------------------
  Future<AuthResponse> facebookLogin({required String accessToken}) async {
    try {
      final response = await _client.post(
        ApiConstants.facebookAuth,
        data: {'access_token': accessToken},
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Refresh token — sends refresh_token, receives new token pair
  // ---------------------------------------------------------------------------
  Future<AuthResponse> refreshToken({required String refreshToken}) async {
    try {
      final response = await _client.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Logout — sends the current bearer token for server-side revocation
  // ---------------------------------------------------------------------------
  Future<void> logout({required String token}) async {
    try {
      await _client.post(ApiConstants.logout);
    } on DioException catch (e) {
      // Swallow 401 on logout (token already invalid), rethrow the rest.
      if (e.response?.statusCode == 401) return;
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Get profile
  // ---------------------------------------------------------------------------
  Future<UserModel> getProfile() async {
    try {
      final response = await _client.get(ApiConstants.profile);
      final data = (response.data as Map<String, dynamic>);
      // Unwrap envelope if present
      final userJson = (data['data']?['user'] ?? data) as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Update profile
  // ---------------------------------------------------------------------------
  Future<UserModel> updateProfile({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _client.put(
        ApiConstants.profile,
        data: data,
      );
      final body = (response.data as Map<String, dynamic>);
      final userJson = (body['data']?['user'] ?? body) as Map<String, dynamic>;
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Forgot password — POST /auth/forgot-password
  // ---------------------------------------------------------------------------
  Future<void> forgotPassword({required String email}) async {
    try {
      await _client.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Reset password — POST /auth/reset-password
  // ---------------------------------------------------------------------------
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _client.post(
        ApiConstants.resetPassword,
        data: {
          'token':                 token,
          'email':                 email,
          'password':              password,
          'password_confirmation': passwordConfirmation,
        },
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Verify email — POST /auth/verify-email
  // ---------------------------------------------------------------------------
  Future<void> verifyEmail({
    required String email,
    required String token,
  }) async {
    try {
      await _client.post(
        ApiConstants.verifyEmail,
        data: {
          'email': email,
          'token': token,
        },
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Resend verification email — POST /auth/resend-verification
  // ---------------------------------------------------------------------------
  Future<void> resendVerification({required String email}) async {
    try {
      await _client.post(
        ApiConstants.resendVerification,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Error mapping helper
  // ---------------------------------------------------------------------------
  ApiException _mapDioException(DioException e) {
    // The ApiInterceptor already wraps known status codes into typed exceptions
    // carried in DioException.error. Unwrap them first.
    final wrapped = e.error;
    if (wrapped is ApiException) return wrapped;

    final statusCode = e.response?.statusCode;

    // Try to extract the server error message for user-facing display.
    String? serverMessage;
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      serverMessage =
          data['message'] as String? ?? data['error'] as String?;
    }

    switch (statusCode) {
      case 401:
        return UnauthorizedException(
          message: serverMessage ?? 'Non autorisé',
        );
      case 422:
        return ApiException(
          message: serverMessage ?? 'Données invalides',
          statusCode: 422,
        );
      case 423:
        return ApiException(
          message: serverMessage ?? 'Compte temporairement bloqué',
          statusCode: 423,
        );
      case 404:
        return NotFoundException(
          message: serverMessage ?? 'Ressource introuvable',
        );
      case final code when code != null && code >= 500:
        return ServerException(
          message: serverMessage ?? 'Erreur serveur',
        );
      default:
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          return const NetworkException();
        }
        return ApiException(
          message: serverMessage ?? e.message ?? 'Erreur inconnue',
          statusCode: statusCode,
        );
    }
  }
}
