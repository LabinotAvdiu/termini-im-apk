import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Soft amber banner surfaced at the top of `/home` when the authenticated
/// user's profile is incomplete.
///
///  * **Client** — shown when either `gender` or `phone` is null.
///  * **Owner** — shown when `gender` is null (phone isn't required because
///    the salon has its own phone number).
///
/// Returns a `SizedBox.shrink()` when nothing's missing, so callers can drop
/// it in at the top of any scroll view without guarding.
class CompleteProfileBanner extends ConsumerWidget {
  const CompleteProfileBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.user;
    if (user == null || !auth.isAuthenticated) {
      return const SizedBox.shrink();
    }

    final isOwner = auth.isOwner || auth.isEmployee;
    final genderMissing = user.gender == null || user.gender!.isEmpty;
    final phoneMissing = user.phone == null || user.phone!.isEmpty;

    // Owner → gender only. Client → gender OR phone.
    final shouldShow = isOwner
        ? genderMissing
        : (genderMissing || phoneMissing);

    if (!shouldShow) return const SizedBox.shrink();

    final l = context.l10n;
    // Pick a dedicated message for each combination:
    //  - gender + phone missing  → "add both" (client only)
    //  - gender only missing     → "add gender"
    //  - phone only missing      → "add phone" (client only, owner never hits this)
    final String message;
    if (isOwner) {
      message = l.completeProfileGenderOnly;
    } else if (genderMissing && phoneMissing) {
      message = l.completeProfileGenderPhone;
    } else if (genderMissing) {
      message = l.completeProfileGenderOnly;
    } else {
      message = l.completeProfilePhoneOnly;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.pushNamed(RouteNames.settings),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.secondaryDark,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.completeYourProfileTitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.secondaryDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
