import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

enum UserRole { user, company }

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

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
    this.role,
    this.token,
    this.rememberMe = true, // default: remember the user
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    UserModel? user,
    UserRole? role,
    String? token,
    bool? rememberMe,
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
  // Remember-me toggle (called from login screen checkbox)
  // ---------------------------------------------------------------------------

  void toggleRememberMe() {
    state = state.copyWith(rememberMe: !state.rememberMe);
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
        role: session.role == 'company' ? UserRole.company : UserRole.user,
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
        role: response.role == 'company' ? UserRole.company : UserRole.user,
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
        role: response.role == 'company' ? UserRole.company : UserRole.user,
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
      // TODO: obtain idToken via google_sign_in package then pass it here.
      // final googleUser = await GoogleSignIn().signIn();
      // final auth = await googleUser!.authentication;
      // final idToken = auth.idToken!;
      throw UnimplementedError(
        'Google Sign-In: intégrez google_sign_in pour obtenir l\'idToken.',
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
      // TODO: obtain accessToken via flutter_facebook_auth then pass it here.
      // final result = await FacebookAuth.instance.login();
      // final accessToken = result.accessToken!.token;
      throw UnimplementedError(
        'Facebook Login: intégrez flutter_facebook_auth pour obtenir l\'accessToken.',
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

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // Always clear local state even if server revocation fails.
    }
    // Reset to initial state while preserving the rememberMe preference so
    // the checkbox default stays coherent on the next login screen visit.
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

final localeProvider = StateProvider<Locale>((ref) => const Locale('fr'));
