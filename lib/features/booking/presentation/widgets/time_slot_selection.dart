import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
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
        // Date picker with availability
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
                    ? () =>
                        ref.read(bookingProvider.notifier).selectDate(dateObj)
                    : null,
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Slots for selected date
        Expanded(
          child: state.selectedDate == null
              ? const _SelectDateHint()
              : state.isLoadingSlots
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _SlotsForDay(
                      slots: state.availableSlots,
                      selectedSlot: state.selectedSlot,
                      onSlotTap: (slot) =>
                          ref.read(bookingProvider.notifier).selectSlot(slot),
                    ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Date chip with availability status
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
              ? AppColors.primary
              : disabled
                  ? AppColors.background
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : disabled
                    ? AppColors.divider
                    : AppColors.border,
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dateObj != null ? _shortDayName(context, dateObj) : day.dayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white70
                    : disabled
                        ? AppColors.textHint
                        : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dayNum,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : disabled
                        ? AppColors.textHint
                        : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _statusLabel(context),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white70
                    : disabled
                        ? AppColors.error.withValues(alpha: 0.6)
                        : AppColors.success,
              ),
            ),
          ],
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
            _SlotSectionHeader(
              icon: Icons.wb_sunny_outlined,
              label: context.l10n.morning,
            ),
            const SizedBox(height: AppSpacing.sm),
            _SlotGrid(
              slots: morning,
              selectedSlot: selectedSlot,
              onSlotTap: onSlotTap,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (afternoon.isNotEmpty) ...[
            _SlotSectionHeader(
              icon: Icons.wb_twilight_rounded,
              label: context.l10n.afternoon,
            ),
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
  final IconData icon;
  final String label;

  const _SlotSectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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
            padding: EdgeInsets.symmetric(
              horizontal: hasCapacity ? AppSpacing.sm : 0,
              vertical: hasCapacity ? AppSpacing.xs : 0,
            ),
            constraints: const BoxConstraints(
              minWidth: 72,
              minHeight: 40,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.slotSelected
                  : AppColors.slotAvailable,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: isLow && !selected
                  ? Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                      width: 1,
                    )
                  : null,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(slot.dateTime),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.primary,
                  ),
                ),
                if (hasCapacity) ...[
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.spotsRemaining(slot.remaining!),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.85)
                          : isLow
                              ? const Color(0xFFF59E0B)
                              : AppColors.textSecondary,
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
            const Icon(Icons.event_busy_rounded,
                size: 48, color: AppColors.textHint),
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
