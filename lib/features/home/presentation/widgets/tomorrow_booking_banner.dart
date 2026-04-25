import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../appointments/data/models/appointment_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// C16 — Tomorrow Bookings Provider
// ---------------------------------------------------------------------------

/// Fetches confirmed appointments for tomorrow (local calendar).
/// Hits GET /bookings and filters client-side — no new endpoint needed
/// as the existing datasource already caches the full list.
///
/// Returns an empty list when the user is not authenticated, or when
/// there are no confirmed appointments scheduled for tomorrow.
final tomorrowBookingsProvider =
    FutureProvider<List<AppointmentModel>>((ref) async {
  final isAuth = ref.watch(
    authStateProvider.select((s) => s.isAuthenticated),
  );
  if (!isAuth) return const [];

  try {
    final client = ref.read(dioClientProvider);
    final response = await client.get(ApiConstants.bookings);

    final raw = response.data;
    final List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic> && raw['data'] is List) {
      list = raw['data'] as List<dynamic>;
    } else {
      return const [];
    }

    final appointments = list
        .cast<Map<String, dynamic>>()
        .map(AppointmentModel.fromJson)
        .toList();

    // Filter: status confirmed + dateTime falls on tomorrow (local).
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dayAfter = tomorrow.add(const Duration(days: 1));

    return appointments
        .where((a) =>
            a.status == 'confirmed' &&
            a.dateTime.isAfter(tomorrow.subtract(const Duration(seconds: 1))) &&
            a.dateTime.isBefore(dayAfter))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  } catch (_) {
    return const [];
  }
});

// ---------------------------------------------------------------------------
// C16 — Session-local dismiss state
// ---------------------------------------------------------------------------

/// True once the user has tapped the close button during this app session.
/// Resets on cold-start (no persistence needed — a banner per session is fine).
final _tomorrowBannerDismissedProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// C16 — Tomorrow Booking Banner Widget
// ---------------------------------------------------------------------------

/// Self-gating banner: renders nothing when:
///   - user is not authenticated
///   - no confirmed appointment tomorrow
///   - banner was dismissed this session
class TomorrowBookingBanner extends ConsumerWidget {
  const TomorrowBookingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDismissed = ref.watch(_tomorrowBannerDismissedProvider);
    if (isDismissed) return const SizedBox.shrink();

    final isAuth = ref.watch(
      authStateProvider.select((s) => s.isAuthenticated),
    );
    if (!isAuth) return const SizedBox.shrink();

    final async = ref.watch(tomorrowBookingsProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (appointments) {
        if (appointments.isEmpty) return const SizedBox.shrink();
        final first = appointments.first;
        return _TomorrowBannerContent(appointment: first);
      },
    );
  }
}

class _TomorrowBannerContent extends ConsumerWidget {
  final AppointmentModel appointment;
  const _TomorrowBannerContent({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr =
        '${appointment.dateTime.hour.toString().padLeft(2, '0')}:${appointment.dateTime.minute.toString().padLeft(2, '0')}';
    final message = context.l10n.tomorrowBookingBannerMessage(
      timeStr,
      appointment.companyName,
    );

    return GestureDetector(
      onTap: () => context.pushNamed('my-appointments'),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.ivoryAlt,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Bordeaux accent dot
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Message text
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Close button
            GestureDetector(
              onTap: () => ref
                  .read(_tomorrowBannerDismissedProvider.notifier)
                  .state = true,
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
