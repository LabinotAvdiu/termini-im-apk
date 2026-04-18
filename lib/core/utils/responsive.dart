import 'package:flutter/widgets.dart';

/// Responsive breakpoints used across the app.
///
/// Anything at or above [desktop] width picks the desktop presentation;
/// below falls back to the mobile presentation.
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1100;
}

/// Picks between [mobile] and [desktop] presentations based on screen width.
///
/// Keep shared logic (providers, state, navigation calls) in the parent that
/// wraps this widget — the two presentation widgets should only differ in
/// layout. Use [tablet] to override the mid-range breakpoint.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= Breakpoints.desktop;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= Breakpoints.tablet && w < Breakpoints.desktop;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < Breakpoints.tablet;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= Breakpoints.desktop) return desktop;
    if (width >= Breakpoints.tablet) return tablet ?? desktop;
    return mobile;
  }
}
