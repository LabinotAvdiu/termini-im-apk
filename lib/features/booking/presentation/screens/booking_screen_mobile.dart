import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';
import '../providers/booking_provider.dart';
import '../widgets/step_indicator.dart';
import '../widgets/employee_selection.dart';
import '../widgets/time_slot_selection.dart';
import '../widgets/booking_confirmation.dart';

/// Mobile presentation for the booking flow.
///
/// Stateless — receives all mutable state from [BookingScreen] via props.
/// Interaction callbacks are forwarded straight to the parent wrapper.
class BookingScreenMobile extends ConsumerWidget {
  final String companyId;
  final PageController pageController;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onConfirm;

  const BookingScreenMobile({
    super.key,
    required this.companyId,
    required this.pageController,
    required this.onBack,
    required this.onNext,
    required this.onPrevious,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _MobileAppBar(
        serviceName: state.serviceName,
        currentStep: state.currentStep,
        onBack: onBack,
      ),
      body: state.isLoading && state.employees.isEmpty
          ? const _LoadingView()
          : Column(
              children: [
                Container(
                  color: AppColors.surface,
                  child: StepIndicator(
                    currentStep: state.currentStep,
                    totalSteps: 2,
                    labels: [
                      context.l10n.bookAppointment,
                      context.l10n.step3Title,
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: PageView(
                    controller: pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      _EmployeeAndTimeStep(),
                      BookingConfirmation(),
                    ],
                  ),
                ),
                _MobileBottomNavBar(
                  state: state,
                  onNext: onNext,
                  onBack: onPrevious,
                  onConfirm: onConfirm,
                ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Combined step 0: Employee + Time Slots
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
    final state = ref.read(bookingProvider);
    if (state.selectedDate == null && state.availableSlots.isNotEmpty) {
      final firstDate = state.availableSlots.first.dateTime;
      ref.read(bookingProvider.notifier).selectDate(
            DateTime(firstDate.year, firstDate.month, firstDate.day),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hideEmployeeBlock = ref.watch(
      bookingProvider.select((s) =>
          s.bookingMode == 'capacity_based' || s.employeeLocked),
    );

    return Column(
      children: [
        if (!hideEmployeeBlock) ...[
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
        ],
        const Expanded(child: TimeSlotSelection()),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// AppBar
// ---------------------------------------------------------------------------

class _MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? serviceName;
  final int currentStep;
  final VoidCallback onBack;

  const _MobileAppBar({
    required this.serviceName,
    required this.currentStep,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ÉTAPE ${currentStep + 1}/2',
            style: AppTextStyles.overline.copyWith(
              color: AppColors.textHint,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            context.l10n.bookingAppBarTitle,
            style: AppTextStyles.h3,
          ),
        ],
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: AppColors.textPrimary,
          ),
          onPressed: onBack,
          tooltip: context.l10n.back,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom navigation bar
// ---------------------------------------------------------------------------

class _MobileBottomNavBar extends StatelessWidget {
  final BookingState state;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  const _MobileBottomNavBar({
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
          if (state.currentStep > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: SizedBox(
                height: 52,
                width: 52,
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
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
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _canProceed && !state.isLoading
                    ? (isLastStep ? onConfirm : onNext)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.background,
                  disabledBackgroundColor: AppColors.border,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.background,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastStep
                                ? context.l10n.confirmBooking.toUpperCase()
                                : context.l10n.continueLabel.toUpperCase(),
                            style: AppTextStyles.button
                                .copyWith(color: AppColors.background),
                          ),
                          if (!isLastStep) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
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
// Loading view — skeleton employés pour le premier chargement
// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(top: AppSpacing.md),
        child: SkeletonBookingEmployees(),
      ),
    );
  }
}
