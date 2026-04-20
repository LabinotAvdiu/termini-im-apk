import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/auth_prompt_sheet.dart';
import '../../../../core/widgets/language_sheet.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';
import '../../../appointments/presentation/widgets/upcoming_appointment_banner.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../company/presentation/widgets/salon_geocoding_banner.dart';
import '../providers/home_providers.dart';
import '../widgets/company_card.dart';
import '../widgets/complete_profile_banner.dart';
import '../widgets/search_filter_bar.dart';

/// Mobile presentation for the home / search screen (M1 editorial design).
///
/// Stateless — reads providers directly via [ref]. All business logic
/// (refresh, load) stays in the [HomeScreen] thin wrapper.
class HomeScreenMobile extends ConsumerWidget {
  /// Called when the user triggers pull-to-refresh.
  final Future<void> Function() onRefresh;

  const HomeScreenMobile({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyState = ref.watch(companyListProvider);
    final companies = companyState.companies;
    final isSearching = ref.watch(searchQueryProvider).isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _MobileAppBar(),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Email verification banner
            SliverToBoxAdapter(child: _EmailVerificationBanner()),

            // Profile completion nudge (gender / phone missing).
            const SliverToBoxAdapter(child: CompleteProfileBanner()),

            // Salon geocoding warning — shown to owners whose salon has no
            // Google address + no GPS (can't be ranked in proximity search).
            const SliverToBoxAdapter(child: SalonGeocodingBanner()),

            // Feature 2 — Upcoming appointment reminder banner (auth users only)
            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, _) {
                  final isAuth = ref.watch(
                    authStateProvider.select((s) => s.isAuthenticated),
                  );
                  if (!isAuth) return const SizedBox.shrink();
                  return const UpcomingAppointmentBanner();
                },
              ),
            ),

            // Sticky-ish filter bar + results label
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

            // Company cards list
            if (companyState.isLoading && companies.isEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    child: const SkeletonCompanyCard(
                      key: ValueKey('skeleton'),
                    ),
                  ),
                  childCount: 5,
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
                  (context, index) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    child: CompanyCard(
                      key: ValueKey(companies[index].id),
                      company: companies[index],
                    ),
                  ),
                  childCount: companies.length,
                ),
              ),

            // Bottom padding so last card clears the nav bar
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

class _MobileAppBar extends ConsumerWidget implements PreferredSizeWidget {
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
            'Termini im',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        if (!ref.watch(authStateProvider).isAuthenticated) ...[
          IconButton(
            icon: const Icon(
              Icons.language_rounded,
              color: AppColors.textSecondary,
            ),
            tooltip: context.l10n.language,
            onPressed: () => showLanguageSheet(context),
          ),
          IconButton(
            icon: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primary,
            ),
            tooltip: context.l10n.login,
            onPressed: () => showAuthPromptSheet(context),
          ),
        ],
        const SizedBox(width: AppSpacing.xs),
      ],
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
    final plural = count > 1 ? 's' : '';
    final label = isFiltered
        ? context.l10n.resultsFound(count, plural)
        : context.l10n.salonsNearby(count, plural);

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

    if (user == null || user.emailVerified) return const SizedBox.shrink();

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
