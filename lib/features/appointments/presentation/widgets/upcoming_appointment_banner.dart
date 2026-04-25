import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/models/appointment_model.dart';
import '../providers/appointments_provider.dart';

/// Displays a reminder banner when an upcoming appointment starts within 3h.
///
/// The banner:
///  - Watches [appointmentsProvider] for the closest upcoming appointment.
///  - Uses [minutesUntilStart] from the API *or* computes it locally if null.
///  - Refreshes every minute via an internal timer so the countdown stays live.
///  - Animates in with a slide-up + fade (300ms) on first render.
///  - Taps navigate to the appointments screen.
class UpcomingAppointmentBanner extends ConsumerStatefulWidget {
  const UpcomingAppointmentBanner({super.key});

  @override
  ConsumerState<UpcomingAppointmentBanner> createState() =>
      _UpcomingAppointmentBannerState();
}

class _UpcomingAppointmentBannerState
    extends ConsumerState<UpcomingAppointmentBanner>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    // Trigger animation on first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animController.forward();
    });

    // Refresh countdown every minute.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  /// Returns the nearest appointment starting within the next 3 hours,
  /// or null if none exists.
  AppointmentModel? _nearestAppointment(List<AppointmentModel> upcoming) {
    final now = DateTime.now();
    final cutoff = now.add(const Duration(hours: 3));

    AppointmentModel? nearest;
    for (final a in upcoming) {
      if (a.dateTime.isAfter(now) && a.dateTime.isBefore(cutoff)) {
        if (nearest == null || a.dateTime.isBefore(nearest.dateTime)) {
          nearest = a;
        }
      }
    }
    return nearest;
  }

  int _minutesUntil(AppointmentModel a) {
    if (a.minutesUntilStart != null) return a.minutesUntilStart!;
    return a.dateTime.difference(DateTime.now()).inMinutes;
  }

  String _formatDuration(BuildContext context, int minutes) {
    if (minutes <= 0) return context.l10n.upcomingReminderNow;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) {
      return context.l10n.inXHoursYMinutes(h, m);
    } else if (h > 0) {
      return context.l10n.inXHoursYMinutes(h, 0);
    } else {
      return context.l10n.inXHoursYMinutes(0, m);
    }
  }

  @override
  Widget build(BuildContext context) {
    final upcoming =
        ref.watch(appointmentsProvider.select((s) => s.upcoming));
    final appt = _nearestAppointment(upcoming);

    if (appt == null) return const SizedBox.shrink();

    final mins = _minutesUntil(appt);
    if (mins < 0) return const SizedBox.shrink();

    final durationStr = _formatDuration(context, mins);

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: GestureDetector(
          onTap: () => context.pushNamed(RouteNames.appointments),
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.secondary,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Clock icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    size: 22,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.upcomingReminderTitle,
                        style: GoogleFonts.fraunces(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.upcomingReminderBody(
                          appt.companyName,
                          durationStr,
                        ),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.secondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
