import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../employee_schedule/data/models/schedule_models.dart';
import '../../../employee_schedule/presentation/providers/schedule_provider.dart';

/// Banner shown at the top of the unified planning screen in employee_based
/// mode — one employee = one timeline → surfacing "who's next" is useful.
/// Hidden in capacity mode where multiple bookings can overlap and "next"
/// is ambiguous.
///
/// Tap → bottom sheet with phone + tap-to-call. Small by default, becomes
/// "compact" with a date badge when the next booking is on a different day.
class NextAppointmentBanner extends ConsumerWidget {
  /// The currently viewed date on the planning (YYYY-MM-DD). Used to decide
  /// whether the banner should render in compact mode (not on viewed day).
  final String viewedDate;

  const NextAppointmentBanner({super.key, required this.viewedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(upcomingAppointmentProvider);
    final appt = async.valueOrNull;
    if (appt == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final todayIso =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final onViewedDay = appt.date == viewedDate;
    final isOnToday = appt.date == todayIso;
    final compact = !onViewedDay;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: _NextAppointmentCard(
        appointment: appt,
        compact: compact,
        isToday: isOnToday,
      ),
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  final ScheduleAppointment appointment;
  final bool compact;
  final bool isToday;

  const _NextAppointmentCard({
    required this.appointment,
    required this.compact,
    required this.isToday,
  });

  String _formatDateBadge(BuildContext context) {
    final l = context.l10n;
    final now = DateTime.now();
    final date = DateTime.tryParse(appointment.date ?? '');
    if (date == null) return '';
    if (isToday) return l.todayLabel;
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return l.tomorrowLabel;
    }
    final months = [
      l.monthShortJan, l.monthShortFeb, l.monthShortMar, l.monthShortApr,
      l.monthShortMay, l.monthShortJun, l.monthShortJul, l.monthShortAug,
      l.monthShortSep, l.monthShortOct, l.monthShortNov, l.monthShortDec,
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(
        compact ? AppSpacing.radiusMd : AppSpacing.radiusLg,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openSheet(context),
        child: compact ? _buildCompact(context) : _buildFull(context),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _NextAppointmentDetailSheet(
        appointment: appointment,
        dateBadge: _formatDateBadge(context),
        isToday: isToday,
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final dateBadge = _formatDateBadge(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_available_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
                children: [
                  TextSpan(
                    text: '${context.l10n.nextAppointment} · ',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                      letterSpacing: 0.2,
                    ),
                  ),
                  TextSpan(
                    text: appointment.clientFullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              dateBadge,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            appointment.startTime,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.nextAppointment,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appointment.clientFullName,
                  style: AppTextStyles.subtitle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appointment.serviceName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              appointment.startTime,
              style: AppTextStyles.subtitle.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet opened when the owner taps the banner — phone quick-dial
/// + context (client, service, time).
class _NextAppointmentDetailSheet extends StatelessWidget {
  final ScheduleAppointment appointment;
  final String dateBadge;
  final bool isToday;

  const _NextAppointmentDetailSheet({
    required this.appointment,
    required this.dateBadge,
    required this.isToday,
  });

  Future<void> _dial(BuildContext context, String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleaned');
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(phone)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hasPhone = appointment.clientPhone != null &&
        appointment.clientPhone!.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.nextAppointment,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textHint),
                      ),
                      Row(
                        children: [
                          Text(
                            appointment.startTime,
                            style: AppTextStyles.h3,
                          ),
                          const SizedBox(width: 8),
                          if (dateBadge.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                dateBadge,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.person_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    appointment.clientFullName.isEmpty
                        ? '—'
                        : appointment.clientFullName,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.content_cut_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${appointment.serviceName}  •  ${appointment.durationMinutes} min  •  ${appointment.price.toStringAsFixed(0)} €',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (hasPhone)
              InkWell(
                onTap: () => _dial(context, appointment.clientPhone!),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          appointment.clientPhone!,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 15,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.phone_forwarded_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_disabled_rounded,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l.noPhoneAvailable,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
