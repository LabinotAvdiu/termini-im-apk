import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/platform/web_storage_stub.dart'
    if (dart.library.html) '../../../../core/platform/web_storage_web.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../notifications/data/repositories/notification_repository.dart'
    show notificationRepositoryProvider;

enum UserRole { user, company, employee }

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  /// The last error caught by the notifier. Either an [ApiException] (for
  /// backend errors), a String (for legacy call sites) or null. UI code should
  /// pass this to `context.errorMessage(error)` to get a localized message.
  final Object? error;
  final UserModel? user;
  final UserRole? role;
  final String? token;
  final bool rememberMe;
  // True when the user chose to browse without logging in.
  final bool isGuest;
  // One-shot flag set to true right after a successful signup; the shell
  // consumes it to land a new owner on the "Mon Salon" tab, then clears it.
  final bool justSignedUp;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
    this.role,
    this.token,
    this.rememberMe = true, // default: remember the user
    this.isGuest = false,
    this.justSignedUp = false,
  });

  /// Convenience getters for tab-layout decisions in MainShell.
  bool get isOwner    => role == UserRole.company;
  bool get isEmployee => role == UserRole.employee;
  bool get isClient   => role == UserRole.user;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    Object? error,
    UserModel? user,
    UserRole? role,
    String? token,
    bool? rememberMe,
    bool? isGuest,
    bool? justSignedUp,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      // Explicit null clears the error field (pass null intentionally via
      // copyWith to reset errors after a new attempt starts).
      error: error,
      user: user ?? this.user,
      role: role ?? this.role,
      token: token ?? this.token,
      rememberMe: rememberMe ?? this.rememberMe,
      isGuest: isGuest ?? this.isGuest,
      justSignedUp: justSignedUp ?? this.justSignedUp,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  // Référence lazy vers le repository notifications — injectée depuis le
  // provider pour éviter une dépendance circulaire au moment de la création.
  Future<void> Function(String token, String platform)? _deviceRegister;
  Future<void> Function(String token)? _deviceUnregister;

  void setDeviceCallbacks({
    required Future<void> Function(String token, String platform) register,
    required Future<void> Function(String token) unregister,
  }) {
    _deviceRegister = register;
    _deviceUnregister = unregister;
  }

  AuthNotifier({required AuthRepository repository})
      : _repository = repository,
        super(const AuthState());

  // ---------------------------------------------------------------------------
  // FCM token helpers — fire-and-forget, swallent les erreurs silencieusement
  // ---------------------------------------------------------------------------

  Future<void> _registerFcmToken() async {
    if (_deviceRegister == null) return;
    await NotificationService.registerToken(_deviceRegister!);
  }

  Future<void> _unregisterFcmToken() async {
    if (_deviceUnregister == null) return;
    await NotificationService.unregisterToken(_deviceUnregister!);
  }

  // ---------------------------------------------------------------------------
  // Role resolution
  // ---------------------------------------------------------------------------

  /// Maps the API role string + optional companyRole field to [UserRole].
  ///
  /// - 'company' top-level role + companyRole == 'employee' → [UserRole.employee]
  /// - 'company' top-level role (owner or unspecified)      → [UserRole.company]
  /// - anything else                                        → [UserRole.user]
  static UserRole _resolveRole(String apiRole, UserModel? user) {
    if (apiRole == 'company') {
      if (user?.companyRole == 'employee') return UserRole.employee;
      return UserRole.company;
    }
    return UserRole.user;
  }

  // ---------------------------------------------------------------------------
  // Remember-me toggle (called from login screen checkbox)
  // ---------------------------------------------------------------------------

  void toggleRememberMe() {
    state = state.copyWith(rememberMe: !state.rememberMe);
  }

  // ---------------------------------------------------------------------------
  // Guest mode — browse without authenticating
  // ---------------------------------------------------------------------------

  void enterGuestMode() {
    state = state.copyWith(isGuest: true, error: null);
  }

  // ---------------------------------------------------------------------------
  // App-start: restore session from secure storage (rememberMe was true)
  // ---------------------------------------------------------------------------

  Future<void> checkAuthStatus() async {
    try {
      final session = await _repository.tryRestoreSession();
      if (session == null) return;

      state = state.copyWith(
        isAuthenticated: true,
        token: session.token,
        role: _resolveRole(session.role, state.user),
        error: null,
      );
    } catch (_) {
      // If restoration fails (e.g. storage corrupted), start unauthenticated.
      state = const AuthState();
    }
  }

  // ---------------------------------------------------------------------------
  // Email / password login
  // ---------------------------------------------------------------------------

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.login(
        email: email,
        password: password,
        rememberMe: state.rememberMe,
      );
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        token: response.token,
        user: response.user,
        role: _resolveRole(response.role, response.user),
        error: null,
      );
      // Enregistre le token FCM après login réussi (fire-and-forget).
      unawaited(_registerFcmToken());
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Register
  // ---------------------------------------------------------------------------

  Future<void> signup({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
    String? city,
    String? companyName,
    String? address,
    String? bookingMode,
    double? latitude,
    double? longitude,
    String? locale,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = <String, dynamic>{
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'role': role == UserRole.company ? 'company' : 'user',
        'city': city,
        'company_name': companyName,
        'address': address,
        if (bookingMode != null) 'booking_mode': bookingMode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (locale != null) 'locale': locale,
      }..removeWhere((_, v) => v == null);

      final response = await _repository.register(
        data: data,
        rememberMe: state.rememberMe,
      );

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        token: response.token,
        user: response.user,
        role: _resolveRole(response.role, response.user),
        error: null,
        justSignedUp: true,
      );
      // Enregistre le token FCM après signup réussi (fire-and-forget).
      unawaited(_registerFcmToken());
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e,
      );
    }
  }

  /// Called by the shell after consuming the one-shot flag.
  void clearJustSignedUp() {
    if (state.justSignedUp) {
      state = state.copyWith(justSignedUp: false);
    }
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Trigger Google Sign-In native flow
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled
        state = state.copyWith(isLoading: false);
        return;
      }
      final auth = await googleUser.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('Google ID token manquant');

      // 2. Send idToken to backend
      final response = await _repository.googleLogin(
        idToken: idToken,
        rememberMe: state.rememberMe,
      );

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        token: response.token,
        user: response.user,
        role: _resolveRole(response.role, response.user),
        error: null,
      );
      // Enregistre le token FCM après Google login réussi (fire-and-forget).
      unawaited(_registerFcmToken());
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // Facebook Login
  // ---------------------------------------------------------------------------

  Future<void> loginWithFacebook() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      if (result.status == LoginStatus.cancelled) {
        state = state.copyWith(isLoading: false);
        return;
      }
      if (result.status != LoginStatus.success) {
        throw Exception(result.message ?? 'Facebook login échoué');
      }
      final accessToken = result.accessToken!.tokenString;

      final response = await _repository.facebookLogin(
        accessToken: accessToken,
        rememberMe: state.rememberMe,
      );

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        token: response.token,
        user: response.user,
        role: _resolveRole(response.role, response.user),
        error: null,
      );
      // Enregistre le token FCM après Facebook login réussi (fire-and-forget).
      unawaited(_registerFcmToken());
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // Forgot password — requests a reset email; does not touch auth state
  // ---------------------------------------------------------------------------

  Future<void> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.forgotPassword(email: email);
      state = state.copyWith(isLoading: false, error: null);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // Reset password — applies the token + new password received by email
  // ---------------------------------------------------------------------------

  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.resetPassword(
        token: token,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      state = state.copyWith(isLoading: false, error: null);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // Logout — server revocation + local clear
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Update user data in state (after profile edit)
  // ---------------------------------------------------------------------------

  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  // ---------------------------------------------------------------------------
  // Logout — server revocation + local clear
  // ---------------------------------------------------------------------------

  Future<void> logout() async {
    // 1. Retire le token FCM côté backend AVANT de vider le JWT.
    //    Si ça échoue, on continue quand même (best-effort).
    await _unregisterFcmToken();

    try {
      await _repository.logout();
    } catch (_) {
      // Always clear local state even if server revocation fails.
    }
    // Reset to initial state while preserving the rememberMe preference so
    // the checkbox default stays coherent on the next login screen visit.
    // isGuest is cleared so the user lands back on /landing.
    state = AuthState(rememberMe: state.rememberMe);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final notifier = AuthNotifier(repository: repository);

  // Injecte les callbacks FCM depuis le repository notifications.
  final notifRepo = ref.read(notificationRepositoryProvider);
  notifier.setDeviceCallbacks(
    register: (token, platform) =>
        notifRepo.registerDevice(token: token, platform: platform),
    unregister: (token) => notifRepo.unregisterDevice(token: token),
  );

  return notifier;
});

// ---------------------------------------------------------------------------
// Locale — persisted StateNotifier
// ---------------------------------------------------------------------------

/// Manages the app locale with persistence in [FlutterSecureStorage].
///
/// On creation it is initialised to 'fr'. Call [load] once on app start to
/// read the persisted value, then [setLocale] to change it.
/// [setLocale] optionally syncs the change to the API when the user is
/// authenticated (pass the [AuthRepository] and the locale string).
class LocaleNotifier extends StateNotifier<Locale> {
  final FlutterSecureStorage _storage;

  LocaleNotifier(this._storage) : super(const Locale('sq'));

  /// Reads the persisted locale from secure storage and applies it.
  /// Call once from main() / app start — before the first frame if possible.
  Future<void> load() async {
    final stored = await _storage.read(key: AppConstants.localeKey);
    if (stored == 'en' || stored == 'fr' || stored == 'sq') {
      state = Locale(stored!);
      // Ensure the web splash has the up-to-date value for the next reload.
      writeWebLocale(stored);
    } else {
      // Default is 'sq' — persist it so the splash matches the app from now on.
      writeWebLocale(state.languageCode);
    }
  }

  /// Changes the locale, persists it, and optionally syncs to the backend.
  Future<void> setLocale(
    String languageCode, {
    AuthRepository? repository,
  }) async {
    if (state.languageCode == languageCode) return;

    state = Locale(languageCode);
    await _storage.write(key: AppConstants.localeKey, value: languageCode);
    // Mirror to window.localStorage on web so the splash screen can pick it up
    // on the next cold reload (no-op on mobile).
    writeWebLocale(languageCode);

    if (repository != null) {
      // Fire-and-forget: best-effort API sync — swallow errors silently.
      unawaited(
        repository
            .updateProfile(data: {'locale': languageCode})
            .then((_) {}, onError: (_) {}),
      );
    }
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  // Do NOT watch authRepositoryProvider here — that would recreate the notifier
  // (and reset the locale) whenever the auth state changes.
  const storage = FlutterSecureStorage();
  return LocaleNotifier(storage);
});
