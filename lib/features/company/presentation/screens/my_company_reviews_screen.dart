import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../reviews/data/models/review_model.dart';
import '../../../reviews/presentation/providers/review_provider.dart';

class MyCompanyReviewsScreen extends ConsumerWidget {
  const MyCompanyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myCompanyReviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar.standard(title: context.l10n.reviewsReceived),
      body: state.isLoading && state.reviews.isEmpty
          // Skeleton loader conforme §2.7 — remplace le CircularProgressIndicator
          // plein écran qui créait un flash de layout au chargement.
          ? const AppReviewsLoadingSkeleton()
          : state.error != null && state.reviews.isEmpty
              // État d'erreur normé §2.8 — était absent précédemment.
              ? Center(
                  child: AppErrorState(
                    message: state.error!,
                    onRetry: () =>
                        ref.read(myCompanyReviewsProvider.notifier).load(),
                  ),
                )
              : state.reviews.isEmpty && !state.isLoading
                  // État vide normé §2.6 — remplace le simple Text centré sans icône.
                  ? Center(
                      child: AppEmptyState(
                        icon: Icons.star_outline_rounded,
                        title: context.l10n.reviewsEmpty,
                        variant: AppEmptyStateVariant.neutral,
                      ),
                    )
                  : RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: () =>
                      ref.read(myCompanyReviewsProvider.notifier).load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    itemCount: state.reviews.length +
                        (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.reviews.length) {
                        // Load more trigger
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref
                              .read(myCompanyReviewsProvider.notifier)
                              .loadMore();
                        });
                        return const Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        );
                      }
                      final review = state.reviews[index];
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _OwnerReviewCard(review: review),
                      );
                    },
                  ),
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Review card with hide/unhide actions
// ---------------------------------------------------------------------------

class _OwnerReviewCard extends ConsumerWidget {
  final ReviewModel review;

  const _OwnerReviewCard({required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHidden = review.isHidden;
    final textOpacity = isHidden ? 0.45 : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: isHidden
            ? AppColors.surface.withValues(alpha: 0.6)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isHidden
              ? AppColors.divider.withValues(alpha: 0.5)
              : AppColors.divider,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Avatar
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
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.textPrimary
                            .withValues(alpha: textOpacity),
                      ),
                    ),
                    Text(
                      _relativeDate(context, review.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint
                            .withValues(alpha: textOpacity),
                      ),
                    ),
                  ],
                ),
              ),

              // Stars
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

              const SizedBox(width: AppSpacing.sm),

              // Hide/unhide button
              if (isHidden)
                IconButton(
                  icon: const Icon(Icons.visibility_rounded, size: 20),
                  color: AppColors.textSecondary,
                  tooltip: context.l10n.reviewHidden,
                  onPressed: () => _onUnhide(context, ref),
                )
              else
                IconButton(
                  icon: const Icon(Icons.visibility_off_outlined, size: 20),
                  color: AppColors.textSecondary,
                  tooltip: context.l10n.reviewHideTitle,
                  onPressed: () => _onHide(context, ref),
                ),
            ],
          ),

          // Comment
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              review.comment!,
              style: AppTextStyles.body.copyWith(
                color:
                    AppColors.textSecondary.withValues(alpha: textOpacity),
              ),
            ),
          ],

          // Hidden badge
          if (isHidden) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.textHint.withValues(alpha: 0.3)),
              ),
              child: Text(
                context.l10n.reviewHidden,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onHide(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(
          context.l10n.reviewHideTitle,
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: reasonController,
              label: context.l10n.reviewHideReason,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel,
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.confirm,
                style: const TextStyle(color: AppColors.surface)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = reasonController.text.trim().isEmpty
          ? null
          : reasonController.text.trim();
      final ok = await ref
          .read(myCompanyReviewsProvider.notifier)
          .hideReview(review.id, reason: reason);
      if (!ok && context.mounted) {
        context.showSnackBar(context.l10n.actionFailed, isError: true);
      }
    }
    reasonController.dispose();
  }

  Future<void> _onUnhide(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(myCompanyReviewsProvider.notifier)
        .unhideReview(review.id);
    if (!ok && context.mounted) {
      context.showSnackBar(context.l10n.actionFailed, isError: true);
    }
  }

  String _relativeDate(BuildContext context, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    if (diff.inDays < 30) return 'Il y a ${diff.inDays ~/ 7} sem.';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
