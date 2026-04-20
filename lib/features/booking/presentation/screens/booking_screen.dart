import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/ux_prefs_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_required_modal.dart';
import '../providers/booking_provider.dart';
import 'booking_screen_mobile.dart';
import 'booking_screen_desktop.dart';

/// Thin wrapper — owns all shared state and business logic.
///
/// Manages: [PageController], initialization, step animation, auth guard,
/// confirm flow, success dialog. Both presentation widgets only receive
/// callbacks and read providers for rendering.
class BookingScreen extends ConsumerStatefulWidget {
  final String companyId;
  final String? serviceId;
  /// Set by the router when a shared link carries `?employee=<userId>`.
  /// Forwarded to [BookingNotifier.initialize] which selects that employee
  /// after the employee list loads — skipped silently if the id doesn't
  /// match any available pro or if the salon is capacity_based.
  final String? preselectedEmployeeId;

  const BookingScreen({
    super.key,
    required this.companyId,
    this.serviceId,
    this.preselectedEmployeeId,
  });

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).initialize(
            companyId: widget.companyId,
            serviceId: widget.serviceId,
            preselectedEmployeeId: widget.preselectedEmployeeId,
          );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToStep(int step) {
    // Only PageView (mobile) needs explicit animation; desktop uses state-driven
    // conditional rendering with AnimatedSwitcher.
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleBack() {
    final step = ref.read(bookingProvider).currentStep;
    if (step > 0) {
      ref.read(bookingProvider.notifier).previousStep();
    } else {
      // Preserve `?employee=<userId>` so a recipient going back from the
      // booking flow lands on the same silently-filtered salon page they
      // came from (otherwise the service list snaps back to "all").
      final employee = widget.preselectedEmployeeId;
      final uri = Uri(
        path: '/company/${widget.companyId}',
        queryParameters: (employee != null && employee.isNotEmpty)
            ? {'employee': employee}
            : null,
      );
      context.go(uri.toString());
    }
  }

  void _handleNext() {
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated) {
      showAuthRequiredModal(context);
      return;
    }
    // Changement de step — selectionClick
    ref.read(uxPrefsProvider.notifier).selectionClick();
    ref.read(bookingProvider.notifier).nextStep();
  }

  void _handlePrevious() {
    ref.read(uxPrefsProvider.notifier).selectionClick();
    ref.read(bookingProvider.notifier).previousStep();
  }

  Future<void> _handleConfirm() async {
    // Déclenchement de la confirmation — lightImpact avant la requête
    ref.read(uxPrefsProvider.notifier).lightImpact();

    final booking = await ref
        .read(bookingProvider.notifier)
        .confirmBooking(companyId: widget.companyId);

    if (!mounted) return;

    if (booking != null) {
      // Succès major — mediumImpact
      ref.read(uxPrefsProvider.notifier).mediumImpact();
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    final isCapacityBased =
        ref.read(bookingProvider).bookingMode == 'capacity_based';
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BookingSuccessDialog(
        isPending: isCapacityBased,
        onDone: () {
          Navigator.of(context).pop();
          context.go('/home');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sync PageView when step changes via provider (e.g. back from notifier)
    ref.listen<BookingState>(bookingProvider, (previous, next) {
      if (previous?.currentStep != next.currentStep) {
        _animateToStep(next.currentStep);
      }
    });

    return ResponsiveLayout(
      mobile: BookingScreenMobile(
        companyId: widget.companyId,
        pageController: _pageController,
        onBack: _handleBack,
        onNext: _handleNext,
        onPrevious: _handlePrevious,
        onConfirm: _handleConfirm,
      ),
      desktop: BookingScreenDesktop(
        companyId: widget.companyId,
        onBack: _handleBack,
        onNext: _handleNext,
        onPrevious: _handlePrevious,
        onConfirm: _handleConfirm,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success dialog — shared between mobile and desktop (shown by the wrapper)
// ---------------------------------------------------------------------------

class _BookingSuccessDialog extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  final bool isPending;

  const _BookingSuccessDialog({required this.onDone, this.isPending = false});

  @override
  ConsumerState<_BookingSuccessDialog> createState() =>
      _BookingSuccessDialogState();
}

class _BookingSuccessDialogState extends ConsumerState<_BookingSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1200),
    );
    _controller.forward();

    // Lance le confetti uniquement si :
    // - booking confirmé (pas pending)
    // - animations activées dans les prefs
    // - MediaQuery.disableAnimations est false (a11y)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final animationsEnabled =
          ref.read(uxPrefsProvider).animationsEnabled;
      final reduceMotion =
          MediaQuery.of(context).disableAnimations;

      if (!widget.isPending && animationsEnabled && !reduceMotion) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Dialog content
        _SuccessDialogContent(
          controller: _controller,
          scaleAnimation: _scaleAnimation,
          isPending: widget.isPending,
          onDone: widget.onDone,
        ),

        // Confetti — par-dessus le dialog, depuis le haut
        Positioned(
          top: 0,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: math.pi / 2, // vers le bas
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.15,
            numberOfParticles: 18,
            gravity: 0.2,
            maxBlastForce: 20,
            minBlastForce: 8,
            // Couleurs éditoriales — 4 max pour rester classe
            colors: const [
              AppColors.primary,
              AppColors.secondary,
              AppColors.ivoryAlt,
              Colors.white,
            ],
            // Paillettes rectangulaires 6×14 — pas des ronds kitsch
            createParticlePath: (size) {
              final path = Path();
              path.addRect(Rect.fromLTWH(0, 0, 6, 14));
              return path;
            },
          ),
        ),
      ],
    );
  }
}

// Extracted to keep the stateful widget lean
class _SuccessDialogContent extends StatelessWidget {
  final AnimationController controller;
  final Animation<double> scaleAnimation;
  final bool isPending;
  final VoidCallback onDone;

  const _SuccessDialogContent({
    required this.controller,
    required this.scaleAnimation,
    required this.isPending,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: scaleAnimation,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isPending
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPending
                      ? Icons.hourglass_top_rounded
                      : Icons.check_circle_rounded,
                  color: isPending ? AppColors.primary : AppColors.success,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isPending
                  ? context.l10n.bookingPendingTitle
                  : context.l10n.bookingConfirmed,
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isPending
                  ? context.l10n.bookingPendingMessage
                  : context.l10n.bookingSuccessMessage,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: context.l10n.backToHome,
              onPressed: onDone,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
