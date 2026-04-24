import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/services/ux_prefs_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_button.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ---------------------------------------------------------------------------
// C17 — First Booking Share Prompt
// ---------------------------------------------------------------------------

/// Shows a bottom-sheet share prompt after a user's first completed booking.
///
/// Call [showFirstBookingSharePrompt] from [BookingScreen] after the success
/// dialog closes. The function handles its own gating:
///   1. Increments the completed-bookings counter.
///   2. Returns early if the share prompt was already shown.
///   3. On first booking, marks prompt as shown and displays the sheet.
///
/// Deep link shared: https://termini-im.com (add deep link once registered).
const String _kShareUrl = 'https://termini-im.com';

// Shared service instance (same storage used by UxPrefsProvider).
final _sharePrefsService =
    UxPrefsService(const FlutterSecureStorage());

/// Entry point — increment counter, gate, show sheet.
///
/// Call right after the success dialog closes. Safe to call on every
/// completed booking — the function is idempotent after the first show.
Future<void> showFirstBookingSharePrompt(
    BuildContext context, WidgetRef ref) async {
  final service = _sharePrefsService;

  // Increment counter for every completed booking (also feeds C18).
  await service.incrementCompletedBookings();

  // Gate: only show once, only on the very first booking.
  final alreadyShown = await service.isSharePromptShown();
  if (alreadyShown) return;

  final count = await service.getCompletedBookingsCount();
  if (count != 1) return; // only after exactly the first booking

  await service.setSharePromptShown();

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _FirstBookingShareSheet(),
  );
}

// ---------------------------------------------------------------------------
// Sheet
// ---------------------------------------------------------------------------

class _FirstBookingShareSheet extends ConsumerWidget {
  const _FirstBookingShareSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Bordeaux icon container
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF511522), Color(0xFF7A2232)],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.share_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Title — Fraunces italic
          Text(
            context.l10n.shareAppTitle,
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Message — Instrument Sans
          Text(
            context.l10n.shareAppMessage,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Primary CTA
          AppButton(
            text: context.l10n.shareAppCta,
            onPressed: () {
              Navigator.of(context).pop();
              Share.share(_kShareUrl);
            },
            width: double.infinity,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Dismiss
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(
              context.l10n.shareAppLater,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
