import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/booking_provider.dart';

class BookingConfirmation extends ConsumerWidget {
  const BookingConfirmation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.summary, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.bookingConfirmationSubtitle,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Summary card
          _SummaryCard(state: state),

          const SizedBox(height: AppSpacing.lg),

          // Info note
          _InfoNote(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  final BookingState state;

  const _SummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header gradient band
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  context.l10n.yourAppointment,
                  style: AppTextStyles.subtitle.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.content_cut_rounded,
                  label: context.l10n.service,
                  value: state.serviceName ?? context.l10n.service,
                  subValue: state.servicePrice != null
                      ? '${state.servicePrice!.toStringAsFixed(2)} €'
                      : null,
                  subValueColor: AppColors.primary,
                ),
                const Divider(height: AppSpacing.lg),
                _SummaryRow(
                  icon: Icons.person_outline_rounded,
                  label: context.l10n.hairdresser,
                  value: state.employeeDisplayName,
                  subValue: state.noPreference
                      ? null
                      : state.selectedEmployee?.specialties.isNotEmpty == true
                          ? state.selectedEmployee!.specialties.first
                          : null,
                ),
                if (state.selectedSlot != null) ...[
                  const Divider(height: AppSpacing.lg),
                  _SummaryRow(
                    icon: Icons.event_rounded,
                    label: context.l10n.dateLabel,
                    value: _formatDate(context, state.selectedSlot!.dateTime),
                  ),
                  const Divider(height: AppSpacing.lg),
                  _SummaryRow(
                    icon: Icons.access_time_rounded,
                    label: context.l10n.timeLabel,
                    value: _formatTime(state.selectedSlot!.dateTime),
                    subValue: state.serviceDuration != null
                        ? '~${state.serviceDuration} min'
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

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
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final Color? subValueColor;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    this.subValueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.subtitle.copyWith(fontSize: 15),
              ),
              if (subValue != null)
                Text(
                  subValue!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: subValueColor ?? AppColors.textSecondary,
                    fontWeight: subValueColor != null
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Info note
// ---------------------------------------------------------------------------

class _InfoNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.info,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.reminderNote,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.info,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
