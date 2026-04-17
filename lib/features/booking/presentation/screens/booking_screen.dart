import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_required_modal.dart';
import '../providers/booking_provider.dart';
import '../widgets/step_indicator.dart';
import '../widgets/employee_selection.dart';
import '../widgets/time_slot_selection.dart';
import '../widgets/booking_confirmation.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String companyId;
  final String? serviceId;

  const BookingScreen({
    super.key,
    required this.companyId,
    this.serviceId,
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
          );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleConfirm() async {
    final booking = await ref
        .read(bookingProvider.notifier)
        .confirmBooking(companyId: widget.companyId);

    if (!mounted) return;

    if (booking != null) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BookingSuccessDialog(
        onDone: () {
          Navigator.of(context).pop(); // close dialog
          context.go('/home');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingProvider);

    // Sync PageView when step changes via provider (back button)
    ref.listen<BookingState>(bookingProvider, (previous, next) {
      if (previous?.currentStep != next.currentStep) {
        _animateToStep(next.currentStep);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _BookingAppBar(
        serviceId: widget.serviceId,
        serviceName: state.serviceName,
        onBack: () {
          if (state.currentStep > 0) {
            ref.read(bookingProvider.notifier).previousStep();
          } else {
            context.go('/company/${widget.companyId}');
          }
        },
      ),
      body: state.isLoading && state.employees.isEmpty
          ? const _LoadingView()
          : Column(
              children: [
                // Step indicator (2 steps now)
                Container(
                  color: AppColors.surface,
                  child: StepIndicator(
                    currentStep: state.currentStep,
                    totalSteps: 2,
                    labels: [context.l10n.bookAppointment, context.l10n.step3Title],
                  ),
                ),
                const Divider(height: 1),

                // Step content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      _EmployeeAndTimeStep(),
                      BookingConfirmation(),
                    ],
                  ),
                ),

                // Bottom navigation buttons
                _BottomNavBar(
                  state: state,
                  onNext: () {
                    final authState = ref.read(authStateProvider);
                    if (!authState.isAuthenticated) {
                      showAuthRequiredModal(context);
                      return;
                    }
                    ref.read(bookingProvider.notifier).nextStep();
                  },
                  onBack: () {
                    ref.read(bookingProvider.notifier).previousStep();
                  },
                  onConfirm: _handleConfirm,
                ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Combined Step 1: Employee + Time Slots
// ---------------------------------------------------------------------------

class _EmployeeAndTimeStep extends ConsumerStatefulWidget {
  const _EmployeeAndTimeStep();

  @override
  ConsumerState<_EmployeeAndTimeStep> createState() =>
      _EmployeeAndTimeStepState();
}

class _EmployeeAndTimeStepState extends ConsumerState<_EmployeeAndTimeStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectFirstDate();
    });
  }

  void _autoSelectFirstDate() {
    final notifier = ref.read(bookingProvider.notifier);
    final state = ref.read(bookingProvider);
    if (state.selectedDate == null && state.availableSlots.isNotEmpty) {
      final firstDate = state.availableSlots.first.dateTime;
      notifier.selectDate(
        DateTime(firstDate.year, firstDate.month, firstDate.day),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Employee selection (compact horizontal chips)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          child: const EmployeeSelection(),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Divider(height: AppSpacing.lg),
        ),

        // Time slot selection (takes remaining space)
        const Expanded(child: TimeSlotSelection()),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// AppBar
// ---------------------------------------------------------------------------

class _BookingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? serviceId;
  final String? serviceName;
  final VoidCallback onBack;

  const _BookingAppBar({
    required this.serviceId,
    required this.serviceName,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.bookingAppBarTitle, style: AppTextStyles.h3),
          if (serviceName != null)
            Text(
              serviceName!,
              style: AppTextStyles.caption,
            ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: onBack,
        tooltip: context.l10n.back,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom navigation bar
// ---------------------------------------------------------------------------

class _BottomNavBar extends StatelessWidget {
  final BookingState state;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  const _BottomNavBar({
    required this.state,
    required this.onNext,
    required this.onBack,
    required this.onConfirm,
  });

  bool get _canProceed {
    return switch (state.currentStep) {
      0 => state.canProceedStep0 && state.canProceedStep1,
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = state.currentStep == 1;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button (hidden on step 0)
          if (state.currentStep > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: SizedBox(
                height: 52,
                width: 52,
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
              ),
            ),

          // Next / Confirm button
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _canProceed && !state.isLoading
                    ? (isLastStep ? onConfirm : onNext)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.border,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  elevation: _canProceed ? 2 : 0,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastStep
                                ? context.l10n.confirmBooking
                                : context.l10n.continueLabel,
                            style: AppTextStyles.button
                                .copyWith(color: Colors.white),
                          ),
                          if (!isLastStep) ...[
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading view
// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

// ---------------------------------------------------------------------------
// Success dialog
// ---------------------------------------------------------------------------

class _BookingSuccessDialog extends StatefulWidget {
  final VoidCallback onDone;

  const _BookingSuccessDialog({required this.onDone});

  @override
  State<_BookingSuccessDialog> createState() => _BookingSuccessDialogState();
}

class _BookingSuccessDialogState extends State<_BookingSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

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
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
              scale: _scaleAnimation,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.bookingConfirmed,
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.bookingSuccessMessage,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: context.l10n.backToHome,
              onPressed: widget.onDone,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
