import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';
import 'appointments_screen_desktop.dart';
import 'appointments_screen_mobile.dart';

/// Responsive wrapper for the appointments screen.
///
/// Delegates to [AppointmentsScreenMobile] on narrow screens (< 1100 px)
/// and to [AppointmentsScreenDesktop] on wide screens (≥ 1100 px).
class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const AppointmentsScreenMobile(),
      desktop: const AppointmentsScreenDesktop(),
    );
  }
}
