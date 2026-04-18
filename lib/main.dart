import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charge la locale persistée avant le premier frame.
  final container = ProviderContainer();
  await container.read(localeProvider.notifier).load();

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
