import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages — part of the Flutter SDK, no pubspec entry needed
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web only — serve clean URLs (`/company/5`) instead of the default hash
  // routing (`/#/company/5`). This is required for shared links to resolve
  // correctly when a recipient opens the URL in a fresh browser. In prod,
  // the hosting nginx/Apache must fall back to index.html for unknown paths.
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Charge la locale persistée avant le premier frame.
  final container = ProviderContainer();
  await container.read(localeProvider.notifier).load();

  // Facebook SDK — init web (no-op sur mobile). Nécessaire pour que
  // FacebookAuth.login() ouvre la popup OAuth côté navigateur.
  if (kIsWeb) {
    await FacebookAuth.i.webAndDesktopInitialize(
      appId: '1262066146100608',
      cookie: true,
      xfbml: true,
      version: 'v18.0',
    );
  }

  // Initialise Firebase + FCM.
  // Si Firebase n'est pas encore configuré (placeholders dev), l'app continue
  // normalement — NotificationService.init() absorbe l'erreur en interne.
  await NotificationService.init();

  // Injecte le callback de navigation GoRouter.
  // La closure est lazy : elle lit le router au moment effectif du tap,
  // donc GoRouter est déjà monté même si le tap arrive au démarrage.
  NotificationService.setNavigationCallback((appointmentId, companyId) {
    final router = container.read(routerProvider);
    if (appointmentId != null && appointmentId.isNotEmpty) {
      // Route vers le détail du rendez-vous.
      // TODO: crée la route /appointments/:id dans app_router.dart si elle n'existe pas.
      router.push('/appointments/$appointmentId');
    } else if (companyId != null && companyId.isNotEmpty) {
      router.push('/company/$companyId');
    }
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TakimiApp(),
    ),
  );
}
