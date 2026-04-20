import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive.dart';
import 'role_selection_screen_desktop.dart';
import 'role_selection_screen_mobile.dart';

/// Thin responsive wrapper — dispatches to [RoleSelectionScreenMobile] below
/// [Breakpoints.desktop] and to [RoleSelectionScreenDesktop] above.
///
/// No shared state or business logic lives here: both presentations are
/// self-contained and read their own providers directly.
class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ResponsiveLayout(
      mobile: RoleSelectionScreenMobile(),
      desktop: RoleSelectionScreenDesktop(),
    );
  }
}
