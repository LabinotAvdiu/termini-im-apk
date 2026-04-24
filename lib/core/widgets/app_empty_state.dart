import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Variante visuelle de l'état vide.
///
/// [neutral] — fond sable [AppColors.background], utilisé dans les listes
///             scrollables (ex. onglet Avis vide).
/// [soft]    — fond ivoire [AppColors.surface], utilisé dans les cartes
///             intégrées à une page (ex. section équipe vide dans le dashboard).
enum AppEmptyStateVariant { neutral, soft }

/// Widget normé pour les états vides (§2.6 UX-UNIFORMISATION).
///
/// Affiche : icône doux + titre Fraunces + sous-titre Instrument Sans + CTA optionnel.
/// Usage :
/// ```dart
/// AppEmptyState(
///   icon: Icons.star_outline_rounded,
///   title: l10n.reviewsEmpty,
///   subtitle: l10n.reviewsEmptySubtitle,
///   variant: AppEmptyStateVariant.neutral,
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final AppEmptyStateVariant variant;
  /// Couleur de l'icône. Par défaut [AppColors.textHint] à 40 % d'opacité.
  final Color? iconColor;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.variant = AppEmptyStateVariant.neutral,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = variant == AppEmptyStateVariant.soft
        ? AppColors.surface
        : AppColors.background;

    final resolvedIconColor =
        iconColor ?? AppColors.textHint.withValues(alpha: 0.4);

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: resolvedIconColor),

          const SizedBox(height: AppSpacing.md),

          Text(
            title,
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),

          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],

          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: actionLabel!,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
