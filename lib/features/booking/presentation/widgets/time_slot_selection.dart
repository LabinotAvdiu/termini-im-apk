import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/available_slot_model.dart';
import '../providers/booking_provider.dart';

class TimeSlotSelection extends ConsumerWidget {
  const TimeSlotSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingProvider);

    // Distinct available dates
    final dates = _distinctDates(state.availableSlots);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal date picker
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = state.selectedDate != null &&
                  _isSameDay(state.selectedDate!, date);
              return _DateChip(
                date: date,
                isSelected: isSelected,
                onTap: () =>
                    ref.read(bookingProvider.notifier).selectDate(date),
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Time slots for selected date
        Expanded(
          child: state.selectedDate == null
              ? const _EmptyDateHint()
              : _SlotsForDay(
                  slots: ref
                      .read(bookingProvider.notifier)
                      .slotsForSelectedDate(),
                  selectedSlot: state.selectedSlot,
                  onSlotTap: (slot) =>
                      ref.read(bookingProvider.notifier).selectSlot(slot),
                ),
        ),
      ],
    );
  }

  List<DateTime> _distinctDates(List<AvailableSlotModel> slots) {
    final seen = <String>{};
    final result = <DateTime>[];
    for (final s in slots) {
      final key =
          '${s.dateTime.year}-${s.dateTime.month}-${s.dateTime.day}';
      if (seen.add(key)) {
        result.add(
            DateTime(s.dateTime.year, s.dateTime.month, s.dateTime.day));
      }
    }
    return result;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ---------------------------------------------------------------------------
// Date chip
// ---------------------------------------------------------------------------

class _DateChip extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateChip({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  static const _dayAbbreviations = [
    'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim',
  ];

  static const _monthAbbreviations = [
    'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
    'jul', 'aoû', 'sep', 'oct', 'nov', 'déc',
  ];

  @override
  Widget build(BuildContext context) {
    final dayName = _dayAbbreviations[date.weekday - 1];
    final monthAbbr = _monthAbbreviations[date.month - 1];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 58,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
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
              : [
                  const BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              monthAbbr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: isSelected ? Colors.white70 : AppColors.textHint,
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
              label: 'Matin',
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
              label: 'Après-midi',
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
        return GestureDetector(
          onTap: () => onSlotTap(slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 72,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  selected ? AppColors.slotSelected : AppColors.slotAvailable,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
            child: Text(
              _formatTime(slot.dateTime),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyDateHint extends StatelessWidget {
  const _EmptyDateHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Sélectionnez une date ci-dessus.',
        style: AppTextStyles.bodySmall,
      ),
    );
  }
}

class _NoSlotsMessage extends StatelessWidget {
  const _NoSlotsMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded,
                size: 48, color: AppColors.textHint),
            SizedBox(height: AppSpacing.md),
            Text(
              'Aucun créneau disponible\npour cette date.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
