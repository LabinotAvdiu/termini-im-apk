import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';
import '../../data/models/appointment_model.dart';
import '../providers/appointments_provider.dart';
import '../widgets/cancel_appointment_dialog.dart';
import '../widgets/upcoming_appointment_banner.dart';

class AppointmentsScreenMobile extends ConsumerWidget {
  const AppointmentsScreenMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: state.isLoading && state.appointments.isEmpty
          ? _AppointmentsSkeletonView()
          : state.error != null && state.appointments.isEmpty
              ? _ErrorState(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(appointmentsProvider.notifier).refresh(),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: () =>
                      ref.read(appointmentsProvider.notifier).refresh(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    children: [
                      // Title
                      Text(
                        context.l10n.myAppointments,
                        style: AppTextStyles.h2,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Upcoming section ──────────────────────────
                      _SectionHeader(
                        icon: Icons.event_available_rounded,
                        label: context.l10n.upcoming,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Feature 2 — Reminder banner at top of list
                      const UpcomingAppointmentBanner(),
                      if (state.upcoming.isNotEmpty)
                        const SizedBox(height: AppSpacing.xs),

                      if (state.upcoming.isEmpty)
                        _EmptyCard(
                          message: context.l10n.noUpcomingAppointments,
                          icon: Icons.calendar_today_rounded,
                          color: AppColors.primary,
                        )
                      else
                        ...state.upcoming.map(
                          (a) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _AppointmentCard(
                              appointment: a,
                              isUpcoming: true,
                            ),
                          ),
                        ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Past section ──────────────────────────────
                      _SectionHeader(
                        icon: Icons.history_rounded,
                        label: context.l10n.past,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      if (state.past.isEmpty)
                        _EmptyCard(
                          message: context.l10n.noPastAppointments,
                          icon: Icons.event_busy_rounded,
                          color: AppColors.textHint,
                        )
                      else
                        ...state.past.map(
                          (a) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _AppointmentCard(
                              appointment: a,
                              isUpcoming: false,
                            ),
                          ),
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
// Skeleton view — affiché pendant le premier chargement
// ---------------------------------------------------------------------------

class _AppointmentsSkeletonView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        // Title
        const SkeletonBox(w: 200, h: 28, radius: BorderRadius.all(Radius.circular(6))),
        const SizedBox(height: AppSpacing.lg),

        // Section header
        Row(
          children: const [
            SkeletonBox(w: 14, h: 14),
            SizedBox(width: AppSpacing.xs),
            SkeletonText(width: 80),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // 2 upcoming cards
        const SkeletonAppointmentCard(),
        const SkeletonAppointmentCard(),

        const SizedBox(height: AppSpacing.lg),

        // Section header past
        Row(
          children: const [
            SkeletonBox(w: 14, h: 14),
            SizedBox(width: AppSpacing.xs),
            SkeletonText(width: 60),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // 1 past card
        const SkeletonAppointmentCard(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section header — editorial overline style
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.overline.copyWith(
            color: color,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Appointment card — different style for upcoming vs past
// ---------------------------------------------------------------------------

class _AppointmentCard extends ConsumerWidget {
  final AppointmentModel appointment;
  final bool isUpcoming;

  const _AppointmentCard({
    required this.appointment,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opacity = isUpcoming ? 1.0 : 0.6;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: isUpcoming
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: isUpcoming
                ? AppColors.primary.withValues(alpha: 0.10)
                : AppColors.cardShadow,
            blurRadius: isUpcoming ? 16 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Company photo banner ──────────────────────────────
          if (appointment.companyPhotoUrl != null &&
              appointment.companyPhotoUrl!.isNotEmpty)
            Opacity(
              opacity: isUpcoming ? 1.0 : 0.5,
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: appointment.companyPhotoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    child: const Center(
                      child: Icon(Icons.storefront_rounded,
                          size: 32, color: AppColors.primary),
                    ),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    child: const Center(
                      child: Icon(Icons.storefront_rounded,
                          size: 32, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Company name + status ────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.pushNamed(
                          RouteNames.companyDetail,
                          pathParameters: {'id': appointment.companyId},
                        ),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                appointment.companyName,
                                style: GoogleFonts.fraunces(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  color: isUpcoming
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  letterSpacing: -0.18,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: isUpcoming
                                  ? AppColors.primary
                                  : AppColors.textHint,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _StatusBadge(status: appointment.status),
                  ],
                ),

                // ── Address ──────────────────────────────────────
                if (appointment.companyAddress != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textHint
                              .withValues(alpha: opacity)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          appointment.companyAddress!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary
                                .withValues(alpha: opacity),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // ── Date & time — prominent ──────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm + 2,
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: isUpcoming
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.background,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: isUpcoming
                            ? AppColors.primary
                            : AppColors.textHint,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _formatDay(context, appointment.dateTime),
                        style: AppTextStyles.body.copyWith(
                          color: isUpcoming
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(appointment.dateTime),
                        style: GoogleFonts.fraunces(
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          color: isUpcoming
                              ? AppColors.primary
                              : AppColors.textHint,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Service + Employee + Price ────────────────────
                Row(
                  children: [
                    Icon(Icons.content_cut_rounded,
                        size: 14,
                        color: isUpcoming
                            ? AppColors.primary
                            : AppColors.textHint),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        appointment.serviceName,
                        style: AppTextStyles.body.copyWith(
                          color: isUpcoming
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${appointment.price.toStringAsFixed(appointment.price.truncateToDouble() == appointment.price ? 0 : 2)} €',
                      style: AppTextStyles.subtitle.copyWith(
                        color: isUpcoming
                            ? AppColors.primary
                            : AppColors.textHint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                if (appointment.employeeName != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 14,
                          color: isUpcoming
                              ? AppColors.primary
                              : AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        appointment.employeeName!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isUpcoming
                              ? AppColors.textSecondary
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Feature 1 : Cancel / cancellable-until info ──
                if (isUpcoming) ...[
                  const SizedBox(height: AppSpacing.md),
                  _CancelSection(appointment: appointment),
                ],

                // ── Feature 3 : Review CTA (past appointments) ───
                if (!isUpcoming) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ReviewSection(appointment: appointment),
                ],

                // ── No-show explanation ──────────────────────────
                if (appointment.status == 'no_show') ...[
                  const SizedBox(height: AppSpacing.sm),
                  _NoShowExplanation(),
                ],

                // ── Rejection reason (shown by the salon) ────────
                if (appointment.status == 'rejected' &&
                    (appointment.rejectionReason?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _RejectionReasonClient(reason: appointment.rejectionReason!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDay(BuildContext context, DateTime dt) {
    final l = context.l10n;
    final dayNames = [l.monday, l.tuesday, l.wednesday, l.thursday, l.friday, l.saturday, l.sunday];
    final monthNames = [
      l.monthJan, l.monthFeb, l.monthMar, l.monthApr,
      l.monthMay, l.monthJun, l.monthJul, l.monthAug,
      l.monthSep, l.monthOct, l.monthNov, l.monthDec,
    ];
    return '${dayNames[dt.weekday - 1]} ${dt.day} ${monthNames[dt.month - 1]}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// No-show explanation
// ---------------------------------------------------------------------------

class _NoShowExplanation extends StatelessWidget {
  const _NoShowExplanation();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.textHint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.appointmentNoShowDetail,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rejection reason shown to the client (salon's motive)
// ---------------------------------------------------------------------------

class _RejectionReasonClient extends StatelessWidget {
  final String reason;
  const _RejectionReasonClient({required this.reason});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 16,
            color: AppColors.primary.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.rejectionReasonClientLabel.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.45,
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
// Feature 1 — Cancel section on upcoming cards
// ---------------------------------------------------------------------------

class _CancelSection extends ConsumerWidget {
  final AppointmentModel appointment;

  const _CancelSection({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = appointment;
    if (a.status != 'confirmed' && a.status != 'pending') {
      return const SizedBox.shrink();
    }

    if (a.canCancel) {
      return TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.error,
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.cancel_outlined, size: 16),
        label: Text(
          context.l10n.cancelAppointment,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        ),
        onPressed: () =>
            CancelAppointmentDialog.show(context, ref, appointment),
      );
    }

    if (a.cancelsBeforeAt != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.textHint.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.textHint.withValues(alpha: 0.2)),
        ),
        child: Text(
          context.l10n.cancellableUntil(
            _formatCancelsAt(a.cancelsBeforeAt!),
          ),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textHint,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _formatCancelsAt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month} $h:$m';
  }
}

// ---------------------------------------------------------------------------
// Feature 3 — Review section on past cards
// ---------------------------------------------------------------------------

class _ReviewSection extends ConsumerWidget {
  final AppointmentModel appointment;

  const _ReviewSection({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = appointment;

    if (a.review != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded,
                size: 14, color: AppColors.secondary),
            const SizedBox(width: 4),
            Text(
              context.l10n.reviewBadge(a.review!.rating),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (!a.canReview) return const SizedBox.shrink();

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
        foregroundColor: AppColors.secondaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
      ),
      icon: const Icon(Icons.star_outline_rounded, size: 16),
      label: Text(
        context.l10n.reviewSubmitTitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.secondaryDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: () => context.pushNamed(
        RouteNames.submitReview,
        pathParameters: {'id': a.id},
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'confirmed' => (
          context.l10n.appointmentConfirmed,
          AppColors.primary.withValues(alpha: 0.10),
          AppColors.primary,
        ),
      'pending' => (
          context.l10n.appointmentPending,
          AppColors.secondary.withValues(alpha: 0.15),
          AppColors.secondaryDark,
        ),
      'completed' => (
          context.l10n.appointmentCompleted,
          AppColors.textHint.withValues(alpha: 0.12),
          AppColors.textSecondary,
        ),
      'cancelled' => (
          context.l10n.appointmentCancelled,
          AppColors.error.withValues(alpha: 0.10),
          AppColors.error,
        ),
      'rejected' => (
          context.l10n.appointmentRejected,
          AppColors.error.withValues(alpha: 0.10),
          AppColors.error,
        ),
      'no_show' => (
          context.l10n.appointmentNoShow,
          AppColors.error.withValues(alpha: 0.12),
          AppColors.error,
        ),
      _ => (
          status,
          AppColors.textHint.withValues(alpha: 0.12),
          AppColors.textSecondary,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.20), width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyles.overline.copyWith(
          color: fg,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty card for a section
// ---------------------------------------------------------------------------

class _EmptyCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _EmptyCard({
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color.withValues(alpha: 0.5)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.error, style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
