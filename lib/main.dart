import 'dart:ui' show PlatformDispatcher;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages — part of the Flutter SDK, no pubspec entry needed
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app.dart';
import 'core/notifications/models/in_app_notification.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/providers/in_app_notification_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/error_reporter_service.dart';
import 'core/services/models/error_report.dart';
import 'core/services/remote_config_service.dart';
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

  // E28 — Backend error reporter : initialise avant les hooks d'erreur.
  await ErrorReporterService.instance.init();

  // E26 — Crashlytics : active la collection uniquement hors debug et hors web.
  // Dual-report : chaque erreur est envoyée à Crashlytics ET au backend Laravel.
  if (!kIsWeb) {
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      ErrorReporterService.instance.report(ErrorReport(
        platform: detectPlatform(),
        appVersion: ErrorReporterService.instance.appVersion,
        errorType: 'FlutterError',
        message: details.exceptionAsString(),
        stackTrace: details.stack?.toString(),
        occurredAt: DateTime.now(),
      ));
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      ErrorReporterService.instance.report(ErrorReport(
        platform: detectPlatform(),
        appVersion: ErrorReporterService.instance.appVersion,
        errorType: 'AsyncError',
        message: error.toString(),
        stackTrace: stack.toString(),
        occurredAt: DateTime.now(),
      ));
      return true;
    };
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
  }

  // E27 — Remote Config : fetch+activate avant le premier frame.
  // En cas d'échec (offline) les valeurs par défaut locales sont utilisées.
  await RemoteConfigService.instance.init();

  // Injecte le callback de navigation GoRouter.
  // La closure est lazy : elle lit le router au moment effectif du tap,
  // donc GoRouter est déjà monté même si le tap arrive au démarrage.
  //
  // Mapping type → route : la route `/appointments/:id` n'existe pas en tant
  // que détail unitaire. On oriente plutôt vers les surfaces existantes
  // selon le contexte métier de la notif.
  NotificationService.setNavigationCallback((type, appointmentId, companyId) {
    final router = container.read(routerProvider);

    // Notifs côté owner : atterrissage sur la file de validation (mode
    // capacity) ou la page du salon, depuis lesquelles l'owner retrouve
    // ses RDV.
    const ownerTypes = {
      'appointment.created',
      'walk_in_created',
      'new_review',
      'capacity_full',
      'appointment.rescheduled_by_client',
    };

    // Notifs côté client : liste des RDV — chaque RDV a sa row, dans
    // laquelle la navigation interne prend le relais.
    const clientTypes = {
      'appointment.confirmed',
      'appointment.cancelled_by_client',
      'appointment.cancelled_by_owner',
      'appointment.rejected',
      'appointment.rescheduled_by_owner',
      'appointment.reminder.evening',
      'appointment.reminder.2h',
      'appointment.review_request',
    };

    if (type != null && ownerTypes.contains(type)) {
      router.push('/pending-approvals');
      return;
    }

    if (type != null && clientTypes.contains(type)) {
      router.push('/my-appointments');
      return;
    }

    // Support reply → settings (la section support vit là aujourd'hui).
    if (type == 'support.reply') {
      router.push('/settings');
      return;
    }

    // Fallback universel : si on a un companyId, on ouvre la fiche salon
    // (partage reçu par exemple). Sinon rien — pas de route 404.
    if (companyId != null && companyId.isNotEmpty) {
      router.push('/company/$companyId');
    }
  });

  // Injecte le callback d'affichage in-app.
  // La closure est lazy : elle lit le notifier au moment effectif de l'appel.
  NotificationService.setInAppCallback((InAppNotification notification) {
    container.read(inAppNotificationProvider.notifier).show(notification);
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TakimiApp(),
    ),
  );
}
