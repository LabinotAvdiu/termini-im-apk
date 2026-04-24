import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/auth_provider.dart';

/// Persistent banner shown at the top of [MainShell] when the authenticated
/// user has not yet confirmed their email address.
///
/// Tapping anywhere on the banner (or the CTA) navigates to [/verify-email].
/// The banner is invisible when [user.emailVerified] is true.
class UnverifiedEmailBanner extends ConsumerWidget {
  const UnverifiedEmailBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider.select((s) => s.user));

    // Only show for authenticated users whose email is not yet verified.
    if (user == null || user.emailVerified) return const SizedBox.shrink();

    return _BannerContent(email: user.email);
  }
}

class _BannerContent extends StatelessWidget {
  final String email;

  const _BannerContent({required this.email});

  void _navigate(BuildContext context) {
    context.push(
      Uri(
        path: '/verify-email',
        queryParameters: {'email': email},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigate(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.ivoryAlt,
          border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            // Bourgogne accent dot
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Message text
            Expanded(
              child: Text(
                context.l10n.unverifiedBannerMessage,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // CTA — italic serif link
            Text(
              context.l10n.unverifiedBannerCta,
              style: GoogleFonts.instrumentSerif(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),

            const SizedBox(width: AppSpacing.xs),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 11,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
