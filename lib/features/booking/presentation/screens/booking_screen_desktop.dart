import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/models/available_slot_model.dart';
import '../../data/models/day_availability_model.dart';
import '../providers/booking_provider.dart';
import '../widgets/employee_selection.dart';
import '../widgets/booking_confirmation.dart';

/// Desktop (D5) editorial presentation for the booking flow.
///
/// Implements the 2-column split-screen layout:
/// - Left: step content (employee grid, time-slot calendar, confirmation)
/// - Right: sticky recap card in deep burgundy
///
/// Stateless — reads providers directly and forwards callbacks to [BookingScreen].
class BookingScreenDesktop extends ConsumerWidget {
  final String companyId;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onConfirm;

  const BookingScreenDesktop({
    super.key,
    required this.companyId,
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
      body: state.isLoading && state.employees.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _DesktopBody(
              state: state,
              onBack: onBack,
              onNext: onNext,
              onPrevious: onPrevious,
              onConfirm: onConfirm,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main body — constrains max width and splits columns
// ---------------------------------------------------------------------------

class _DesktopBody extends StatelessWidget {
  final BookingState state;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onConfirm;

  const _DesktopBody({
    required this.state,
    required this.onBack,
    required this.onNext,
    required this.onPrevious,
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
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          // Max 1100 px, centred with generous horizontal padding
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top nav bar ──────────────────────────────────────────────
                _DesktopTopBar(
                  currentStep: state.currentStep,
                  onBack: onBack,
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ── Split content ────────────────────────────────────────────
                // IntrinsicHeight was stripped: it tries to compute intrinsic
                // dimensions of the sidebar's Stack, which has no intrinsic
                // size and triggers "Cannot hit test a render box with no size".
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: step content
                    Expanded(
                      child: _StepContent(state: state),
                    ),

                    const SizedBox(width: AppSpacing.xl),

                    // Right: sticky recap card (380 px, matches D5 spec)
                    SizedBox(
                      width: 380,
                      child: _RecapSidebar(
                        state: state,
                        canProceed: _canProceed,
                        onNext: onNext,
                        onPrevious: onPrevious,
                        onConfirm: onConfirm,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top navigation bar (breadcrumb step indicator + back link)
// ---------------------------------------------------------------------------

class _DesktopTopBar extends StatelessWidget {
  final int currentStep;
  final VoidCallback onBack;

  const _DesktopTopBar({
    required this.currentStep,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Back button
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 13,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.back,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.lg),

        // Step breadcrumbs
        _StepBreadcrumb(
          label: '1 · ${context.l10n.bookAppointment}',
          isActive: currentStep == 0,
          isDone: currentStep > 0,
        ),
        _BreadcrumbChevron(),
        _StepBreadcrumb(
          label: '2 · ${context.l10n.step3Title}',
          isActive: currentStep == 1,
          isDone: false,
        ),
      ],
    );
  }
}

class _StepBreadcrumb extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepBreadcrumb({
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: isActive ? AppColors.textPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive
              ? AppColors.textPrimary
              : isDone
                  ? AppColors.textHint
                  : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.overline.copyWith(
          color: isActive
              ? AppColors.background
              : isDone
                  ? AppColors.textHint
                  : AppColors.textHint,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _BreadcrumbChevron extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 16,
        color: AppColors.textHint,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step content switcher — no PageView on desktop, just conditional rendering
// ---------------------------------------------------------------------------

class _StepContent extends StatelessWidget {
  final BookingState state;

  const _StepContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey<int>(state.currentStep),
        child: state.currentStep == 0
            ? _DesktopStepSlot(state: state)
            : _DesktopStepConfirm(state: state),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 0 — Employee + time-slot calendar
// ---------------------------------------------------------------------------

class _DesktopStepSlot extends StatelessWidget {
  final BookingState state;

  const _DesktopStepSlot({required this.state});

  @override
  Widget build(BuildContext context) {
    final isCapacityBased = state.bookingMode == 'capacity_based';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editorial hero title
        Text(
          context.l10n.bookAppointment,
          style: AppTextStyles.overline.copyWith(
            color: AppColors.textHint,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        RichText(
          text: TextSpan(
            style: GoogleFonts.fraunces(
              fontSize: 52,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              height: 1.0,
              letterSpacing: -1.5,
            ),
            children: [
              TextSpan(text: context.l10n.bookingDesktopChoose),
              TextSpan(
                text: context.l10n.bookingDesktopChooseEm,
                style: GoogleFonts.fraunces(
                  fontSize: 52,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primary,
                  height: 1.0,
                  letterSpacing: -1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Employee selection (only for employee_based mode)
        if (!isCapacityBased) ...[
          Text(
            context.l10n.hairdresser,
            style: AppTextStyles.caption.copyWith(
              letterSpacing: 1.8,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const EmployeeSelection(),
          const SizedBox(height: AppSpacing.xl),
        ],

        // Divider before date/slot section
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: AppSpacing.xl),

        // Date strip + slot grid combined
        _DesktopDateAndSlots(state: state),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop date strip + slot grid
// ---------------------------------------------------------------------------

class _DesktopDateAndSlots extends ConsumerWidget {
  final BookingState state;

  const _DesktopDateAndSlots({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.availability.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date grid
        _DesktopDateGrid(
          availability: state.availability,
          selectedDate: state.selectedDate,
          onDateSelected: (date) =>
              ref.read(bookingProvider.notifier).selectDate(date),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Slot section
        if (state.selectedDate != null) ...[
          _DesktopSlotSection(
            state: state,
            onSlotTap: (slot) =>
                ref.read(bookingProvider.notifier).selectSlot(slot),
          ),
        ] else ...[
          Text(
            context.l10n.selectDateHint,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Date grid — 7 columns (Mon–Sun)
// ---------------------------------------------------------------------------

class _DesktopDateGrid extends StatelessWidget {
  final List<DayAvailability> availability;
  final DateTime? selectedDate;
  final void Function(DateTime) onDateSelected;

  const _DesktopDateGrid({
    required this.availability,
    required this.selectedDate,
    required this.onDateSelected,
  });

  List<String> _dowLabels(BuildContext context) {
    final l = context.l10n;
    return [
      l.dayShortMon,
      l.dayShortTue,
      l.dayShortWed,
      l.dayShortThu,
      l.dayShortFri,
      l.dayShortSat,
      l.dayShortSun,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (availability.isEmpty) return const SizedBox.shrink();

    // Build a 7-column layout anchored on the first date's weekday
    final firstDate = DateTime.tryParse(availability.first.date);
    final leadingBlanks = firstDate != null ? firstDate.weekday - 1 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day-of-week headers
        Row(
          children: _dowLabels(context)
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d.toUpperCase(),
                      style: AppTextStyles.overline.copyWith(
                        color: AppColors.textHint,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Calendar grid using Wrap for simplicity while respecting weekday layout
        LayoutBuilder(
          builder: (context, constraints) {
            const columns = 7;
            final itemWidth =
                (constraints.maxWidth - (columns - 1) * AppSpacing.xs) /
                    columns;
            final allItems = [
              ...List.generate(leadingBlanks, (_) => null),
              ...availability,
            ];

            return Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: allItems.map((day) {
                if (day == null) {
                  return SizedBox(width: itemWidth);
                }
                final dateObj = DateTime.tryParse(day.date);
                final isSelected = selectedDate != null &&
                    dateObj != null &&
                    selectedDate!.year == dateObj.year &&
                    selectedDate!.month == dateObj.month &&
                    selectedDate!.day == dateObj.day;

                return _DesktopDayCell(
                  width: itemWidth,
                  day: day,
                  dateObj: dateObj,
                  isSelected: isSelected,
                  onTap: day.isAvailable && dateObj != null
                      ? () => onDateSelected(dateObj)
                      : null,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _DesktopDayCell extends StatelessWidget {
  final double width;
  final DayAvailability day;
  final DateTime? dateObj;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DesktopDayCell({
    required this.width,
    required this.day,
    required this.dateObj,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = day.isDisabled;
    final hasSlots = day.isAvailable;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.textPrimary
              : disabled
                  ? Colors.transparent
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.textPrimary
                : disabled
                    ? AppColors.divider
                    : AppColors.border,
          ),
        ),
        child: Opacity(
          opacity: disabled ? 0.3 : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dateObj?.day.toString() ?? '',
                style: GoogleFonts.fraunces(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color:
                      isSelected ? AppColors.background : AppColors.textPrimary,
                ),
              ),
              if (hasSlots && !isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slot section — shown below date grid when a date is selected
// ---------------------------------------------------------------------------

class _DesktopSlotSection extends StatelessWidget {
  final BookingState state;
  final void Function(AvailableSlotModel) onSlotTap;

  const _DesktopSlotSection({
    required this.state,
    required this.onSlotTap,
  });

  String _sectionTitle(BuildContext context) {
    if (state.selectedDate == null) return '';
    final l = context.l10n;
    final d = state.selectedDate!;
    final months = [
      l.monthJan, l.monthFeb, l.monthMar, l.monthApr,
      l.monthMay, l.monthJun, l.monthJul, l.monthAug,
      l.monthSep, l.monthOct, l.monthNov, l.monthDec,
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (state.availableSlots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Text(
          context.l10n.noSlotsAvailable,
          style: AppTextStyles.bodySmall,
        ),
      );
    }

    final morning =
        state.availableSlots.where((s) => s.dateTime.hour < 12).toList();
    final afternoon =
        state.availableSlots.where((s) => s.dateTime.hour >= 12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title — italic serif
        Text(
          _sectionTitle(context),
          style: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (morning.isNotEmpty) ...[
          _DesktopSlotGroupHeader(label: context.l10n.morning),
          const SizedBox(height: AppSpacing.sm),
          _DesktopSlotGrid(
            slots: morning,
            selectedSlot: state.selectedSlot,
            onSlotTap: onSlotTap,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (afternoon.isNotEmpty) ...[
          _DesktopSlotGroupHeader(label: context.l10n.afternoon),
          const SizedBox(height: AppSpacing.sm),
          _DesktopSlotGrid(
            slots: afternoon,
            selectedSlot: state.selectedSlot,
            onSlotTap: onSlotTap,
          ),
        ],
      ],
    );
  }
}

class _DesktopSlotGroupHeader extends StatelessWidget {
  final String label;

  const _DesktopSlotGroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.caption.copyWith(letterSpacing: 1.8),
    );
  }
}

class _DesktopSlotGrid extends StatelessWidget {
  final List<AvailableSlotModel> slots;
  final AvailableSlotModel? selectedSlot;
  final void Function(AvailableSlotModel) onSlotTap;

  const _DesktopSlotGrid({
    required this.slots,
    required this.selectedSlot,
    required this.onSlotTap,
  });

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: slots.map((slot) {
        final isSelected = selectedSlot?.dateTime == slot.dateTime;
        final hasCapacity = slot.remaining != null;
        final isLow = hasCapacity && slot.remaining! <= 2;

        return GestureDetector(
          onTap: () => onSlotTap(slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minWidth: 88),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.textPrimary : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected
                    ? AppColors.textPrimary
                    : isLow
                        ? AppColors.secondary.withValues(alpha: 0.6)
                        : AppColors.border,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(slot.dateTime),
                  style: GoogleFonts.fraunces(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: isSelected
                        ? AppColors.background
                        : AppColors.textPrimary,
                  ),
                ),
                if (hasCapacity) ...[
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.spotsRemaining(slot.remaining!),
                    style: AppTextStyles.overline.copyWith(
                      fontSize: 9,
                      color: isSelected
                          ? AppColors.secondary
                          : isLow
                              ? AppColors.secondary
                              : AppColors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Confirmation (reuses shared BookingConfirmation widget)
// ---------------------------------------------------------------------------

class _DesktopStepConfirm extends StatelessWidget {
  final BookingState state;

  const _DesktopStepConfirm({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.step3Title.toUpperCase(),
          style: AppTextStyles.overline.copyWith(
            color: AppColors.textHint,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        RichText(
          text: TextSpan(
            style: GoogleFonts.fraunces(
              fontSize: 52,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              height: 1.0,
              letterSpacing: -1.5,
            ),
            children: [
              TextSpan(text: context.l10n.bookingDesktopConfirm),
              TextSpan(
                text: context.l10n.bookingDesktopConfirmEm,
                style: GoogleFonts.fraunces(
                  fontSize: 52,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primary,
                  height: 1.0,
                  letterSpacing: -1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: AppSpacing.xl),
        // Reuse the shared confirmation widget — it reads bookingProvider directly
        const BookingConfirmation(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Right sidebar — sticky recap card in deep burgundy
// ---------------------------------------------------------------------------

class _RecapSidebar extends StatelessWidget {
  final BookingState state;
  final bool canProceed;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onConfirm;

  const _RecapSidebar({
    required this.state,
    required this.canProceed,
    required this.onNext,
    required this.onPrevious,
    required this.onConfirm,
  });

  String _formatDate(BuildContext context, DateTime dt) {
    final l = context.l10n;
    final months = [
      l.monthJan, l.monthFeb, l.monthMar, l.monthApr,
      l.monthMay, l.monthJun, l.monthJul, l.monthAug,
      l.monthSep, l.monthOct, l.monthNov, l.monthDec,
    ];
    final days = [
      l.monday, l.tuesday, l.wednesday, l.thursday,
      l.friday, l.saturday, l.sunday,
    ];
    return '${days[dt.weekday - 1].substring(0, 3)} ${dt.day} ${months[dt.month - 1]}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = state.currentStep == 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        // Decorative gold radial glow (matches D5 ::after pseudo-element)
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Decorative gold radial blob (top-right)
          Positioned(
            right: -80,
            top: 40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Actual content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overline
                Text(
                  context.l10n.summary.toUpperCase(),
                  style: AppTextStyles.overline.copyWith(
                    color: AppColors.secondary,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Service name — large serif
                Text(
                  state.serviceName ?? context.l10n.service,
                  style: GoogleFonts.fraunces(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFF7F2EA), // ivory
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),

                // ── Recap blocks ──────────────────────────────────────────────
                _RecapBlock(
                  label: context.l10n.hairdresser,
                  value: state.employeeDisplayName,
                ),

                if (state.selectedSlot != null) ...[
                  _RecapBlock(
                    label: context.l10n.dateLabel,
                    value: _formatDate(context, state.selectedSlot!.dateTime),
                    emphasis: _formatTime(state.selectedSlot!.dateTime),
                  ),
                  if (state.serviceDuration != null)
                    _RecapBlock(
                      label: context.l10n.duration,
                      value: '${state.serviceDuration}',
                      emphasis: ' min',
                    ),
                ],

                // ── Total ─────────────────────────────────────────────────────
                if (state.servicePrice != null && state.servicePrice! > 0) ...[
                  Container(
                    margin: const EdgeInsets.only(top: AppSpacing.xl),
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Color(0x1FF7F2EA), // ivory 12 %
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.price.toUpperCase(),
                          style: AppTextStyles.overline.copyWith(
                            color: const Color(0xB3F7F2EA), // ivory 70 %
                            letterSpacing: 1.8,
                          ),
                        ),
                        Text(
                          '${state.servicePrice!.toStringAsFixed(0)} €',
                          style: GoogleFonts.fraunces(
                            fontSize: 40,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondary,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // ── CTA button ────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: _DesktopCtaButton(
                    isLastStep: isLastStep,
                    isLoading: state.isLoading,
                    canProceed: canProceed,
                    onNext: onNext,
                    onConfirm: onConfirm,
                  ),
                ),

                // Back button (compact, shown after step 0)
                if (state.currentStep > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: onPrevious,
                      child: Text(
                        context.l10n.previous.toUpperCase(),
                        style: AppTextStyles.button.copyWith(
                          color: const Color(0x80F7F2EA), // ivory 50 %
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recap block — a labelled data row inside the sidebar
// ---------------------------------------------------------------------------

class _RecapBlock extends StatelessWidget {
  final String label;
  final String value;
  final String? emphasis; // gold-coloured suffix (e.g. time, " min")

  const _RecapBlock({
    required this.label,
    required this.value,
    this.emphasis,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.only(top: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0x1FF7F2EA), // ivory 12 %
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.overline.copyWith(
              color: const Color(0xB3F7F2EA), // ivory 70 %
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 6),
          emphasis == null
              ? Text(
                  value,
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFF7F2EA),
                    height: 1.2,
                  ),
                )
              : RichText(
                  text: TextSpan(
                    style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFF7F2EA),
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(text: value),
                      TextSpan(
                        text: emphasis,
                        style: GoogleFonts.fraunces(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          color: AppColors.secondary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CTA button — gold background, ink text
// ---------------------------------------------------------------------------

class _DesktopCtaButton extends StatelessWidget {
  final bool isLastStep;
  final bool isLoading;
  final bool canProceed;
  final VoidCallback onNext;
  final VoidCallback onConfirm;

  const _DesktopCtaButton({
    required this.isLastStep,
    required this.isLoading,
    required this.canProceed,
    required this.onNext,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final label = isLastStep
        ? context.l10n.confirmBooking.toUpperCase()
        : context.l10n.continueLabel.toUpperCase();

    return AnimatedOpacity(
      opacity: canProceed && !isLoading ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: canProceed && !isLoading
            ? (isLastStep ? onConfirm : onNext)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.textPrimary,
                ),
              )
            : Text(
                label,
                style: AppTextStyles.button.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 1.4,
                ),
              ),
      ),
    );
  }
}
