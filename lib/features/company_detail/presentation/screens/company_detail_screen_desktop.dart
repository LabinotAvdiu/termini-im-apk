import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../widgets/gallery_lightbox.dart';

/// D2 — Desktop/editorial presentation for the company detail screen.
///
/// Layout: top brandbar → multi-photo gallery grid → 2-column body
/// (left: name/stats/services, right: sticky booking card).
///
/// Stateless presentation — reads [companyDetailProvider] directly for
/// display data. Navigation is issued locally (leaf actions only).
class CompanyDetailScreenDesktop extends ConsumerStatefulWidget {
  final String companyId;

  const CompanyDetailScreenDesktop({super.key, required this.companyId});

  @override
  ConsumerState<CompanyDetailScreenDesktop> createState() =>
      _CompanyDetailScreenDesktopState();
}

class _CompanyDetailScreenDesktopState
    extends ConsumerState<CompanyDetailScreenDesktop> {
  // Attached to the services section so the sidebar CTA can scroll to it.
  final GlobalKey _servicesKey = GlobalKey();

  void _scrollToServices() {
    final ctx = _servicesKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = ref.watch(
      companyDetailProvider.select((s) => s.company!),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1360),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top brand bar ──────────────────────────────────────────
                _DesktopTopBar(companyId: widget.companyId),

                // ── Photo gallery grid ─────────────────────────────────────
                _DesktopGallery(
                  photos: company.photos,
                  salonName: company.name,
                ),

                // ── 2-column body ──────────────────────────────────────────
                _DesktopBody(
                  company: company,
                  companyId: widget.companyId,
                  servicesKey: _servicesKey,
                  onViewServices: _scrollToServices,
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top brand bar — back link + brand wordmark + favorite button
// ---------------------------------------------------------------------------

class _DesktopTopBar extends ConsumerWidget {
  final String companyId;

  const _DesktopTopBar({required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 36,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          // Back link
          InkWell(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 13,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.back,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Brand wordmark
          RichText(
            text: TextSpan(
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
              children: const [
                TextSpan(text: 'Termini '),
                TextSpan(
                  text: 'im',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Favorite button (right side)
          _DesktopFavoriteButton(companyId: companyId),
        ],
      ),
    );
  }
}

/// Animated favorite outlined button for desktop top bar.
class _DesktopFavoriteButton extends ConsumerStatefulWidget {
  final String companyId;

  const _DesktopFavoriteButton({required this.companyId});

  @override
  ConsumerState<_DesktopFavoriteButton> createState() =>
      _DesktopFavoriteButtonState();
}

class _DesktopFavoriteButtonState
    extends ConsumerState<_DesktopFavoriteButton>
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
    final auth = ref.read(authStateProvider);
    if (!auth.isAuthenticated || auth.isGuest) {
      showAuthPromptSheet(context);
      return;
    }

    final isFav = ref.read(
      companyDetailProvider.select((s) => s.company?.isFavorite ?? false),
    );

    if (!isFav) {
      _ctrl.forward(from: 0);
      final ok =
          await ref.read(favoriteProvider.notifier).add(widget.companyId);
      if (!mounted) return;
      if (ok) {
        context.showSnackBar(context.l10n.favoriteAdded);
      } else {
        context.showErrorSnackBar(ref.read(favoriteProvider).error);
      }
    } else {
      final companyName =
          ref.read(companyDetailProvider).company?.name ?? '';
      final confirmed = await showRemoveFavoriteDialog(
        context,
        companyName: companyName,
      );
      if (confirmed != true || !mounted) return;
      _ctrl.forward(from: 0);
      final ok =
          await ref.read(favoriteProvider.notifier).remove(widget.companyId);
      if (!mounted) return;
      if (ok) {
        context.showSnackBar(context.l10n.favoriteRemoved);
      } else {
        context.showErrorSnackBar(ref.read(favoriteProvider).error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFav = ref.watch(
      companyDetailProvider.select((s) => s.company?.isFavorite ?? false),
    );

    return ScaleTransition(
      scale: _scale,
      child: OutlinedButton.icon(
        onPressed: _handleTap,
        icon: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 16,
          color: AppColors.primary,
        ),
        label: const SizedBox.shrink(),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: isFav ? AppColors.primary : AppColors.border,
          ),
          backgroundColor: isFav
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          minimumSize: const Size(44, 44),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo gallery — D2 grid: 1 large (spans 2 rows) + up to 4 thumbnails.
//
// When photos.length > 5, the last visible thumbnail (index 4, bottom-right)
// shows an editorial "+N photos" overlay (Airbnb/Booksy pattern). Tapping any
// cell opens the fullscreen lightbox on that photo.
// ---------------------------------------------------------------------------

class _DesktopGallery extends StatelessWidget {
  final List<String> photos;
  final String? salonName;

  const _DesktopGallery({required this.photos, this.salonName});

  @override
  Widget build(BuildContext context) {
    // Always render at most 5 slots; the rest are accessible via lightbox.
    final displayPhotos = photos.take(5).toList();
    final extraCount = photos.length > 5 ? photos.length - 5 : 0;

    final mainUrl = displayPhotos.isNotEmpty ? displayPhotos[0] : null;
    final thumbUrls = displayPhotos.length > 1
        ? displayPhotos.sublist(1)
        : <String>[];

    void openLightbox(int index) {
      showGalleryLightbox(
        context,
        photos,
        initialIndex: index,
        salonName: salonName,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 0, 36, 0),
      child: SizedBox(
        height: 480,
        child: photos.isEmpty
            ? _GalleryPlaceholder(radius: AppSpacing.radiusLg)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Main photo — full height, left 2/3 ──────────────────
                  Expanded(
                    flex: 2,
                    child: _GalleryCell(
                      url: mainUrl,
                      photoIndex: 0,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppSpacing.radiusLg),
                        bottomLeft: Radius.circular(AppSpacing.radiusLg),
                      ),
                      onTap: () => openLightbox(0),
                    ),
                  ),

                  // ── First thumbnail column (photos 1 & 2) ───────────────
                  if (thumbUrls.isNotEmpty) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Expanded(
                            child: _GalleryCell(
                              url: thumbUrls[0],
                              photoIndex: 1,
                              borderRadius: thumbUrls.length <= 1
                                  ? const BorderRadius.only(
                                      topRight:
                                          Radius.circular(AppSpacing.radiusLg),
                                      bottomRight:
                                          Radius.circular(AppSpacing.radiusLg),
                                    )
                                  : const BorderRadius.only(
                                      topRight:
                                          Radius.circular(AppSpacing.radiusLg),
                                    ),
                              onTap: () => openLightbox(1),
                            ),
                          ),
                          if (thumbUrls.length > 1) ...[
                            const SizedBox(height: 14),
                            Expanded(
                              child: _GalleryCell(
                                url: thumbUrls[1],
                                photoIndex: 2,
                                borderRadius: const BorderRadius.only(
                                  bottomRight:
                                      Radius.circular(AppSpacing.radiusLg),
                                ),
                                onTap: () => openLightbox(2),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // ── Second thumbnail column (photos 3 & 4) ──────────────
                  if (thumbUrls.length > 2) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Expanded(
                            child: _GalleryCell(
                              url: thumbUrls[2],
                              photoIndex: 3,
                              borderRadius: thumbUrls.length <= 3
                                  ? const BorderRadius.only(
                                      topRight:
                                          Radius.circular(AppSpacing.radiusLg),
                                      bottomRight:
                                          Radius.circular(AppSpacing.radiusLg),
                                    )
                                  : const BorderRadius.only(
                                      topRight:
                                          Radius.circular(AppSpacing.radiusLg),
                                    ),
                              onTap: () => openLightbox(3),
                            ),
                          ),
                          if (thumbUrls.length > 3) ...[
                            const SizedBox(height: 14),
                            // Bottom-right cell — carries the "+N" overlay when
                            // there are more than 5 photos in total.
                            Expanded(
                              child: _GalleryCell(
                                url: thumbUrls[3],
                                photoIndex: 4,
                                borderRadius: const BorderRadius.only(
                                  bottomRight:
                                      Radius.circular(AppSpacing.radiusLg),
                                ),
                                onTap: () => openLightbox(4),
                                extraCount: extraCount,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single grid cell — CachedNetworkImage + optional "+N" overlay
// ---------------------------------------------------------------------------

class _GalleryCell extends StatefulWidget {
  final String? url;
  final int photoIndex;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  /// When > 0, an editorial overlay is rendered on top of the image.
  final int extraCount;

  const _GalleryCell({
    required this.url,
    required this.photoIndex,
    required this.borderRadius,
    required this.onTap,
    this.extraCount = 0,
  });

  @override
  State<_GalleryCell> createState() => _GalleryCellState();
}

class _GalleryCellState extends State<_GalleryCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.url == null) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: Container(
          color: AppColors.divider,
          child: const Center(
            child: Icon(
              Icons.store_rounded,
              color: AppColors.textHint,
              size: 48,
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Base image ──────────────────────────────────────────────
              CachedNetworkImage(
                imageUrl: widget.url!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(color: AppColors.divider),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.divider,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.textHint,
                      size: 32,
                    ),
                  ),
                ),
              ),

              // ── Hover brightness tint (all cells) ──────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                color: Colors.black.withValues(
                  alpha: widget.extraCount > 0
                      ? (_hovered ? 0.45 : 0.55)
                      : (_hovered ? 0.12 : 0.0),
                ),
              ),

              // ── "+N photos" overlay (last thumbnail only) ──────────────
              if (widget.extraCount > 0)
                Center(
                  child: AnimatedScale(
                    scale: _hovered ? 1.03 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: _MorePhotosOverlayContent(
                      extraCount: widget.extraCount,
                    ),
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
// Overlay content: icon + "+N" large + "Voir la galerie" sub-label
// ---------------------------------------------------------------------------

class _MorePhotosOverlayContent extends StatelessWidget {
  final int extraCount;

  const _MorePhotosOverlayContent({required this.extraCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.photo_library_outlined,
          color: Colors.white,
          size: 22,
        ),
        const SizedBox(height: 8),
        Text(
          '+ $extraCount',
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.viewGallery.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GalleryPlaceholder extends StatelessWidget {
  final double radius;

  const _GalleryPlaceholder({required this.radius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.primary],
          ),
        ),
        child: const Center(
          child: Icon(Icons.store_rounded, size: 72, color: Colors.white54),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2-column body: left (main) + right (sidebar booking card)
// ---------------------------------------------------------------------------

class _DesktopBody extends StatelessWidget {
  final CompanyDetailModel company;
  final String companyId;
  final GlobalKey servicesKey;
  final VoidCallback onViewServices;

  const _DesktopBody({
    required this.company,
    required this.companyId,
    required this.servicesKey,
    required this.onViewServices,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 30, 36, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left — main content (1.6 parts)
          Expanded(
            flex: 16,
            child: _DesktopMainColumn(
              company: company,
              companyId: companyId,
              servicesKey: servicesKey,
            ),
          ),

          const SizedBox(width: 60),

          // Right — booking sidebar (1 part ≈ 360 px)
          SizedBox(
            width: 340,
            child: _BookingSidebar(
              company: company,
              companyId: companyId,
              onViewServices: onViewServices,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Left column — overline, serif h2, lede, stats strip, services
// ---------------------------------------------------------------------------

class _DesktopMainColumn extends StatelessWidget {
  final CompanyDetailModel company;
  final String companyId;
  final GlobalKey servicesKey;

  const _DesktopMainColumn({
    required this.company,
    required this.companyId,
    required this.servicesKey,
  });

  @override
  Widget build(BuildContext context) {
    final totalServices =
        company.categories.fold<int>(0, (sum, c) => sum + c.services.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overline — uppercase burgundy. Reflects the salon's target audience.
        Text(
          switch (company.gender) {
            'men' => context.l10n.salonForMen,
            'women' => context.l10n.salonForWomen,
            _ => context.l10n.salonUnisex,
          }
              .toUpperCase(),
          style: AppTextStyles.overline.copyWith(
            color: AppColors.primary,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),

        // Company name — large Fraunces with italic accent on last word
        _SerifHeadline(name: company.name),

        const SizedBox(height: 24),

        // Lede — italic serif, muted
        Text(
          company.address,
          style: GoogleFonts.instrumentSerif(
            fontSize: 20,
            fontStyle: FontStyle.italic,
            color: AppColors.textHint,
            height: 1.5,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),

        // ── Stats strip (4 columns) ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: _DesktopStatsStrip(
            rating: company.rating,
            reviewCount: company.reviewCount,
            serviceCount: totalServices,
          ),
        ),

        // ── Services section ───────────────────────────────────────────────
        RichText(
          key: servicesKey,
          text: TextSpan(
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              letterSpacing: -0.56,
            ),
            children: [
              TextSpan(text: '${context.l10n.ourServices} '),
              TextSpan(
                text: context.l10n.servicesOffered,
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primary,
                  letterSpacing: -0.56,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Services — D2 layout per category
        ...company.categories.map(
          (cat) => _DesktopCategorySection(
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
    );
  }
}

/// Large Fraunces headline — last word italic burgundy
class _SerifHeadline extends StatelessWidget {
  final String name;

  const _SerifHeadline({required this.name});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final lastWord = parts.isNotEmpty ? parts.removeLast() : '';
    final firstPart = parts.join(' ');

    final baseStyle = GoogleFonts.fraunces(
      fontSize: 64,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      height: 0.96,
      letterSpacing: -1.5,
    );

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          if (firstPart.isNotEmpty) TextSpan(text: '$firstPart '),
          TextSpan(
            text: lastWord,
            style: baseStyle.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop stats strip — 4 cells with vertical right-borders
// ---------------------------------------------------------------------------

class _DesktopStatsStrip extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final int serviceCount;

  const _DesktopStatsStrip({
    required this.rating,
    required this.reviewCount,
    required this.serviceCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          _DesktopStatCell(
            valueWidget: RichText(
              text: TextSpan(
                style: GoogleFonts.fraunces(
                  fontSize: 34,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.68,
                ),
                children: [
                  TextSpan(
                    text: '\u2605',
                    style: GoogleFonts.fraunces(
                      fontSize: 34,
                      color: AppColors.primary,
                    ),
                  ),
                  TextSpan(text: rating.toStringAsFixed(1)),
                ],
              ),
            ),
            label: context.l10n.averageRating.toUpperCase(),
            hasBorder: true,
          ),
          _DesktopStatCell(
            valueWidget: Text(
              '$reviewCount',
              style: GoogleFonts.fraunces(
                fontSize: 34,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                letterSpacing: -0.68,
              ),
            ),
            label: context.l10n.reviews(reviewCount).toUpperCase(),
            hasBorder: true,
          ),
          _DesktopStatCell(
            valueWidget: Text(
              '$serviceCount',
              style: GoogleFonts.fraunces(
                fontSize: 34,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                letterSpacing: -0.68,
              ),
            ),
            label: context.l10n.services.toUpperCase(),
            hasBorder: false,
          ),
        ],
      ),
    );
  }
}

class _DesktopStatCell extends StatelessWidget {
  final Widget valueWidget;
  final String label;
  final bool hasBorder;

  const _DesktopStatCell({
    required this.valueWidget,
    required this.label,
    required this.hasBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.only(right: 24),
        decoration: hasBorder
            ? const BoxDecoration(
                border: Border(
                  right: BorderSide(color: AppColors.divider, width: 1),
                ),
              )
            : null,
        margin: const EdgeInsets.only(right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            valueWidget,
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textHint,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop service category — D2 layout
// ---------------------------------------------------------------------------

class _DesktopCategorySection extends StatelessWidget {
  final ServiceCategoryModel category;
  final void Function(ServiceModel service) onServiceChosen;

  const _DesktopCategorySection({
    required this.category,
    required this.onServiceChosen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category heading with count chip
        Padding(
          padding: const EdgeInsets.only(top: 28, bottom: 4),
          child: Row(
            children: [
              Text(
                category.name,
                style: AppTextStyles.h3.copyWith(
                  fontSize: 18,
                  letterSpacing: -0.18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Text(
                  '${category.services.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Service rows
        ...category.services.map(
          (svc) => _DesktopServiceRow(
            service: svc,
            onChoose: () => onServiceChosen(svc),
          ),
        ),
      ],
    );
  }
}

class _DesktopServiceRow extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onChoose;

  const _DesktopServiceRow({
    required this.service,
    required this.onChoose,
  });

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: service name + description placeholder
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 18,
                    letterSpacing: -0.18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(service.durationMinutes),
                  style: AppTextStyles.caption.copyWith(
                    letterSpacing: 1.0,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Right: price + duration + choose pill
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${service.price.toStringAsFixed(0)} \u20AC',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: AppColors.primary,
                  letterSpacing: -0.44,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // "Choisir" dark pill — D2 button style
              GestureDetector(
                onTap: onChoose,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.l10n.choose.toUpperCase(),
                    style: AppTextStyles.buttonSmall.copyWith(
                      color: AppColors.background,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Right sidebar — sticky booking card (cream-card, ink background)
// ---------------------------------------------------------------------------

class _BookingSidebar extends StatelessWidget {
  final CompanyDetailModel company;
  final String companyId;
  final VoidCallback onViewServices;

  const _BookingSidebar({
    required this.company,
    required this.companyId,
    required this.onViewServices,
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

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Decorative gold radial glow (top-right)
          Positioned(
            right: -60,
            top: 20,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.30),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Overline
              Text(
                context.l10n.bookOverline.toUpperCase(),
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.secondary,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Heading — translated + italic accent on the last segment
              RichText(
                text: TextSpan(
                  style: GoogleFonts.fraunces(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: AppColors.background,
                    height: 1.1,
                    letterSpacing: -0.56,
                  ),
                  children: [
                    TextSpan(text: context.l10n.bookSidebarTitle),
                    TextSpan(
                      text: context.l10n.bookSidebarTitleEm,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Contact block — address, phones
              DefaultTextStyle(
                style: AppTextStyles.body.copyWith(
                  color: AppColors.background.withValues(alpha: 0.78),
                  height: 1.7,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(company.address),
                    if (hasPhone)
                      GestureDetector(
                        onTap: () => _dialPhone(context, company.phone!),
                        child: Text(
                          company.phone!,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.secondary,
                            height: 1.7,
                          ),
                        ),
                      ),
                    if (hasPhoneSecondary)
                      GestureDetector(
                        onTap: () =>
                            _dialPhone(context, company.phoneSecondary!),
                        child: Text(
                          company.phoneSecondary!,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.secondary,
                            height: 1.7,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Divider
              Divider(
                color: AppColors.background.withValues(alpha: 0.12),
                height: 1,
              ),

              const SizedBox(height: 22),

              // Hint — why the CTA scrolls instead of navigating directly
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.secondary.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.bookSidebarHint,
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppColors.background.withValues(alpha: 0.75),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Gold CTA — scrolls to the services list.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onViewServices,
                  icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                  label: Text(
                    context.l10n.viewServices.toUpperCase(),
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 1.4,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

