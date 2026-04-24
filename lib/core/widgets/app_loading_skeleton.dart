import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Helpers shimmer génériques (§2.7 UX-UNIFORMISATION).
///
/// Animation 1.4 s, couleurs [AppColors.divider] → [AppColors.background].
/// Trois factories statiques :
///   - [AppLoadingSkeleton.rect] — bloc rectangle de hauteur h, largeur w
///   - [AppLoadingSkeleton.line] — ligne de texte de largeur optionnelle
///   - [AppLoadingSkeleton.circle] — avatar circulaire
///
/// Pour des skeletons contextuels plus riches (carte salon, planning, etc.)
/// utiliser les widgets de `lib/core/widgets/skeletons/skeleton_widgets.dart`.
class AppLoadingSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool _isCircle;

  const AppLoadingSkeleton._({
    this.width,
    this.height,
    this.borderRadius,
    bool isCircle = false,
  }) : _isCircle = isCircle;

  /// Bloc rectangle shimmer.
  static Widget rect(double h, {double? w}) => AppLoadingSkeleton._(
        width: w,
        height: h,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      );

  /// Ligne de texte shimmer (hauteur fixe 13 dp).
  static Widget line({double? width}) => AppLoadingSkeleton._(
        width: width,
        height: 13,
        borderRadius: BorderRadius.circular(4),
      );

  /// Avatar ou icône circulaire shimmer.
  static Widget circle(double size) => AppLoadingSkeleton._(
        width: size,
        height: size,
        isCircle: true,
      );

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.ivoryAlt,
      highlightColor: AppColors.surface,
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.ivoryAlt,
          borderRadius: _isCircle
              ? null
              : (borderRadius ?? BorderRadius.circular(AppSpacing.radiusSm)),
          shape: _isCircle ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }
}

/// Squelette générique pour une liste de reviews : N lignes de carte.
///
/// Utilisé par [MyCompanyReviewsScreen] pour remplacer le
/// [CircularProgressIndicator] plein écran.
class AppReviewsLoadingSkeleton extends StatelessWidget {
  final int count;

  const AppReviewsLoadingSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: count,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header : avatar + nom + date + étoiles
              Row(
                children: [
                  AppLoadingSkeleton.circle(40),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppLoadingSkeleton.line(),
                        const SizedBox(height: AppSpacing.xs),
                        AppLoadingSkeleton.line(width: 80),
                      ],
                    ),
                  ),
                  AppLoadingSkeleton.rect(12, w: 72),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Commentaire — 2 lignes
              AppLoadingSkeleton.line(),
              const SizedBox(height: AppSpacing.xs),
              AppLoadingSkeleton.line(width: 160),
            ],
          ),
        ),
      ),
    );
  }
}
