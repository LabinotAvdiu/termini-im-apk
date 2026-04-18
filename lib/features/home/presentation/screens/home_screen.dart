import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/home_providers.dart';
import 'home_screen_mobile.dart';
import 'home_screen_desktop.dart';

/// Thin wrapper — owns the shared refresh logic and dispatches to the correct
/// presentation via [ResponsiveLayout].
///
/// Keep all business logic here (refresh, future pagination). Both
/// [HomeScreenMobile] and [HomeScreenDesktop] are stateless presenters.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> handleRefresh() =>
        ref.read(companyListProvider.notifier).refresh();

    return ResponsiveLayout(
      mobile: HomeScreenMobile(onRefresh: handleRefresh),
      desktop: HomeScreenDesktop(onRefresh: handleRefresh),
    );
  }
}
