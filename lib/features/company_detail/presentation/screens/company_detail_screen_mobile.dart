import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/auth_prompt_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../favorites/presentation/providers/favorite_provider.dart';
import '../../../favorites/presentation/widgets/remove_favorite_dialog.dart';
import '../../data/models/company_detail_model.dart';
import '../providers/company_detail_provider.dart';
import '../widgets/photo_gallery.dart';
import '../widgets/service_category_section.dart';

/// M2 — Mobile presentation for the company detail screen.
///
/// Stateless presentation layer. All data is read from [companyDetailProvider]
/// or passed as props. Navigation callbacks are issued directly from here
/// because they are leaf actions (no shared logic with the desktop layout).
class CompanyDetailScreenMobile extends ConsumerWidget {
  final String companyId;

  const CompanyDetailScreenMobile({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final company = ref.watch(
      companyDetailProvider.select((s) => s.company!),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero SliverAppBar ──────────────────────────────────────────────
          // No `stretch` / `stretchModes` here: they install a vertical
          // overscroll gesture that fights with the PhotoGallery's PageView
          // horizontal swipe, preventing users from navigating photos.
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: _BackButton(),
            actions: [
              _HeartButton(
                companyId: companyId,
                isFavorite: company.isFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PhotoGallery(
                    photoUrls: company.photos,
                    height: 280,
                  ),
                  // Gradient: readability for the back/heart actions.
                  // Pointer events disabled so horizontal swipes reach the
                  // PageView below.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.10),
                              const Color(0xFF171311).withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Info sheet — sits below the hero, with rounded top edge ──────
          // We used to Transform.translate(-28) this up into the hero, but
          // the Viewport clips sliver paint to their own layout slot, so the
          // translated content (including the overline) was getting clipped
          // and visually covered by the hero image.
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MobileInfoSheet(
                  company: company,
                  companyId: companyId,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info sheet — rounded top corners, overlaps hero
// ---------------------------------------------------------------------------

class _MobileInfoSheet extends StatelessWidget {
  final CompanyDetailModel company;
  final String companyId;

  const _MobileInfoSheet({
    required this.company,
    required this.companyId,
  });

  Future<void> _dialPhone(BuildContext context, String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleaned');
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(phone)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = company.phone != null && company.phone!.isNotEmpty;
    final hasPhoneSecondary =
        company.phoneSecondary != null && company.phoneSecondary!.isNotEmpty;

    // Total services count
    final totalServices =
        company.categories.fold<int>(0, (sum, c) => sum + c.services.length);

    // Dynamic overline based on the salon's target gender — same copy as
    // desktop (see company_detail_screen_desktop.dart).
    final overline = switch (company.gender) {
      'men'   => context.l10n.salonForMen,
      'women' => context.l10n.salonForWomen,
      _       => context.l10n.salonUnisex,
    };

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name / overline / address / phone ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overline (burgundy, uppercase)
                Text(
                  overline,
                  style: AppTextStyles.overline.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),

                // Serif company name — M2 h2 (28px)
                Text(
                  company.name,
                  style: AppTextStyles.h2.copyWith(fontSize: 28),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Address
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
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

                if (hasPhone) ...[
                  const SizedBox(height: AppSpacing.xs),
                  GestureDetector(
                    onTap: () => _dialPhone(context, company.phone!),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 15,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          company.phone!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (hasPhoneSecondary) ...[
                  const SizedBox(height: AppSpacing.xs),
                  GestureDetector(
                    onTap: () =>
                        _dialPhone(context, company.phoneSecondary!),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 15,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          company.phoneSecondary!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Stats strip — bordered, M2 .m2-info .stats ─────────────
                const SizedBox(height: 14),
                _StatsStrip(
                  rating: company.rating,
                  reviewCount: company.reviewCount,
                  serviceCount: totalServices,
                ),
              ],
            ),
          ),

          // ── Services heading ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  context.l10n.ourServices,
                  style: AppTextStyles.h2,
                ),
                Text(
                  '$totalServices ${context.l10n.services.toLowerCase()}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          // ── Service categories ───────────────────────────────────────────
          ...company.categories.map(
            (cat) => ServiceCategorySection(
              category: cat,
              onServiceChosen: (service) {
                context.goNamed(
                  RouteNames.booking,
                  pathParameters: {'id': companyId},
                  queryParameters: {'serviceId': service.id},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats strip — rating / reviews / services, bordered top+bottom
// ---------------------------------------------------------------------------

class _StatsStrip extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final int serviceCount;

  const _StatsStrip({
    required this.rating,
    required this.reviewCount,
    required this.serviceCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          _StatCell(
            value: rating.toStringAsFixed(1),
            valueAccent: true,
            label: 'NOTE',
          ),
          _StatDivider(),
          _StatCell(
            value: '$reviewCount',
            label: context.l10n.reviews(reviewCount),
          ),
          _StatDivider(),
          _StatCell(
            value: '$serviceCount',
            label: context.l10n.services,
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final bool valueAccent;

  const _StatCell({
    required this.value,
    required this.label,
    this.valueAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: AppTextStyles.h3.copyWith(fontSize: 22),
              children: valueAccent
                  ? [
                      TextSpan(
                        text: '\u2605',
                        style: AppTextStyles.h3.copyWith(
                          fontSize: 22,
                          color: AppColors.primary,
                        ),
                      ),
                      TextSpan(text: value),
                    ]
                  : [TextSpan(text: value)],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.overline.copyWith(
              color: AppColors.textHint,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.divider,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero overlay buttons
// ---------------------------------------------------------------------------

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: AppColors.background.withValues(alpha: 0.90),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

/// Heart button in the SliverAppBar actions.
///
/// Animates with a scale heartbeat (1.0 → 1.25 → 1.0, 280 ms, easeOutBack)
/// on every toggle. Handles auth check, optimistic update, confirmation dialog
/// for removal, and error rollback via SnackBar.
class _HeartButton extends ConsumerStatefulWidget {
  final String companyId;
  final bool isFavorite;

  const _HeartButton({
    required this.companyId,
    required this.isFavorite,
  });

  @override
  ConsumerState<_HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends ConsumerState<_HeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    // Auth check — if guest or not authenticated, show auth prompt
    final auth = ref.read(authStateProvider);
    if (!auth.isAuthenticated || auth.isGuest) {
      showAuthPromptSheet(context);
      return;
    }

    final isFav = widget.isFavorite;

    if (!isFav) {
      // Adding: run heartbeat animation immediately, then call API
      _ctrl.forward(from: 0);
      final ok =
          await ref.read(favoriteProvider.notifier).add(widget.companyId);
      if (!mounted) return;
      if (ok) {
        context.showSnackBar(context.l10n.favoriteAdded);
      } else {
        final err = ref.read(favoriteProvider).error;
        context.showErrorSnackBar(err);
      }
    } else {
      // Removing: ask for confirmation first
      final confirmed = await showRemoveFavoriteDialog(
        context,
        companyName: ref
                .read(companyDetailProvider)
                .company
                ?.name ??
            '',
      );
      if (confirmed != true || !mounted) return;
      _ctrl.forward(from: 0);
      final ok =
          await ref.read(favoriteProvider.notifier).remove(widget.companyId);
      if (!mounted) return;
      if (ok) {
        context.showSnackBar(context.l10n.favoriteRemoved);
      } else {
        final err = ref.read(favoriteProvider).error;
        context.showErrorSnackBar(err);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch isFavorite from provider so it reflects optimistic updates
    final isFav = ref.watch(
      companyDetailProvider.select((s) => s.company?.isFavorite ?? false),
    );

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: AppColors.background.withValues(alpha: 0.90),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _handleTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ScaleTransition(
              scale: _scale,
              child: Icon(
                isFav
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
