import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/company_detail/presentation/screens/company_detail_screen.dart';
import '../../features/booking/presentation/screens/booking_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'route_names.dart';

/// A [ChangeNotifier] that fires whenever the auth state changes.
/// Used by GoRouter's refreshListenable so the router doesn't get
/// recreated on every state change (which would reset to initialLocation).
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AuthState>(authStateProvider, (_, _) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isLoading = authState.isLoading;

      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/role-select' ||
          state.matchedLocation == '/forgot-password';

      // Don't redirect while loading (prevents flash to login during signup/login)
      if (isLoading) return null;

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: RouteNames.signup,
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'user';
          return SignupScreen(role: role);
        },
      ),
      GoRoute(
        path: '/role-select',
        name: RouteNames.roleSelect,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/company/:id',
        name: RouteNames.companyDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CompanyDetailScreen(companyId: id);
        },
        routes: [
          GoRoute(
            path: 'book',
            name: RouteNames.booking,
            builder: (context, state) {
              final companyId = state.pathParameters['id']!;
              final serviceId = state.uri.queryParameters['serviceId'];
              return BookingScreen(
                companyId: companyId,
                serviceId: serviceId,
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page introuvable: ${state.error}'),
      ),
    ),
  );
});
