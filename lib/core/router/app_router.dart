import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/landing_screen.dart';
import '../../features/company_detail/presentation/screens/company_detail_screen.dart';
import '../../features/booking/presentation/screens/booking_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shell/presentation/screens/main_shell.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/company/presentation/screens/capacity_settings_screen.dart';
import '../../features/company/presentation/screens/pending_approvals_screen.dart';
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
    initialLocation: '/landing',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isGuest = authState.isGuest;
      final isLoading = authState.isLoading;

      final currentPath = state.matchedLocation;

      final isAuthRoute = currentPath == '/login' ||
          currentPath == '/signup' ||
          currentPath == '/role-select' ||
          currentPath == '/forgot-password';

      final isLandingRoute = currentPath == '/landing';

      // Routes accessible without login: landing, auth routes, home, company detail.
      // Routes that require auth: /settings, /company/:id/book, /bookings.
      final isGuestAllowedRoute = isLandingRoute ||
          isAuthRoute ||
          currentPath == '/home' ||
          currentPath.startsWith('/company/');

      // Don't redirect while loading (prevents flash to login during signup/login)
      if (isLoading) return null;

      // Authenticated users on landing/auth screens → home
      if (isLoggedIn && (isLandingRoute || isAuthRoute)) {
        return '/home';
      }

      // Unauthenticated (no guest mode) trying to reach a protected route → landing
      if (!isLoggedIn && !isGuest && !isGuestAllowedRoute) {
        return '/landing';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/landing',
        name: RouteNames.landing,
        builder: (context, state) => const LandingScreen(),
      ),
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
      // ── /home — smart dispatch based on auth state ──────────────────
      // Authenticated users get the MainShell (bottom nav + IndexedStack).
      // Guests get the bare HomeScreen with no bottom nav.
      GoRoute(
        path: '/home',
        name: RouteNames.home,
        builder: (context, state) {
          // Read auth state directly in the builder so the widget tree
          // can use ProviderScope; ref is not available here, so we rely
          // on the Consumer inside MainShell / HomeScreen for reactivity.
          // The redirect guard above already ensures only valid users
          // reach this route, so we just pick the right widget.
          return const _HomeDispatcher();
        },
      ),
      GoRoute(
        path: '/settings',
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/capacity-settings',
        name: RouteNames.capacitySettings,
        builder: (context, state) => const CapacitySettingsScreen(),
      ),
      GoRoute(
        path: '/pending-approvals',
        name: RouteNames.pendingApprovals,
        builder: (context, state) => const PendingApprovalsScreen(),
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

// ---------------------------------------------------------------------------
// _HomeDispatcher
//
// Shown at /home. Authenticated users get the MainShell (bottom nav);
// guests get the bare HomeScreen with no bottom navigation.
// ---------------------------------------------------------------------------

class _HomeDispatcher extends ConsumerWidget {
  const _HomeDispatcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(
      authStateProvider.select((s) => s.isAuthenticated),
    );

    if (isAuthenticated) {
      return const MainShell();
    }
    return const HomeScreen();
  }
}
