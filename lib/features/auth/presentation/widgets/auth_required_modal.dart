import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';

/// Shows a bottom-sheet modal asking the guest to authenticate before
/// proceeding with a booking action.
///
/// Captures the caller's current location so that after a successful
/// login/signup the router can redirect back there instead of dropping the
/// user on `/home`. Without this, a shared booking link (e.g.
/// `/company/5/book?employee=7f1`) would be lost the moment the user taps
/// "Se connecter".
Future<void> showAuthRequiredModal(BuildContext context) {
  final returnTo = GoRouterState.of(context).uri.toString();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _AuthRequiredSheet(returnTo: returnTo),
  );
}

class _AuthRequiredSheet extends StatelessWidget {
  final String returnTo;
  const _AuthRequiredSheet({required this.returnTo});

  @override
  Widget build(BuildContext context) {
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

          // Lock icon with gradient background
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
              Icons.lock_outline_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
            context.l10n.loginToBook,
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Message
          Text(
            context.l10n.loginToBookMessage,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Se connecter button (primary filled)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.pushNamed(
                  RouteNames.login,
                  queryParameters: {'returnTo': returnTo},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(
                context.l10n.login,
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // S'inscrire button (outlined)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.pushNamed(
                  RouteNames.roleSelect,
                  queryParameters: {'returnTo': returnTo},
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(
                context.l10n.signup,
                style: AppTextStyles.button.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Continuer sans compte — dismisses the modal
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(
              context.l10n.continueWithoutAccount,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
