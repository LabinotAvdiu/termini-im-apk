import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create the container early so we can load persisted locale before first frame.
  final container = ProviderContainer();
  await container.read(localeProvider.notifier).load();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TakimiApp(),
    ),
  );
}
