import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// En-tête de section normé (§2.2 UX-UNIFORMISATION).
///
/// Affiche un eyebrow Instrument Sans + titre Fraunces, avec une action
/// optionnelle à droite.
///
/// Variante compacte (opérationnelle) :
///   - eyebrow = overline UPPERCASE + icône optionnelle
///   - Pas de numérotation éditoriale
///
/// Usage :
/// ```dart
/// AppSectionHeader(
///   title: l10n.team,
///   icon: Icons.people_outline_rounded,
///   action: TextButton(...),
/// )
/// ```
class AppSectionHeader extends StatelessWidget {
  /// Titre principal (Fraunces).
  final String title;

  /// Icône optionnelle affichée à gauche du label.
  final IconData? icon;

  /// Couleur de l'icône et de l'eyebrow. Par défaut [AppColors.textHint].
  final Color? color;

  /// Widget affiché à droite (ex. [TextButton], [IconButton]).
  final Widget? action;

  /// Affiche un eyebrow au-dessus du titre (ex. numéro de section ou
  /// catégorie courte).
  final String? eyebrow;

  /// Padding inférieur entre le header et le contenu qui suit.
  final double bottomPadding;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.color,
    this.action,
    this.eyebrow,
    this.bottomPadding = AppSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.textHint;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (eyebrow != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppSpacing.iconSm, color: resolvedColor),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    eyebrow!.toUpperCase(),
                    style: AppTextStyles.overline.copyWith(
                      color: resolvedColor,
                    ),
                  ),
                ],
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null && eyebrow == null) ...[
                Icon(icon, size: AppSpacing.iconSm, color: resolvedColor),
                const SizedBox(width: AppSpacing.sm),
              ],

              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h3,
                ),
              ),

              ?action,
            ],
          ),
        ],
      ),
    );
  }
}
