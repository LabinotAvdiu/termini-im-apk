import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/auth_provider.dart';

/// Social auth buttons shown on the auth landing screen.
///
/// Google & Facebook are wired through the existing auth provider.
/// Apple is displayed for parity — the backend endpoint is not yet ready,
/// so tapping it surfaces a "coming soon" snackbar instead of crashing.
class SocialLoginButtons extends ConsumerWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final isLoading = auth.isLoading;

    return Column(
      children: [
        _SocialButton(
          iconAsset: 'assets/icons/google.png',
          label: context.l10n.continueWithGoogle,
          onPressed: isLoading
              ? null
              : () =>
                  ref.read(authStateProvider.notifier).loginWithGoogle(),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SocialButton(
          iconAsset: 'assets/icons/facebook.png',
          label: context.l10n.continueWithFacebook,
          onPressed: isLoading
              ? null
              : () =>
                  ref.read(authStateProvider.notifier).loginWithFacebook(),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SocialButton(
          iconAsset: 'assets/icons/apple.svg',
          iconColor: AppColors.textPrimary,
          label: context.l10n.continueWithApple,
          onPressed: isLoading
              ? null
              : () => ref.read(authStateProvider.notifier).loginWithApple(),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String iconAsset;
  final String label;
  final VoidCallback? onPressed;

  /// When set, the SVG is rendered in this single flat color instead of its
  /// native colors. Used for the monochrome Apple glyph so it adapts to
  /// the button's foreground.
  final Color? iconColor;

  const _SocialButton({
    required this.iconAsset,
    required this.label,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // PNG assets (google.png, facebook.png) render as full-color Image.
            // SVG assets (apple.svg) stay on SvgPicture so iconColor can tint
            // the monochrome Apple glyph to match the button foreground.
            iconAsset.endsWith('.svg')
                ? SvgPicture.asset(
                    iconAsset,
                    width: 20,
                    height: 20,
                    colorFilter: iconColor != null
                        ? ColorFilter.mode(iconColor!, BlendMode.srcIn)
                        : null,
                  )
                : Image.asset(
                    iconAsset,
                    width: 20,
                    height: 20,
                    filterQuality: FilterQuality.medium,
                  ),
            const SizedBox(width: AppSpacing.sm + 2),
            Text(
              label,
              style: GoogleFonts.instrumentSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
