import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';

/// Displays the rejection reason the owner provided when refusing an appointment
/// (pending → rejected). Uses the editorial bordeaux palette to differentiate
/// visually from [CancellationReasonBox] (which is error-red, client-initiated).
///
/// When [showSlotFreedBadge] is true (rejected → cancelled, slot released),
/// an additional "Créneau libéré" badge is appended to signal the state change.
class RejectionReasonBox extends StatelessWidget {
  final String reason;

  /// Show the "Créneau libéré" badge — pass true when status == 'cancelled'
  /// but rejectionReason is not null (i.e. was rejected then slot was freed).
  final bool showSlotFreedBadge;

  const RejectionReasonBox({
    super.key,
    required this.reason,
    this.showSlotFreedBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.block_rounded,
                size: 14,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                l.rejectionReasonOwnerLabel,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              if (showSlotFreedBadge) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_open_rounded,
                        size: 10,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        l.slotFreedBadge,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reason,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
