import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';
import 'submit_review_screen_desktop.dart';
import 'submit_review_screen_mobile.dart';

export 'submit_review_screen_desktop.dart' show showSubmitReviewDialog;

/// Responsive wrapper for the submit-review flow.
///
/// - Mobile (< 1100 px): full-screen Scaffold via [SubmitReviewScreenMobile]
/// - Desktop (≥ 1100 px): renders the mobile scaffold as a fallback for the
///   route, but the preferred entry point is [showSubmitReviewDialog] which
///   opens a compact Dialog (560 px max-width, 75 vh max-height).
///
/// On desktop the button in the appointments card should call
/// [showSubmitReviewDialog] instead of pushing this route.
class SubmitReviewScreen extends StatelessWidget {
  final String appointmentId;

  const SubmitReviewScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    // On desktop, if arrived via route, show the dialog immediately over
    // a transparent barrier and pop when done.
    if (ResponsiveLayout.isDesktop(context)) {
      return _DesktopRouteWrapper(appointmentId: appointmentId);
    }
    return SubmitReviewScreenMobile(appointmentId: appointmentId);
  }
}

/// On desktop, when the route is pushed directly (e.g. deep-link), we show
/// a transparent scaffold and immediately open the dialog, then pop.
class _DesktopRouteWrapper extends StatefulWidget {
  final String appointmentId;

  const _DesktopRouteWrapper({required this.appointmentId});

  @override
  State<_DesktopRouteWrapper> createState() => _DesktopRouteWrapperState();
}

class _DesktopRouteWrapperState extends State<_DesktopRouteWrapper> {
  @override
  void initState() {
    super.initState();
    // Open dialog on next frame so the scaffold is mounted first.
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    if (!mounted) return;
    await showSubmitReviewDialog(
      context,
      appointmentId: widget.appointmentId,
    );
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    // Transparent scaffold — the dialog sits on top.
    return const Scaffold(
      backgroundColor: Colors.transparent,
    );
  }
}
