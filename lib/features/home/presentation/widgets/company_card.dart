import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/providers/ux_prefs_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../favorites/presentation/providers/favorite_provider.dart';
import '../../../favorites/presentation/widgets/remove_favorite_dialog.dart';
import '../../data/models/company_card_model.dart';

class CompanyCard extends ConsumerWidget {
  final CompanyCardModel company;
  final int? rank;

  const CompanyCard({super.key, required this.company, this.rank});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF171311).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: () => context.goNamed(
            RouteNames.companyDetail,
            pathParameters: {'id': company.id},
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CompanyPhoto(
                    photoUrl: company.photoUrl,
                    name: company.name,
                    rank: rank,
                    isFavorite: company.isFavorite,
                    companyId: company.id,
                    companyName: company.name,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name.titleCase,
                            style: AppTextStyles.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  company.address,
                                  style: AppTextStyles.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          // Reserve the rating row slot even for salons with
                          // 0 reviews — keeps every card at the same height
                          // so the grid stays uniform.
                          const SizedBox(height: AppSpacing.xs),
                          Visibility(
                            visible: company.reviewCount > 0,
                            maintainSize: true,
                            maintainAnimation: true,
                            maintainState: true,
                            child: _RatingRow(company: company),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          // Unified slot row — same layout as desktop: up to
                          // 4 chips combined (morning + afternoon), no separate
                          // "MATIN / APRÈS-MIDI" split. Reserves a fixed height
                          // so a salon without upcoming slots keeps card
                          // dimensions aligned with the rest of the grid.
                          _CombinedSlotsRow(slots: company.slots),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Builder(
                builder: (context) {
                  final isMobile =
                      MediaQuery.sizeOf(context).width < 600;
                  return Row(
                    mainAxisAlignment: isMobile
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.spaceBetween,
                    children: [
                      if (!isMobile)
                        OutlinedButton(
                          onPressed: () => context.goNamed(
                            RouteNames.companyDetail,
                            pathParameters: {'id': company.id},
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            context.l10n.moreInfo,
                            style: AppTextStyles.buttonSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      _BookButton(companyId: company.id, ref: ref),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo with optional rank chip and favorite badge
// ---------------------------------------------------------------------------

class _CompanyPhoto extends ConsumerWidget {
  final String photoUrl;
  final String name;
  final int? rank;
  final bool isFavorite;
  final String companyId;
  final String companyName;

  const _CompanyPhoto({
    required this.photoUrl,
    required this.name,
    required this.isFavorite,
    required this.companyId,
    required this.companyName,
    this.rank,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width =
        (MediaQuery.sizeOf(context).width * 0.35).clamp(100.0, 130.0);

    return SizedBox(
      width: width,
      child: Stack(
        children: [
          Positioned.fill(
            // Hero: la photo "voyage" vers le détail salon.
            // Le tag est isolé à la photo seulement — les overlays (rank, heart)
            // ne font pas partie du Hero pour éviter les conflits visuels.
            child: Hero(
              tag: 'company-photo-$companyId',
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: AppColors.divider,
                  highlightColor: AppColors.background,
                  child: Container(color: AppColors.divider),
                ),
                errorWidget: (context, url, error) =>
                    _PhotoFallback(name: name),
              ),
            ),
          ),
          if (rank != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rank!.toString().padLeft(2, '0'),
                  style: AppTextStyles.overline.copyWith(
                    color: AppColors.background,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

          // Favorite badge — only shown when isFavorite is true
          if (isFavorite)
            Positioned(
              top: 12,
              right: 12,
              child: FavoriteBadge(
                companyId: companyId,
                companyName: companyName,
                ref: ref,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Favorite badge overlay — 28×28 capsule, ivoire 92% + cœur bordeaux
// ---------------------------------------------------------------------------

class FavoriteBadge extends StatelessWidget {
  final String companyId;
  final String companyName;
  final WidgetRef ref;

  const FavoriteBadge({
    required this.companyId,
    required this.companyName,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.favoriteBadgeTooltip,
      button: true,
      child: GestureDetector(
        onTap: () async {
          // Action destructrice — mediumImpact avant la dialog de confirmation.
          ref.read(uxPrefsProvider.notifier).mediumImpact();
          final confirmed = await showRemoveFavoriteDialog(
            context,
            companyName: companyName,
          );
          if (confirmed == true && context.mounted) {
            final ok = await ref
                .read(favoriteProvider.notifier)
                .remove(companyId);
            if (!context.mounted) return;
            if (ok) {
              context.showSnackBar(context.l10n.favoriteRemoved);
            } else {
              final err = ref.read(favoriteProvider).error;
              context.showErrorSnackBar(err);
            }
          }
        },
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: AppColors.primary,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  final String name;
  const _PhotoFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: AppColors.ivoryAlt,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rating row
// ---------------------------------------------------------------------------

class _RatingRow extends StatelessWidget {
  final CompanyCardModel company;
  const _RatingRow({required this.company});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 13, color: AppColors.starRating),
        const SizedBox(width: 3),
        Text(
          company.rating.toStringAsFixed(1),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '· ${context.l10n.reviews(company.reviewCount)}',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Combined slots row — mirrors the desktop layout: up to 4 chips, morning
// and afternoon merged, same chip styling (ink fill when available, ivory
// border when not). Fixed height keeps card dimensions stable even when a
// salon has no upcoming slots.
// ---------------------------------------------------------------------------

class _CombinedSlotsRow extends StatelessWidget {
  final List<DaySlot> slots;
  const _CombinedSlotsRow({required this.slots});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: slots.isEmpty
          ? const SizedBox()
          : Row(
              children: slots
                  .map(
                    (slot) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _UnifiedSlotChip(slot: slot),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _UnifiedSlotChip extends StatelessWidget {
  final DaySlot slot;
  const _UnifiedSlotChip({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: slot.available ? AppColors.textPrimary : AppColors.background,
        border: Border.all(
          color: slot.available ? AppColors.textPrimary : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${slot.date.day.toString().padLeft(2, '0')}/'
        '${slot.date.month.toString().padLeft(2, '0')}',
        style: AppTextStyles.caption.copyWith(
          color: slot.available ? AppColors.background : AppColors.textHint,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Book CTA
// ---------------------------------------------------------------------------

class _BookButton extends StatelessWidget {
  final String companyId;
  final WidgetRef ref;

  const _BookButton({required this.companyId, required this.ref});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        ref.read(uxPrefsProvider.notifier).lightImpact();
        context.goNamed(
          RouteNames.companyDetail,
          pathParameters: {'id': companyId},
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      child: Text(
        context.l10n.bookAppointment,
        style: AppTextStyles.buttonSmall.copyWith(color: AppColors.background),
      ),
    );
  }
}
