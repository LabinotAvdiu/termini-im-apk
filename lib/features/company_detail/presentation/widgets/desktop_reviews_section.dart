import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../reviews/data/models/review_model.dart';
import '../../../reviews/presentation/providers/review_provider.dart';

/// Reviews section for the desktop company detail page.
///
/// Editorial header (serif title + italic average rating) followed by a
/// 2-column grid capped at 6 cards. When the company has more than 6 reviews,
/// a "See all" link opens a dialog with paginated infinite scroll.
class DesktopReviewsSection extends ConsumerWidget {
  final String companyId;
  const DesktopReviewsSection({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companyReviewsProvider(companyId));
    final reviews = state.reviews;

    // Hide the entire block when the salon has zero reviews. Keeps the
    // services section from being followed by an empty placeholder.
    if (!state.isLoading && state.total == 0) {
      return const SizedBox.shrink();
    }

    if (state.isLoading && reviews.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      );
    }

    final avg = reviews.isEmpty
        ? 0.0
        : reviews.fold<int>(0, (s, r) => s + r.rating) / reviews.length;

    final allWithoutComment = reviews.isNotEmpty &&
        reviews.every((r) => (r.comment?.trim().isEmpty ?? true));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header — "Nos avis" + average rating italic + count + see-all link
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.56,
                ),
                children: [
                  TextSpan(text: '${context.l10n.reviewsTitle} '),
                  if (state.total > 0)
                    TextSpan(
                      text: '\u2605 ${avg.toStringAsFixed(1)}',
                      style: GoogleFonts.fraunces(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: AppColors.secondary,
                        letterSpacing: -0.56,
                      ),
                    ),
                ],
              ),
            ),
            if (state.total > 0) ...[
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  context.l10n.reviews(state.total),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (state.total > 6)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () =>
                      _showAllReviewsModal(context, ref, companyId),
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
        ),
        const SizedBox(height: 24),

        if (allWithoutComment)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 18, color: AppColors.secondaryDark),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.l10n.reviewsOnlyRatings,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.secondaryDark,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (ctx, constraints) {
              const gap = 20.0;
              final cardW = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: reviews
                    .take(6)
                    .map((r) => SizedBox(
                          width: cardW,
                          child: _DesktopReviewCard(review: r),
                        ))
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  void _showAllReviewsModal(
      BuildContext context, WidgetRef ref, String companyId) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.background,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Consumer(
              builder: (context, ref, _) {
                final state = ref.watch(companyReviewsProvider(companyId));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.reviewsTitle,
                            style: GoogleFonts.fraunces(
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          color: AppColors.textHint,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n is ScrollEndNotification &&
                              n.metrics.pixels >=
                                  n.metrics.maxScrollExtent - 200) {
                            ref
                                .read(companyReviewsProvider(companyId)
                                    .notifier)
                                .loadMore();
                          }
                          return false;
                        },
                        child: ListView.separated(
                          itemCount: state.reviews.length +
                              (state.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (_, i) {
                            if (i == state.reviews.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    color: AppColors.secondary,
                                  ),
                                ),
                              );
                            }
                            return _DesktopReviewCard(
                                review: state.reviews[i]);
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _DesktopReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rel = _relativeDate(review.createdAt);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color: AppColors.divider.withValues(alpha: 0.7), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                backgroundImage: review.authorProfileImageUrl != null
                    ? NetworkImage(review.authorProfileImageUrl!)
                    : null,
                child: review.authorProfileImageUrl == null
                    ? Text(
                        review.authorFirstName.isNotEmpty
                            ? review.authorFirstName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorDisplay,
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rel,
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
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()} mo';
    if (diff.inDays > 0) return '${diff.inDays}j';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min';
    return 'maintenant';
  }
}
