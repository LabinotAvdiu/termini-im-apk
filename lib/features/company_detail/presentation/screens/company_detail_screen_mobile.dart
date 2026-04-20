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
import '../../../../core/widgets/language_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../favorites/presentation/providers/favorite_provider.dart';
import '../../../favorites/presentation/widgets/remove_favorite_dialog.dart';
import '../../../sharing/presentation/widgets/share_button.dart';
import '../../../reviews/data/models/review_model.dart';
import '../../../reviews/presentation/providers/review_provider.dart';
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
  final String? preselectedEmployeeId;

  const CompanyDetailScreenMobile({
    super.key,
    required this.companyId,
    this.preselectedEmployeeId,
  });

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
              // Guest-only: small language pill + login CTA. Shown inline so
              // a recipient of a shared link can switch language / auth
              // without leaving the salon page.
              const _MobileGuestActions(),
              ShareIconButton(
                companyId: companyId,
                salonName: company.name,
                bookingMode: company.bookingMode,
                // Pass user ids so matching against authState.user.id works —
                // pivot ids (EmployeeModel.id) are unrelated to user ids.
                employeeIds: {
                  for (final e in company.employees) e.userId,
                },
                showFreshBadge: true,
              ),
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
                    heroTag: 'company-photo-$companyId',
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
                  preselectedEmployeeId: preselectedEmployeeId,
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
  final String? preselectedEmployeeId;

  const _MobileInfoSheet({
    required this.company,
    required this.companyId,
    this.preselectedEmployeeId,
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

    // Resolve the preselected employee (from a shared link) so we can
    // filter services to what they're qualified to do. An empty
    // `serviceIds` means "can do anything" — no filter is applied.
    // Match by `userId` — the pivot `id` would collide across salons.
    final preselectedEmployee = preselectedEmployeeId == null
        ? null
        : company.employees
            .where((e) => e.userId == preselectedEmployeeId)
            .cast<EmployeeModel?>()
            .firstWhere((e) => true, orElse: () => null);

    final visibleCategories = preselectedEmployee == null ||
            preselectedEmployee.serviceIds.isEmpty
        ? company.categories
        : company.categories
            .map((c) => c.copyWith(
                  services: c.services
                      .where((s) =>
                          preselectedEmployee.serviceIds.contains(s.id))
                      .toList(),
                ))
            .where((c) => c.services.isNotEmpty)
            .toList();

    // Total services count (after filter)
    final totalServices = visibleCategories.fold<int>(
        0, (sum, c) => sum + c.services.length);

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

          // ── Service categories (filtered by preselected employee) ────────
          // No visible banner — the filter happens silently so the
          // recipient experiences the salon page as anyone else would.
          ...visibleCategories.map(
            (cat) => ServiceCategorySection(
              category: cat,
              onServiceChosen: (service) {
                context.goNamed(
                  RouteNames.booking,
                  pathParameters: {'id': companyId},
                  queryParameters: {
                    'serviceId': service.id,
                    if (preselectedEmployeeId != null &&
                        preselectedEmployeeId!.isNotEmpty)
                      'employee': preselectedEmployeeId!,
                  },
                );
              },
            ),
          ),

          // ── Reviews section — after services ─────────────────────────────
          _ReviewsSection(companyId: companyId),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats strip — rating / reviews / services, bordered top+bottom
// ---------------------------------------------------------------------------

/// Guest-only inline actions in the mobile SliverAppBar — a tiny language
/// pill and a login pill. Invisible to authenticated users.
class _MobileGuestActions extends ConsumerWidget {
  const _MobileGuestActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuth = ref.watch(
      authStateProvider.select((s) => s.isAuthenticated),
    );
    if (isAuth) return const SizedBox.shrink();

    final lang = ref.watch(localeProvider).languageCode.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Language pill — 3-letter uppercase code on ivory bg
          Material(
            color: AppColors.background.withValues(alpha: 0.92),
            shape: StadiumBorder(
              side: BorderSide(
                color: AppColors.textPrimary.withValues(alpha: 0.08),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => showLanguageSheet(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      lang,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Login pill — primary filled
          Material(
            color: AppColors.primary,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                final returnTo = GoRouterState.of(context).uri.toString();
                context.goNamed(
                  RouteNames.login,
                  queryParameters: {'returnTo': returnTo},
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: AppColors.background,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.login,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.background,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

// ---------------------------------------------------------------------------
// Feature 3 — Reviews section on company detail (mobile)
// ---------------------------------------------------------------------------

class _ReviewsSection extends ConsumerWidget {
  final String companyId;

  const _ReviewsSection({required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companyReviewsProvider(companyId));

    // Nothing to show at all — hide the whole block so the services section
    // is not followed by an "empty" placeholder.
    if (!state.isLoading && state.total == 0) {
      return const SizedBox.shrink();
    }

    // All visible reviews are stars-only (no written comment). Swap the
    // carousel for a concise explanatory note.
    final allWithoutComment = state.reviews.isNotEmpty &&
        state.reviews.every((r) => (r.comment?.trim().isEmpty ?? true));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                Text(
                  context.l10n.reviewsTitle,
                  style: AppTextStyles.h2,
                ),
                const SizedBox(width: AppSpacing.sm),
                if (state.total > 0) ...[
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${state.total} avis',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.secondary,
                ),
              ),
            )
          else if (allWithoutComment)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.secondaryDark),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        context.l10n.reviewsOnlyRatings,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondaryDark,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Horizontal carousel — first 4 reviews
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 20),
                itemCount: state.reviews.take(4).length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) =>
                    _ReviewCard(review: state.reviews[i]),
              ),
            ),
            if (state.total > 4) ...[
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _showAllReviews(context, ref),
                  child: Text(
                    context.l10n.reviewsSeeAll(state.total),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.lg),
          const Padding(
            padding: EdgeInsets.only(right: 20),
            child: Divider(color: AppColors.divider),
          ),
        ],
      ),
    );
  }

  void _showAllReviews(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AllReviewsSheet(
        companyId: companyId,
      ),
    );
  }
}

// Compact review card for horizontal list
class _ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: review.authorProfileImageUrl != null
                    ? NetworkImage(review.authorProfileImageUrl!)
                    : null,
                child: review.authorProfileImageUrl == null
                    ? Text(
                        review.authorFirstName.isNotEmpty
                            ? review.authorFirstName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorDisplay,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 12,
                          color: i < review.rating
                              ? AppColors.secondary
                              : AppColors.divider,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (review.comment != null && review.comment!.isNotEmpty)
            Expanded(
              child: Text(
                review.comment!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

// Full reviews bottom sheet
class _AllReviewsSheet extends ConsumerWidget {
  final String companyId;

  const _AllReviewsSheet({required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companyReviewsProvider(companyId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  context.l10n.reviewsTitle,
                  style: AppTextStyles.h3,
                ),
                const Spacer(),
                Text(
                  '${state.total} avis',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              itemCount:
                  state.reviews.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= state.reviews.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref
                        .read(companyReviewsProvider(companyId).notifier)
                        .loadMore();
                  });
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  );
                }
                final review = state.reviews[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _FullReviewCard(review: review),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FullReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _FullReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: review.authorProfileImageUrl != null
                    ? NetworkImage(review.authorProfileImageUrl!)
                    : null,
                child: review.authorProfileImageUrl == null
                    ? Text(
                        review.authorFirstName.isNotEmpty
                            ? review.authorFirstName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorDisplay,
                      style: AppTextStyles.subtitle,
                    ),
                    Text(
                      _relative(review.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: i < review.rating
                        ? AppColors.secondary
                        : AppColors.divider,
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              review.comment!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    if (diff.inDays < 30) return 'Il y a ${diff.inDays ~/ 7} sem.';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ---------------------------------------------------------------------------

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
