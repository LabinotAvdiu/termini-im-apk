import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../reviews/presentation/screens/submit_review_screen.dart'
    show showSubmitReviewDialog;
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';
import '../../data/models/appointment_model.dart';
import '../providers/appointments_provider.dart';
import '../widgets/cancel_appointment_dialog.dart';
import '../widgets/upcoming_appointment_banner.dart';

// ---------------------------------------------------------------------------
// Desktop appointments screen — editorial 2-col layout, max-width 1180px
// ---------------------------------------------------------------------------

class AppointmentsScreenDesktop extends ConsumerStatefulWidget {
  const AppointmentsScreenDesktop({super.key});

  @override
  ConsumerState<AppointmentsScreenDesktop> createState() =>
      _AppointmentsScreenDesktopState();
}

class _AppointmentsScreenDesktopState
    extends ConsumerState<AppointmentsScreenDesktop> {
  /// Past section is collapsed by default to the first `_pastPageSize`
  /// entries — the owner rarely needs the full history on the first load.
  /// Tap "Voir plus" to reveal the rest.
  bool _pastExpanded = false;
  static const int _pastPageSize = 6;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: state.isLoading && state.appointments.isEmpty
          ? _DesktopSkeletonView()
          : state.error != null && state.appointments.isEmpty
              ? _DesktopErrorState(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(appointmentsProvider.notifier).refresh(),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: () =>
                      ref.read(appointmentsProvider.notifier).refresh(),
                  child: _DesktopContent(
                    state: state,
                    pastExpanded: _pastExpanded,
                    pastPageSize: _pastPageSize,
                    onExpandPast: () => setState(() => _pastExpanded = true),
                  ),
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop main content — constrained + padded
// ---------------------------------------------------------------------------

class _DesktopContent extends StatelessWidget {
  final AppointmentsState state;
  final bool pastExpanded;
  final int pastPageSize;
  final VoidCallback onExpandPast;

  const _DesktopContent({
    required this.state,
    required this.pastExpanded,
    required this.pastPageSize,
    required this.onExpandPast,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    // Generous horizontal padding on very wide screens (≥1440)
    final hPad = screenW >= 1440 ? 120.0 : 48.0;

    final pastFull = state.past;
    final pastVisible = pastExpanded || pastFull.length <= pastPageSize
        ? pastFull
        : pastFull.take(pastPageSize).toList();
    final hiddenPast = pastFull.length - pastVisible.length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(hPad, 48, hPad, AppSpacing.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero header éditorial ────────────────────────────────────
              _DesktopHeroHeader(totalCount: state.appointments.length),

              const SizedBox(height: AppSpacing.xl),

              // ── Reminder banner ──────────────────────────────────────────
              const UpcomingAppointmentBanner(),
              if (state.upcoming.isNotEmpty)
                const SizedBox(height: AppSpacing.md),

              // ── Upcoming section ────────────────────────────────────────
              _DesktopSectionHeader(
                label: context.l10n.upcoming.toUpperCase(),
                count: state.upcoming.length,
              ),
              const SizedBox(height: AppSpacing.md),
              _DesktopGrid(
                appointments: state.upcoming,
                isUpcoming: true,
                emptyMessage: context.l10n.noUpcomingAppointments,
                emptyIcon: Icons.calendar_today_rounded,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Past section ─────────────────────────────────────────────
              _DesktopSectionHeader(
                label: context.l10n.past.toUpperCase(),
                count: pastFull.length,
              ),
              const SizedBox(height: AppSpacing.md),
              _DesktopGrid(
                appointments: pastVisible,
                isUpcoming: false,
                emptyMessage: context.l10n.noPastAppointments,
                emptyIcon: Icons.event_busy_rounded,
              ),

              if (hiddenPast > 0) ...[
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: _SeeMoreButton(
                    label: context.l10n.seeMorePastAppointments(hiddenPast),
                    onPressed: onExpandPast,
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
// Editorial section header — overline + thin burgundy rule + count chip
// ---------------------------------------------------------------------------

class _DesktopSectionHeader extends StatelessWidget {
  final String label;
  final int count;

  const _DesktopSectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.fraunces(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.4,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.fraunces(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.divider,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "See more" ghost button — editorial gold outline
// ---------------------------------------------------------------------------

class _SeeMoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SeeMoreButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.5)),
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.instrumentSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_downward_rounded, size: 14),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero header
// ---------------------------------------------------------------------------

class _DesktopHeroHeader extends StatelessWidget {
  final int totalCount;

  const _DesktopHeroHeader({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overline
        Text(
          context.l10n.appointmentsDesktopOverline,
          style: GoogleFonts.instrumentSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(height: 8),
        // Display title
        Text(
          context.l10n.appointmentsDesktopTitle,
          style: GoogleFonts.fraunces(
            fontSize: 48,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            letterSpacing: -1.2,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        // Subtitle — count
        if (totalCount > 0)
          Text(
            '$totalCount ${totalCount == 1 ? context.l10n.myAppointments : context.l10n.myAppointments}',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textHint,
              fontSize: 15,
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Segmented tab row (pills with or underline)
// ---------------------------------------------------------------------------

// Tab row removed — the desktop view now shows Upcoming + Past stacked,
// with Past capped to 6 entries via a "See more" button.

// ---------------------------------------------------------------------------
// 2-column grid of appointment cards
// ---------------------------------------------------------------------------

class _DesktopGrid extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final bool isUpcoming;
  final String emptyMessage;
  final IconData emptyIcon;

  const _DesktopGrid({
    required this.appointments,
    required this.isUpcoming,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return _DesktopEmptyState(
        message: emptyMessage,
        icon: emptyIcon,
        isUpcoming: isUpcoming,
      );
    }

    // 2-column grid using Wrap for simplicity and flexibility
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 24) / 2;
        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: appointments.map((a) {
            return SizedBox(
              width: cardWidth,
              child: _DesktopAppointmentCard(
                appointment: a,
                isUpcoming: isUpcoming,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop appointment card — horizontal photo + info layout
// ---------------------------------------------------------------------------

class _DesktopAppointmentCard extends ConsumerWidget {
  final AppointmentModel appointment;
  final bool isUpcoming;

  const _DesktopAppointmentCard({
    required this.appointment,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opacity = isUpcoming ? 1.0 : 0.55;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUpcoming
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: isUpcoming
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.cardShadow,
            blurRadius: isUpcoming ? 20 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: photo + info ────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Photo 120×120
                SizedBox(
                  width: 120,
                  height: 120,
                  child: appointment.companyPhotoUrl != null &&
                          appointment.companyPhotoUrl!.isNotEmpty
                      ? Opacity(
                          opacity: isUpcoming ? 1.0 : 0.5,
                          child: CachedNetworkImage(
                            imageUrl: appointment.companyPhotoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => _PhotoPlaceholder(),
                            errorWidget: (_, _, _) => _PhotoPlaceholder(),
                          ),
                        )
                      : _PhotoPlaceholder(),
                ),

                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company name + status badge in top row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.pushNamed(
                                  RouteNames.companyDetail,
                                  pathParameters: {
                                    'id': appointment.companyId
                                  },
                                ),
                                child: Text(
                                  appointment.companyName,
                                  style: GoogleFonts.fraunces(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w400,
                                    color: isUpcoming
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    letterSpacing: -0.2,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _DesktopStatusBadge(status: appointment.status),
                          ],
                        ),

                        // Address
                        if (appointment.companyAddress != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 12,
                                  color: AppColors.textHint
                                      .withValues(alpha: opacity)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  appointment.companyAddress!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textHint
                                        .withValues(alpha: opacity),
                                    letterSpacing: 0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const Spacer(),

                        // Service + price
                        Row(
                          children: [
                            Icon(Icons.content_cut_rounded,
                                size: 12,
                                color: isUpcoming
                                    ? AppColors.primary
                                    : AppColors.textHint),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                appointment.serviceName,
                                style: AppTextStyles.bodySmall.copyWith(
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
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isUpcoming
                                    ? AppColors.primary
                                    : AppColors.textHint,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        // Employee
                        if (appointment.employeeName != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded,
                                  size: 12,
                                  color: isUpcoming
                                      ? AppColors.primary
                                      : AppColors.textHint),
                              const SizedBox(width: 4),
                              Text(
                                appointment.employeeName!,
                                style: AppTextStyles.caption.copyWith(
                                  color: isUpcoming
                                      ? AppColors.textSecondary
                                      : AppColors.textHint,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Date/time strip ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isUpcoming
                  ? AppColors.primary.withValues(alpha: 0.07)
                  : AppColors.background,
              border: Border(
                top: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: isUpcoming ? AppColors.primary : AppColors.textHint,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDay(context, appointment.dateTime),
                  style: AppTextStyles.bodySmall.copyWith(
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
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: isUpcoming ? AppColors.primary : AppColors.textHint,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),

          // ── Actions ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isUpcoming)
                  _DesktopCancelSection(appointment: appointment),
                if (!isUpcoming)
                  _DesktopReviewSection(appointment: appointment),
                if (appointment.status == 'no_show') ...[
                  const SizedBox(height: AppSpacing.xs),
                  _DesktopNoShowExplanation(),
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
    final dayNames = [
      l.monday, l.tuesday, l.wednesday, l.thursday,
      l.friday, l.saturday, l.sunday,
    ];
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

class _PhotoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.07),
      child: const Center(
        child: Icon(Icons.storefront_rounded,
            size: 28, color: AppColors.primary),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop status badge
// ---------------------------------------------------------------------------

class _DesktopStatusBadge extends StatelessWidget {
  final String status;

  const _DesktopStatusBadge({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.20), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: fg,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop cancel section
// ---------------------------------------------------------------------------

class _DesktopCancelSection extends ConsumerWidget {
  final AppointmentModel appointment;

  const _DesktopCancelSection({required this.appointment});

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
        icon: const Icon(Icons.cancel_outlined, size: 14),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.textHint.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.textHint.withValues(alpha: 0.2)),
        ),
        child: Text(
          context.l10n.cancellableUntil(_formatCancelsAt(a.cancelsBeforeAt!)),
          style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
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
// Desktop review section
// ---------------------------------------------------------------------------

class _DesktopReviewSection extends ConsumerWidget {
  final AppointmentModel appointment;

  const _DesktopReviewSection({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = appointment;

    if (a.review != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 12, color: AppColors.secondary),
            const SizedBox(width: 4),
            Text(
              context.l10n.reviewBadge(a.review!.rating),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondaryDark,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
      ),
      icon: const Icon(Icons.star_outline_rounded, size: 14),
      label: Text(
        context.l10n.reviewSubmitTitle,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.secondaryDark,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      // Desktop: open compact dialog instead of pushing the route.
      onPressed: () => showSubmitReviewDialog(
        context,
        appointmentId: a.id,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop no-show explanation
// ---------------------------------------------------------------------------

class _DesktopNoShowExplanation extends StatelessWidget {
  const _DesktopNoShowExplanation();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.textHint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              context.l10n.appointmentNoShowDetail,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop empty state — minimal illustration + serif title
// ---------------------------------------------------------------------------

class _DesktopEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool isUpcoming;

  const _DesktopEmptyState({
    required this.message,
    required this.icon,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Minimal circle illustration
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isUpcoming ? AppColors.primary : AppColors.textHint)
                    .withValues(alpha: 0.07),
              ),
              child: Icon(
                icon,
                size: 40,
                color: (isUpcoming ? AppColors.primary : AppColors.textHint)
                    .withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              message,
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop skeleton view — 2-col grid of cards
// ---------------------------------------------------------------------------

class _DesktopSkeletonView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(80, 48, 80, AppSpacing.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero header skeleton
              const SkeletonBox(w: 100, h: 12, radius: BorderRadius.all(Radius.circular(4))),
              const SizedBox(height: 10),
              const SkeletonBox(w: 280, h: 48, radius: BorderRadius.all(Radius.circular(8))),
              const SizedBox(height: 12),
              const SkeletonText(width: 120),
              const SizedBox(height: AppSpacing.xl),
              // Tab row skeleton
              Row(
                children: const [
                  SkeletonBox(w: 100, h: 36, radius: BorderRadius.all(Radius.circular(12))),
                  SizedBox(width: AppSpacing.sm),
                  SkeletonBox(w: 80, h: 36, radius: BorderRadius.all(Radius.circular(12))),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // 2-col grid of skeleton cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardW = (constraints.maxWidth - 24) / 2;
                  return Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: List.generate(
                      4,
                      (_) => SizedBox(
                        width: cardW,
                        child: const _SkeletonDesktopAppointmentCard(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonDesktopAppointmentCard extends StatelessWidget {
  const _SkeletonDesktopAppointmentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                SkeletonBox(
                  w: 120,
                  h: 120,
                  radius: BorderRadius.zero,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonText(),
                        SizedBox(height: 6),
                        SkeletonText(width: 100),
                        SizedBox(height: AppSpacing.sm),
                        SkeletonText(width: 140),
                        SizedBox(height: 4),
                        SkeletonText(width: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: const [
                SkeletonText(width: 120),
                Spacer(),
                SkeletonBox(w: 48, h: 24, radius: BorderRadius.all(Radius.circular(6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop error state
// ---------------------------------------------------------------------------

class _DesktopErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DesktopErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
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
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.primary),
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
