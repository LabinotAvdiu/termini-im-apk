import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';

/// Shows a confirmation dialog before removing a salon from favorites.
///
/// Returns `true` if the user confirmed, `false` or `null` if cancelled.
///
/// ```dart
/// final confirmed = await showRemoveFavoriteDialog(context, companyName: 'Barber Studio');
/// if (confirmed == true) { ... }
/// ```
Future<bool?> showRemoveFavoriteDialog(
  BuildContext context, {
  required String companyName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _RemoveFavoriteDialog(companyName: companyName),
  );
}

class _RemoveFavoriteDialog extends StatelessWidget {
  final String companyName;

  const _RemoveFavoriteDialog({required this.companyName});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return AlertDialog(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),

      // ── Cœur + titre ────────────────────────────────────────────────────────
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône cœur brisé
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.heart_broken_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l.removeFavoriteTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              letterSpacing: -0.44,
              height: 1.2,
            ),
          ),
        ],
      ),

      // ── Corps + boutons (une seule zone content pour le stretch pleine largeur)
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.removeFavoriteConfirm(companyName),
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Bouton principal — Retirer (bordeaux)
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l.remove,
              style: AppTextStyles.button.copyWith(
                color: AppColors.background,
                letterSpacing: 0.6,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Annuler — outlined discret
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l.cancel,
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
