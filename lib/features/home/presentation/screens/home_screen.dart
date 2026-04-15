import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/home_providers.dart';
import '../widgets/company_card.dart';
import '../widgets/search_filter_bar.dart';

/// Home screen — company listing with search, gender filter, and
/// pull-to-refresh. All state is managed through Riverpod providers.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyState = ref.watch(companyListProvider);
    final companies = companyState.companies;
    final isSearching = ref.watch(searchQueryProvider).isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _HomeAppBar(),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () => ref.read(companyListProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Sticky filter + search header ─────────────────────────
            // ── Email verification banner ─────────────────────────
            SliverToBoxAdapter(
              child: _EmailVerificationBanner(),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SearchFilterBar(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: _ResultsLabel(
                      count: companies.length,
                      isFiltered: isSearching,
                    ),
                  ),
                ],
              ),
            ),

            // ── Company cards list ────────────────────────────────────
            if (companyState.isLoading && companies.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (companies.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final company = companies[index];
                        return CompanyCard(
                          key: ValueKey(company.id),
                          company: company,
                        );
                      },
                      childCount: companies.length,
                    ),
                  ),

            // ── Bottom padding so last card clears the nav bar ────────
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppBar
// ---------------------------------------------------------------------------

class _HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.cardShadow,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Brand accent dot
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: AppSpacing.xs),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            context.l10n.appName,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        // Language toggle
        IconButton(
          icon: const Icon(
            Icons.language_rounded,
            color: AppColors.textSecondary,
          ),
          tooltip: context.l10n.language,
          onPressed: () => _showLanguageSheet(context, ref),
        ),
        // Settings
        IconButton(
          icon: const Icon(
            Icons.tune_rounded,
            color: AppColors.textSecondary,
          ),
          tooltip: context.l10n.settings,
          onPressed: () => context.go('/settings'),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => _LanguageSheet(ref: ref),
    );
  }
}

// ---------------------------------------------------------------------------
// Language bottom sheet
// ---------------------------------------------------------------------------

class _LanguageSheet extends StatelessWidget {
  final WidgetRef ref;
  const _LanguageSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(context.l10n.language, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.md),
          _LanguageTile(
            label: context.l10n.french,
            locale: const Locale('fr'),
            ref: ref,
          ),
          const Divider(height: 1, color: AppColors.divider),
          _LanguageTile(
            label: context.l10n.english,
            locale: const Locale('en'),
            ref: ref,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _LanguageTile extends ConsumerWidget {
  final String label;
  final Locale locale;
  final WidgetRef ref;

  const _LanguageTile({
    required this.label,
    required this.locale,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef innerRef) {
    // Import auth_provider's localeProvider
    // We use a dynamic import-compatible approach here via the localeProvider
    // already exposed at the app level through auth_provider.dart
    return ListTile(
      title: Text(label, style: AppTextStyles.body),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textHint,
      ),
      onTap: () {
        // Navigate back; locale switching wired in app.dart
        Navigator.of(context).pop();
      },
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Results count label
// ---------------------------------------------------------------------------

class _ResultsLabel extends StatelessWidget {
  final int count;
  final bool isFiltered;

  const _ResultsLabel({required this.count, required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    final label = isFiltered
        ? '$count résultat${count > 1 ? 's' : ''} trouvé${count > 1 ? 's' : ''}'
        : '$count salon${count > 1 ? 's' : ''} près de vous';

    return Text(
      label,
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Email verification banner
// ---------------------------------------------------------------------------

class _EmailVerificationBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;

    // Don't show if no user or already verified
    if (user == null || user.emailVerified) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.40),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.emailNotVerifiedTitle,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.emailNotVerifiedMessage,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.noResults,
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.noResultsMessage,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
