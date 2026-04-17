import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

enum UserRole { user, company, employee }

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final UserModel? user;
  final UserRole? role;
  final String? token;
  final bool rememberMe;
  // True when the user chose to browse without logging in.
  final bool isGuest;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
    this.role,
    this.token,
    this.rememberMe = true, // default: remember the user
    this.isGuest = false,
  });

  /// Convenience getters for tab-layout decisions in MainShell.
  bool get isOwner    => role == UserRole.company;
  bool get isEmployee => role == UserRole.employee;
  bool get isClient   => role == UserRole.user;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    UserModel? user,
    UserRole? role,
    String? token,
    bool? rememberMe,
    bool? isGuest,
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
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier({required AuthRepository repository})
      : _repository = repository,
        super(const AuthState());

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
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
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
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
  return AuthNotifier(repository: repository);
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
