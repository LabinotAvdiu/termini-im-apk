import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/notifications/widgets/in_app_notification_overlay.dart';
import 'core/services/analytics_service.dart';
import 'core/services/remote_config_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/widgets/session_expired_overlay.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/remote_config/presentation/screens/force_update_screen.dart';
import 'features/remote_config/presentation/screens/maintenance_screen.dart';

class TakimiApp extends ConsumerStatefulWidget {
  const TakimiApp({super.key});

  @override
  ConsumerState<TakimiApp> createState() => _TakimiAppState();
}

class _TakimiAppState extends ConsumerState<TakimiApp> {
  bool _localeSynced = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final authState = ref.watch(authStateProvider);
    final rc = ref.watch(remoteConfigProvider);

    // Sync locale from user's DB preference after login (once per session).
    // Uses setLocale so it also persists the server value locally.
    if (authState.isAuthenticated && !_localeSynced) {
      _localeSynced = true;
      final userLocale = authState.user?.locale;
      if (userLocale != null &&
          (userLocale == 'fr' || userLocale == 'en' || userLocale == 'sq')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(localeProvider.notifier).setLocale(userLocale);
        });
      }
    }
    if (!authState.isAuthenticated) {
      _localeSynced = false;
    }

    // E27 — Force update : écran bloquant non-dismissible.
    if (rc.forceUpdateRequired) {
      return MaterialApp(
        title: 'Termini im',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ForceUpdateScreen(),
      );
    }

    // E27 — Maintenance : écran bloquant non-dismissible.
    if (rc.maintenanceMode) {
      return MaterialApp(
        title: 'Termini im',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MaintenanceScreen(),
      );
    }

    // E27 — Onboarding A/B : set user property pour le suivi Analytics.
    // Le variant est lu ici pour logger la propriété une seule fois au démarrage.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final variant = rc.newOnboardingVariant;
      ref.read(analyticsProvider).setOnboardingVariant(variant);
    });

    return MaterialApp.router(
      // The ValueKey forces a full rebuild whenever the locale changes,
      // ensuring GoRouter and all cached routes are re-rendered in the new
      // language — this is the missing piece that was preventing updates.
      key: ValueKey(locale.languageCode),
      title: 'Termini im',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      // The in-app notification overlay must live *inside* MaterialApp so it
      // inherits Directionality, Theme and MediaQuery. MaterialApp.router's
      // `builder` receives the Navigator as `child` — wrapping it here gives
      // us a global overlay that floats above every route while still having
      // access to the Material context.
      builder: (context, child) {
        // Session-expired overlay sits OUTSIDE the in-app notification
        // overlay so it sees the same Navigator + Theme + Directionality.
        // Both wrappers must live inside MaterialApp.router for that.
        return SessionExpiredOverlay(
          child: InAppNotificationOverlay(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
