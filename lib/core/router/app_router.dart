import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/company_setup_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/appointments/presentation/screens/appointments_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/landing_screen.dart';
import '../../features/company_detail/presentation/screens/company_detail_screen.dart';
import '../../features/booking/presentation/screens/booking_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shell/presentation/screens/main_shell.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/company/presentation/screens/capacity_settings_screen.dart';
import '../../features/company/presentation/screens/my_company_reviews_screen.dart';
import '../../features/company/presentation/screens/pending_approvals_screen.dart';
import '../../features/employee_schedule/presentation/screens/schedule_settings_screen.dart';
import '../../features/reviews/presentation/screens/submit_review_screen.dart';
import 'page_transitions.dart';
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
      final isCompanySetupRoute = currentPath == '/company-setup';

      // Routes accessible without login: landing, auth routes, home, company detail.
      // Routes that require auth: /settings, /company/:id/book, /bookings.
      final isGuestAllowedRoute = isLandingRoute ||
          isAuthRoute ||
          currentPath == '/home' ||
          currentPath.startsWith('/company/');

      // Don't redirect while loading (prevents flash to login during signup/login)
      if (isLoading) return null;

      // Authenticated company accounts without a Company record yet — force
      // them through the business-info completion screen before anything else.
      if (isLoggedIn && authState.needsCompanySetup && !isCompanySetupRoute) {
        return '/company-setup';
      }

      // Authenticated users on landing/auth screens → home OR the original
      // destination captured in `?returnTo=` (e.g. a shared booking link).
      // Without this, a recipient of a shared salon link loses their URL
      // the moment they log in during the booking flow.
      if (isLoggedIn &&
          !authState.needsCompanySetup &&
          (isLandingRoute || isAuthRoute || isCompanySetupRoute)) {
        final returnTo = state.uri.queryParameters['returnTo'];
        if (returnTo != null && returnTo.isNotEmpty) {
          // Guard against loops: never honour a returnTo that points back
          // at one of the auth pages themselves.
          final loops = returnTo.startsWith('/login') ||
              returnTo.startsWith('/signup') ||
              returnTo.startsWith('/role-select') ||
              returnTo.startsWith('/landing') ||
              returnTo.startsWith('/forgot-password') ||
              returnTo.startsWith('/company-setup');
          if (!loops) return returnTo;
        }
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
        pageBuilder: (context, state) => editorialFadePage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/signup',
        name: RouteNames.signup,
        pageBuilder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'user';
          return editorialFadePage(
            key: state.pageKey,
            child: SignupScreen(role: role),
          );
        },
      ),
      GoRoute(
        path: '/role-select',
        name: RouteNames.roleSelect,
        pageBuilder: (context, state) => editorialFadePage(
          key: state.pageKey,
          child: const RoleSelectionScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        pageBuilder: (context, state) => editorialFadePage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/company-setup',
        name: RouteNames.companySetup,
        pageBuilder: (context, state) => editorialFadePage(
          key: state.pageKey,
          child: const CompanySetupScreen(),
        ),
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
        pageBuilder: (context, state) {
          // `?edit=profile` → open the Mon profil section in edit mode (used
          // by the "Complete your profile" banner on /home).
          final editProfile = state.uri.queryParameters['edit'] == 'profile';
          return editorialSlidePage(
            key: state.pageKey,
            child: SettingsScreen(startInProfileEdit: editProfile),
          );
        },
      ),
      // "Mes rendez-vous" — accessible via Settings for company members
      // (owner/employee) who also book as clients elsewhere. Clients see the
      // same screen inside the shell as a tab.
      GoRoute(
        path: '/my-appointments',
        name: RouteNames.myAppointments,
        pageBuilder: (context, state) => editorialSlidePage(
          key: state.pageKey,
          child: const _StandaloneAppointments(),
        ),
      ),
      // "Mes horaires" — weekly working hours only. The shell tab shows
      // everything in one page; here we split it so each Settings entry
      // leads straight to the relevant section.
      GoRoute(
        path: '/my-schedule',
        name: RouteNames.mySchedule,
        pageBuilder: (context, state) => editorialSlidePage(
          key: state.pageKey,
          child: const _StandaloneSchedule(view: ScheduleView.hoursOnly),
        ),
      ),
      // "Mes pauses" — recurring breaks + days off, same screen with
      // hours card hidden.
      GoRoute(
        path: '/my-breaks',
        name: RouteNames.myBreaks,
        pageBuilder: (context, state) => editorialSlidePage(
          key: state.pageKey,
          child:
              const _StandaloneSchedule(view: ScheduleView.breaksAndDaysOff),
        ),
      ),
      GoRoute(
        path: '/capacity-settings',
        name: RouteNames.capacitySettings,
        pageBuilder: (context, state) => editorialSlidePage(
          key: state.pageKey,
          child: const CapacitySettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/pending-approvals',
        name: RouteNames.pendingApprovals,
        pageBuilder: (context, state) => editorialSlidePage(
          key: state.pageKey,
          child: const PendingApprovalsScreen(),
        ),
      ),
      GoRoute(
        path: '/my-company-reviews',
        name: RouteNames.myCompanyReviews,
        pageBuilder: (context, state) => editorialSlidePage(
          key: state.pageKey,
          child: const MyCompanyReviewsScreen(),
        ),
      ),
      GoRoute(
        path: '/appointments/:id/review',
        name: RouteNames.submitReview,
        pageBuilder: (context, state) {
          final appointmentId = state.pathParameters['id']!;
          return editorialSlidePage(
            key: state.pageKey,
            fromBottom: true,
            child: SubmitReviewScreen(appointmentId: appointmentId),
          );
        },
      ),
      GoRoute(
        path: '/company/:id',
        name: RouteNames.companyDetail,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          // Shared link `/company/:id?employee={userId}` — filter services
          // on the detail page to only those the employee can perform and
          // forward the id to the booking flow on "Choisir".
          final preselectedEmployeeId =
              state.uri.queryParameters['employee'];
          return editorialSlidePage(
            key: state.pageKey,
            child: CompanyDetailScreen(
              companyId: id,
              preselectedEmployeeId: preselectedEmployeeId,
            ),
          );
        },
        routes: [
          GoRoute(
            path: 'book',
            name: RouteNames.booking,
            pageBuilder: (context, state) {
              final companyId = state.pathParameters['id']!;
              final serviceId = state.uri.queryParameters['serviceId'];
              // Shared salon links from employees carry ?employee={userId} so
              // the recipient lands on the booking screen with that pro
              // already picked. See share_url_builder.dart.
              final preselectedEmployeeId =
                  state.uri.queryParameters['employee'];
              return editorialSlidePage(
                key: state.pageKey,
                fromBottom: true,
                child: BookingScreen(
                  companyId: companyId,
                  serviceId: serviceId,
                  preselectedEmployeeId: preselectedEmployeeId,
                ),
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

/// Wraps [AppointmentsScreen] in a Scaffold with a back button when shown
/// outside of the shell (i.e. reached from Settings as a pro).
class _StandaloneAppointments extends StatelessWidget {
  const _StandaloneAppointments();

  @override
  Widget build(BuildContext context) {
    return _BackOverlay(child: const AppointmentsScreen());
  }
}

/// Wraps [ScheduleSettingsScreen] in a Scaffold with a back button. Same
/// screen as the shell tab, but the `view` picks which cards are shown so
/// "Mes horaires" and "Mes pauses" can be two distinct Settings entries.
class _StandaloneSchedule extends StatelessWidget {
  final ScheduleView view;
  const _StandaloneSchedule({required this.view});

  @override
  Widget build(BuildContext context) {
    return _BackOverlay(child: ScheduleSettingsScreen(view: view));
  }
}

/// Shared wrapper — puts a floating ivory back button on top-left so any
/// shell-aware screen can be reached from a plain GoRouter route.
class _BackOverlay extends StatelessWidget {
  final Widget child;
  const _BackOverlay({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                ),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/settings'),
                style: IconButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
