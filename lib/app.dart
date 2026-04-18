import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

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
    );
  }
}
