import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart'
    show ApiException, OwnerHasSalonException, mapDioException;
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

  /// True when the user authenticated as [role]='company' but the Company
  /// record isn't provisioned yet (fresh social sign-up). The app should
  /// route them straight to the business-info completion screen.
  final bool needsCompanySetup;

  const AuthResponse({
    required this.token,
    this.refreshToken,
    required this.user,
    required this.role,
    this.needsCompanySetup = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;

    final userJson = data['user'] as Map<String, dynamic>;
    return AuthResponse(
      token:             data['token'] as String,
      refreshToken:      data['refresh_token'] as String?,
      user:              UserModel.fromJson(userJson),
      role:              (data['role'] as String?) ?? (userJson['role'] as String?) ?? 'user',
      needsCompanySetup: (data['needsCompanySetup'] as bool?) ?? false,
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
  // checkEmail — returns true if the email is available, false if taken
  // ---------------------------------------------------------------------------
  Future<bool> checkEmail(String email) async {
    try {
      final response = await _client.get(
        '/auth/check-email',
        queryParameters: {'email': email},
      );
      final data = response.data as Map<String, dynamic>;
      return data['available'] as bool? ?? true;
    } on DioException {
      return true;
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
  Future<AuthResponse> googleLogin({
    String? idToken,
    String? accessToken,
    String? role, // 'user' | 'company' — only used for first-time creation
  }) async {
    assert(idToken != null || accessToken != null,
        'googleLogin requires either idToken (mobile) or accessToken (web)');
    try {
      final response = await _client.post(
        ApiConstants.googleAuth,
        data: {
          if (idToken != null) 'id_token': idToken,
          if (accessToken != null) 'access_token': accessToken,
          if (role != null) 'role': role,
        },
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Complete company signup — called after a social auth where the user
  // picked role=company but the Company record isn't created yet.
  // ---------------------------------------------------------------------------
  Future<AuthResponse> completeCompanySignup({
    required String companyName,
    required String address,
    required String companyGender, // 'men' | 'women' | 'both'
    String? city,
    String? phone,
    String? bookingMode, // 'employee_based' | 'capacity_based'
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.completeCompany,
        data: {
          'company_name':   companyName,
          'address':        address,
          'company_gender': companyGender,
          if (city != null) 'city': city,
          if (phone != null) 'phone': phone,
          if (bookingMode != null) 'booking_mode': bookingMode,
          if (latitude != null && longitude != null) ...{
            'latitude':  latitude,
            'longitude': longitude,
          },
        },
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Facebook OAuth
  // ---------------------------------------------------------------------------
  Future<AuthResponse> facebookLogin({
    required String accessToken,
    String? role, // 'user' | 'company' — only used for first-time creation
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.facebookAuth,
        data: {
          'access_token': accessToken,
          if (role != null) 'role': role,
        },
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Apple OAuth
  // ---------------------------------------------------------------------------
  /// Send Apple's identity token to the backend. [firstName] / [lastName]
  /// are only provided by Apple on the first sign-in; they're optional so
  /// subsequent logins still resolve the existing account by its sub claim.
  Future<AuthResponse> appleLogin({
    required String identityToken,
    String? authorizationCode,
    String? firstName,
    String? lastName,
    String? role, // 'user' | 'company' — only used for first-time creation
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.appleAuth,
        data: {
          'identity_token': identityToken,
          if (authorizationCode != null) 'authorization_code': authorizationCode,
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (role != null) 'role': role,
        },
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
      final body = response.data as Map<String, dynamic>;
      final envelope = (body['data'] ?? body) as Map<String, dynamic>;
      final userJson = (envelope['user'] ?? envelope) as Map<String, dynamic>;
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
      final body = response.data as Map<String, dynamic>;
      // Accept any of: `{data: {user: {...}}}`, `{data: {...}}`, `{...}`
      final envelope = (body['data'] ?? body) as Map<String, dynamic>;
      final userJson = (envelope['user'] ?? envelope) as Map<String, dynamic>;
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
  // Change password — PUT /auth/change-password
  // ---------------------------------------------------------------------------
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _client.put(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Delete account — DELETE /auth/account
  //
  // Returns normally on 204. Throws [OwnerHasSalonException] when the server
  // returns 422 with code=owner_has_active_salon; [ApiException] otherwise.
  // ---------------------------------------------------------------------------
  Future<void> deleteAccount() async {
    try {
      await _client.delete(ApiConstants.deleteAccount);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data   = e.response?.data;
      if (status == 422 && data is Map<String, dynamic>) {
        final code = data['code'] as String?;
        if (code == 'owner_has_active_salon') {
          throw const OwnerHasSalonException();
        }
      }
      throw _mapDioException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Error mapping helper — delegates to the shared mapper in api_exceptions.
  // ---------------------------------------------------------------------------
  ApiException _mapDioException(DioException e) => mapDioException(e);
}
