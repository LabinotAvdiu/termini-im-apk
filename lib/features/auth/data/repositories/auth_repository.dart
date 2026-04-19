import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Stored session data reconstituted from secure storage on app start.
class StoredSession {
  final String token;
  final String? refreshToken;
  final String role;

  const StoredSession({
    required this.token,
    this.refreshToken,
    required this.role,
  });
}

/// Bridges [AuthRemoteDatasource] and the presentation layer.
///
/// Responsibilities:
/// - Persist / clear tokens in [FlutterSecureStorage].
/// - Apply "remember me" logic: when false, nothing is written to storage
///   (tokens live only in the provider's memory for the session duration).
/// - Expose [tryRestoreSession] for app-start auto-login.
class AuthRepository {
  final AuthRemoteDatasource _datasource;
  final FlutterSecureStorage _storage;

  // In-memory token cache — used when rememberMe is false so the token
  // survives navigation but is lost when the process exits.
  String? _memoryToken;
  String? _memoryRefreshToken;

  AuthRepository({
    required AuthRemoteDatasource datasource,
    FlutterSecureStorage? storage,
  })  : _datasource = datasource,
        _storage = storage ?? const FlutterSecureStorage();

  // ---------------------------------------------------------------------------
  // Session restoration (called on app start by the notifier)
  // ---------------------------------------------------------------------------

  /// Returns a [StoredSession] if a persisted token exists (rememberMe was
  /// true on the last login). Returns null otherwise.
  Future<StoredSession?> tryRestoreSession() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null) return null;

    // Check if session has expired (3 months since last refresh)
    final lastRefreshStr =
        await _storage.read(key: AppConstants.lastRefreshKey);
    if (lastRefreshStr != null) {
      final lastRefresh = DateTime.tryParse(lastRefreshStr);
      if (lastRefresh != null) {
        final daysSinceRefresh =
            DateTime.now().difference(lastRefresh).inDays;
        if (daysSinceRefresh > AppConstants.sessionMaxDays) {
          // Session expired — clear everything and force re-login
          await _clearSession();
          return null;
        }
      }
    }

    final refreshToken =
        await _storage.read(key: AppConstants.refreshTokenKey);
    final role =
        await _storage.read(key: AppConstants.userRoleKey) ?? 'user';

    return StoredSession(
      token: token,
      refreshToken: refreshToken,
      role: role,
    );
  }

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  Future<AuthResponse> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final response = await _datasource.login(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );
    await _persistSession(
      token: response.token,
      refreshToken: response.refreshToken,
      role: response.role,
      rememberMe: rememberMe,
    );
    return response;
  }

  // ---------------------------------------------------------------------------
  // Register
  // ---------------------------------------------------------------------------

  Future<bool> checkEmailAvailable(String email) =>
      _datasource.checkEmail(email);

  Future<AuthResponse> register({
    required Map<String, dynamic> data,
    bool rememberMe = true,
  }) async {
    final response = await _datasource.register(data: data);
    await _persistSession(
      token: response.token,
      refreshToken: response.refreshToken,
      role: response.role,
      rememberMe: rememberMe,
    );
    return response;
  }

  // ---------------------------------------------------------------------------
  // Social login helpers
  // ---------------------------------------------------------------------------

  Future<AuthResponse> googleLogin({
    required String idToken,
    String? role,
    bool rememberMe = true,
  }) async {
    final response = await _datasource.googleLogin(
      idToken: idToken,
      role: role,
    );
    await _persistSession(
      token: response.token,
      refreshToken: response.refreshToken,
      role: response.role,
      rememberMe: rememberMe,
    );
    return response;
  }

  Future<AuthResponse> completeCompanySignup({
    required String companyName,
    required String address,
    required String companyGender,
    String? city,
    String? phone,
    String? bookingMode,
    double? latitude,
    double? longitude,
    bool rememberMe = true,
  }) async {
    final response = await _datasource.completeCompanySignup(
      companyName: companyName,
      address: address,
      companyGender: companyGender,
      city: city,
      phone: phone,
      bookingMode: bookingMode,
      latitude: latitude,
      longitude: longitude,
    );
    await _persistSession(
      token: response.token,
      refreshToken: response.refreshToken,
      role: response.role,
      rememberMe: rememberMe,
    );
    return response;
  }

  Future<AuthResponse> facebookLogin({
    required String accessToken,
    bool rememberMe = true,
  }) async {
    final response = await _datasource.facebookLogin(accessToken: accessToken);
    await _persistSession(
      token: response.token,
      refreshToken: response.refreshToken,
      role: response.role,
      rememberMe: rememberMe,
    );
    return response;
  }

  Future<AuthResponse> appleLogin({
    required String identityToken,
    String? authorizationCode,
    String? firstName,
    String? lastName,
    bool rememberMe = true,
  }) async {
    final response = await _datasource.appleLogin(
      identityToken: identityToken,
      authorizationCode: authorizationCode,
      firstName: firstName,
      lastName: lastName,
    );
    await _persistSession(
      token: response.token,
      refreshToken: response.refreshToken,
      role: response.role,
      rememberMe: rememberMe,
    );
    return response;
  }

  // ---------------------------------------------------------------------------
  // Token refresh
  // ---------------------------------------------------------------------------

  Future<AuthResponse> refreshToken({required bool rememberMe}) async {
    final stored = await _storage.read(key: AppConstants.refreshTokenKey);
    final token = stored ?? _memoryRefreshToken;

    if (token == null) {
      throw Exception('Aucun refresh token disponible');
    }

    final response = await _datasource.refreshToken(refreshToken: token);
    await _persistSession(
      token: response.token,
      refreshToken: response.refreshToken,
      role: response.role,
      rememberMe: rememberMe,
    );
    return response;
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  Future<void> logout() async {
    final token = await _resolveToken();
    if (token != null) {
      // Fire-and-forget: revoke on server; we clear locally regardless.
      await _datasource.logout(token: token).catchError((_) {});
    }
    await _clearSession();
  }

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  Future<UserModel> getProfile() => _datasource.getProfile();

  Future<UserModel> updateProfile({required Map<String, dynamic> data}) =>
      _datasource.updateProfile(data: data);

  // ---------------------------------------------------------------------------
  // Forgot password
  // ---------------------------------------------------------------------------

  Future<void> forgotPassword({required String email}) =>
      _datasource.forgotPassword(email: email);

  // ---------------------------------------------------------------------------
  // Reset password
  // ---------------------------------------------------------------------------

  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) =>
      _datasource.resetPassword(
        token: token,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

  // ---------------------------------------------------------------------------
  // Change password
  // ---------------------------------------------------------------------------

  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) =>
      _datasource.changePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

  // ---------------------------------------------------------------------------
  // Token read helper (used by other parts of the app if needed)
  // ---------------------------------------------------------------------------

  Future<String?> getToken() => _resolveToken();

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _persistSession({
    required String token,
    required String? refreshToken,
    required String role,
    required bool rememberMe,
  }) async {
    if (rememberMe) {
      await _storage.write(key: AppConstants.tokenKey, value: token);
      if (refreshToken != null) {
        await _storage.write(
          key: AppConstants.refreshTokenKey,
          value: refreshToken,
        );
      }
      await _storage.write(key: AppConstants.userRoleKey, value: role);
      await _storage.write(
        key: AppConstants.rememberMeKey,
        value: 'true',
      );
      // Record the timestamp of this refresh/login for 3-month expiry check
      await _storage.write(
        key: AppConstants.lastRefreshKey,
        value: DateTime.now().toIso8601String(),
      );
      // Clear in-memory cache when persisting to storage.
      _memoryToken = null;
      _memoryRefreshToken = null;
    } else {
      // Keep tokens in memory only — nothing written to storage.
      _memoryToken = token;
      _memoryRefreshToken = refreshToken;
      // Ensure no stale persisted token from a previous session interferes.
      await _storage.delete(key: AppConstants.tokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      await _storage.delete(key: AppConstants.rememberMeKey);
    }
  }

  Future<void> _clearSession() async {
    _memoryToken = null;
    _memoryRefreshToken = null;
    // deleteAll clears token, refreshToken, role, rememberMe, lastRefreshAt
    await _storage.deleteAll();
  }

  Future<String?> _resolveToken() async {
    if (_memoryToken != null) return _memoryToken;
    return _storage.read(key: AppConstants.tokenKey);
  }
}
