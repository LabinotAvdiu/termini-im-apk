import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/models/company_card_model.dart';

String _shortDayName(BuildContext context, DateTime date) {
  final l = context.l10n;
  switch (date.weekday) {
    case DateTime.monday:
      return l.dayShortMon;
    case DateTime.tuesday:
      return l.dayShortTue;
    case DateTime.wednesday:
      return l.dayShortWed;
    case DateTime.thursday:
      return l.dayShortThu;
    case DateTime.friday:
      return l.dayShortFri;
    case DateTime.saturday:
      return l.dayShortSat;
    case DateTime.sunday:
    default:
      return l.dayShortSun;
  }
}

/// The main listing card shown on the Home screen.
///
/// Layout (matches reference spec):
///   ┌─────────────────────────────────────────┐
///   │ [PHOTO]   Name                           │
///   │           📍 Address                     │
///   │           ⭐ 4.9 (674 avis) · €€€        │
///   │           MATIN     [Mer.15][Jeu.16]...  │
///   │           APRÈS-MIDI[Mer.15][Jeu.16]...  │
///   │  Plus d'informations       [Prendre RDV] │
///   └─────────────────────────────────────────┘
class CompanyCard extends ConsumerWidget {
  final CompanyCardModel company;

  const CompanyCard({super.key, required this.company});

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
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top section: photo + info ──────────────────────────────
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: photo (~35% of card width)
                  _CompanyPhoto(photoUrl: company.photoUrl, name: company.name),

                  // Right: info column
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
                          // Company name
                          Text(
                            company.name,
                            style: AppTextStyles.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),

                          // Address
                          _IconRow(
                            icon: Icons.location_on_rounded,
                            iconColor: AppColors.secondary,
                            child: Text(
                              company.address,
                              style: AppTextStyles.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),

                          // Rating + reviews + price
                          _RatingRow(company: company),
                          const SizedBox(height: AppSpacing.sm),

                          // Time slots — MATIN
                          _SlotRow(
                            label: context.l10n.morning,
                            slots: company.morningSlots,
                          ),
                          const SizedBox(height: AppSpacing.xs),

                          // Time slots — APRÈS-MIDI
                          _SlotRow(
                            label: context.l10n.afternoon,
                            slots: company.afternoonSlots,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ────────────────────────────────────────────────
            const Divider(height: 1, color: AppColors.divider),

            // ── Bottom action bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // "Plus d'informations" styled button
                  OutlinedButton(
                    onPressed: () => context.goNamed(
                      RouteNames.companyDetail,
                      pathParameters: {'id': company.id},
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.l10n.moreInfo,
                      style: AppTextStyles.buttonSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  // CTA — "Prendre RDV"
                  _BookButton(companyId: company.id, ref: ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo sub-widget
// ---------------------------------------------------------------------------

class _CompanyPhoto extends StatelessWidget {
  final String photoUrl;
  final String name;

  const _CompanyPhoto({required this.photoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    // 35% of screen width, capped for large screens
    final width = (MediaQuery.sizeOf(context).width * 0.35).clamp(100.0, 160.0);

    return SizedBox(
      width: width,
      child: CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        // Shimmer skeleton while loading
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: AppColors.divider,
          highlightColor: AppColors.background,
          child: Container(color: AppColors.divider),
        ),
        // Fallback: gradient placeholder with initials
        errorWidget: (context, url, error) => _PhotoFallback(name: name),
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
      color: AppColors.primaryLight.withAlpha(60),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
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
// Icon + content row
// ---------------------------------------------------------------------------

class _IconRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _IconRow({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 13, color: iconColor),
        ),
        const SizedBox(width: 3),
        Expanded(child: child),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Rating row: ⭐ 4.9 (892 avis) · €€€€
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
          '(${context.l10n.reviews(company.reviewCount)})',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Slot row: MATIN  [Mer.15] [Jeu.16] …
// ---------------------------------------------------------------------------

class _SlotRow extends StatelessWidget {
  final String label;
  final List<DaySlot> slots;

  const _SlotRow({required this.label, required this.slots});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Label (MATIN / APRÈS-MIDI) — fixed width for alignment
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
        ),
        // Scrollable slot chips
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: slots
                  .map((slot) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _SlotChip(slot: slot),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Single day slot chip: "Mer.15"
// ---------------------------------------------------------------------------

class _SlotChip extends StatelessWidget {
  final DaySlot slot;
  const _SlotChip({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: slot.available ? AppColors.slotAvailable : AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: slot.available ? AppColors.primary.withAlpha(80) : AppColors.border,
          width: 1,
        ),
      ),
      child: Text(
        '${_shortDayName(context, slot.date)} ${slot.date.day}',
        style: AppTextStyles.caption.copyWith(
          color: slot.available ? AppColors.primary : AppColors.textHint,
          fontWeight: slot.available ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Prendre RDV" CTA button
// ---------------------------------------------------------------------------

class _BookButton extends StatelessWidget {
  final String companyId;
  final WidgetRef ref;

  const _BookButton({required this.companyId, required this.ref});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.goNamed(
          RouteNames.companyDetail,
          pathParameters: {'id': companyId},
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      child: Text(
        context.l10n.bookAppointment,
        style: AppTextStyles.buttonSmall.copyWith(color: Colors.white),
      ),
    );
  }
}
