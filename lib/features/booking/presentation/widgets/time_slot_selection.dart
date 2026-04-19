import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/ux_prefs_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';
import '../../data/models/available_slot_model.dart';
import '../../data/models/day_availability_model.dart';
import '../providers/booking_provider.dart';

String _shortDayName(BuildContext context, DateTime date) {
  final l = context.l10n;
  switch (date.weekday) {
    case DateTime.monday:
      return l.dayShortMon;
    case DateTime.tuesday:
      return l.dayShortTue;
    case DateTime.wednesday:
      return l.dayShortWed;
    case DateTime.thursday:
      return l.dayShortThu;
    case DateTime.friday:
      return l.dayShortFri;
    case DateTime.saturday:
      return l.dayShortSat;
    case DateTime.sunday:
    default:
      return l.dayShortSun;
  }
}

class TimeSlotSelection extends ConsumerWidget {
  const TimeSlotSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingProvider);

    if (state.isLoading && state.availability.isEmpty) {
      return const SkeletonTimeSlots();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: state.availability.length,
            itemBuilder: (context, index) {
              final day = state.availability[index];
              final dateObj = DateTime.tryParse(day.date);
              final isSelected = state.selectedDate != null &&
                  dateObj != null &&
                  state.selectedDate!.year == dateObj.year &&
                  state.selectedDate!.month == dateObj.month &&
                  state.selectedDate!.day == dateObj.day;

              return _DateChip(
                day: day,
                isSelected: isSelected,
                onTap: day.isAvailable && dateObj != null
                    ? () {
                        ref.read(uxPrefsProvider.notifier).selectionClick();
                        ref
                            .read(bookingProvider.notifier)
                            .selectDate(dateObj);
                      }
                    : null,
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        Expanded(
          child: state.selectedDate == null
              ? const _SelectDateHint()
              : state.isLoadingSlots
                  ? const SkeletonTimeSlots()
                  : _SlotsForDay(
                      slots: state.availableSlots,
                      selectedSlot: state.selectedSlot,
                      onSlotTap: (slot) {
                        ref.read(uxPrefsProvider.notifier).selectionClick();
                        ref.read(bookingProvider.notifier).selectSlot(slot);
                      },
                    ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Date chip
// ---------------------------------------------------------------------------

class _DateChip extends StatelessWidget {
  final DayAvailability day;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DateChip({
    required this.day,
    required this.isSelected,
    this.onTap,
  });

  String _statusLabel(BuildContext context) {
    switch (day.status) {
      case 'closed':
        return context.l10n.closed;
      case 'day_off':
        return context.l10n.slotStatusDayOff;
      case 'not_working':
        return context.l10n.slotStatusNotWorking;
      case 'full':
        return context.l10n.slotStatusFull;
      default:
        return '${day.slotsCount ?? 0}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = day.isDisabled;
    final dateObj = DateTime.tryParse(day.date);
    final dayNum = dateObj?.day.toString() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 62,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.textPrimary
              : disabled
                  ? AppColors.background
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.textPrimary
                : disabled
                    ? AppColors.divider
                    : AppColors.border,
            width: 1,
          ),
        ),
        child: Opacity(
          opacity: disabled ? 0.35 : 1.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dateObj != null
                    ? _shortDayName(context, dateObj).toUpperCase()
                    : day.dayName,
                style: AppTextStyles.overline.copyWith(
                  color: isSelected
                      ? AppColors.background.withValues(alpha: 0.7)
                      : AppColors.textHint,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dayNum,
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: isSelected ? AppColors.background : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _statusLabel(context),
                style: AppTextStyles.overline.copyWith(
                  fontSize: 9,
                  color: isSelected
                      ? AppColors.secondary
                      : disabled
                          ? AppColors.error.withValues(alpha: 0.6)
                          : AppColors.success,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slot grid for a specific day
// ---------------------------------------------------------------------------

class _SlotsForDay extends StatelessWidget {
  final List<AvailableSlotModel> slots;
  final AvailableSlotModel? selectedSlot;
  final void Function(AvailableSlotModel) onSlotTap;

  const _SlotsForDay({
    required this.slots,
    required this.selectedSlot,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const _NoSlotsMessage();
    }

    final morning = slots.where((s) => s.dateTime.hour < 12).toList();
    final afternoon = slots.where((s) => s.dateTime.hour >= 12).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (morning.isNotEmpty) ...[
            _SlotSectionHeader(label: context.l10n.morning),
            const SizedBox(height: AppSpacing.sm),
            _SlotGrid(
              slots: morning,
              selectedSlot: selectedSlot,
              onSlotTap: onSlotTap,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (afternoon.isNotEmpty) ...[
            _SlotSectionHeader(label: context.l10n.afternoon),
            const SizedBox(height: AppSpacing.sm),
            _SlotGrid(
              slots: afternoon,
              selectedSlot: selectedSlot,
              onSlotTap: onSlotTap,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _SlotSectionHeader extends StatelessWidget {
  final String label;

  const _SlotSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.instrumentSerif(
        fontSize: 15,
        fontStyle: FontStyle.italic,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _SlotGrid extends StatelessWidget {
  final List<AvailableSlotModel> slots;
  final AvailableSlotModel? selectedSlot;
  final void Function(AvailableSlotModel) onSlotTap;

  const _SlotGrid({
    required this.slots,
    required this.selectedSlot,
    required this.onSlotTap,
  });

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool _isSelected(AvailableSlotModel slot) {
    if (selectedSlot == null) return false;
    return slot.dateTime == selectedSlot!.dateTime;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: slots.map((slot) {
        final selected = _isSelected(slot);
        final hasCapacity = slot.remaining != null;
        final isLow = hasCapacity && slot.remaining! <= 2;

        return GestureDetector(
          onTap: () => onSlotTap(slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            constraints: const BoxConstraints(
              minWidth: 72,
              minHeight: 40,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.textPrimary : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: selected
                    ? AppColors.textPrimary
                    : isLow
                        ? AppColors.secondary.withValues(alpha: 0.6)
                        : AppColors.border,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(slot.dateTime),
                  style: GoogleFonts.fraunces(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: selected ? AppColors.background : AppColors.textPrimary,
                  ),
                ),
                if (hasCapacity) ...[
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.spotsRemaining(slot.remaining!),
                    style: AppTextStyles.overline.copyWith(
                      fontSize: 9,
                      color: selected
                          ? AppColors.secondary
                          : isLow
                              ? AppColors.secondary
                              : AppColors.textHint,
                      letterSpacing: 0.3,
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

class _SelectDateHint extends StatelessWidget {
  const _SelectDateHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        context.l10n.selectDateHint,
        style: AppTextStyles.bodySmall,
      ),
    );
  }
}

class _NoSlotsMessage extends StatelessWidget {
  const _NoSlotsMessage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_rounded,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.noSlotsAvailable,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
