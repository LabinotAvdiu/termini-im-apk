import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../router/route_names.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/extensions.dart';

/// Shows a bottom sheet prompting the guest to log in or create an account.
void showAuthPromptSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (ctx) {
      final l = ctx.l10n;
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
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
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.authPromptTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.fraunces(
                fontSize: 26,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
                height: 1.15,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.authPromptSubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pushNamed(RouteNames.login);
              },
              child: Text(
                l.login,
                style: GoogleFonts.instrumentSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.background,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pushNamed(RouteNames.roleSelect);
              },
              child: Text(
                l.signup,
                style: GoogleFonts.instrumentSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
