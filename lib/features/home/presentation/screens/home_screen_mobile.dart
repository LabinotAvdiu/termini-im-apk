import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/company_card_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/auth_prompt_sheet.dart';
import '../../../../core/widgets/language_sheet.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';
import '../../../appointments/presentation/widgets/upcoming_appointment_banner.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../company/presentation/widgets/salon_geocoding_banner.dart';
import '../providers/home_providers.dart';
import '../widgets/company_card.dart';
import '../widgets/complete_profile_banner.dart';
import '../widgets/diaspora_banner.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/tomorrow_booking_banner.dart';

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
    final companies = companyState.companies.expandFavoritesDualEntry();
    final isSearching = ref.watch(searchQueryProvider).isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _HomeAppBar(),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Profile completion nudge (gender / phone missing).
            const SliverToBoxAdapter(child: CompleteProfileBanner()),

            // Salon geocoding warning — shown to owners whose salon has no
            // Google address + no GPS (can't be ranked in proximity search).
            const SliverToBoxAdapter(child: SalonGeocodingBanner()),

            // C16 — Tomorrow booking reminder banner (self-gating)
            const SliverToBoxAdapter(child: TomorrowBookingBanner()),

            // E27 — Diaspora banner (Remote Config gate + locale gate + session dismiss)
            const SliverToBoxAdapter(child: DiasporaBanner()),

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
                      // Suffix the key with index because the dual-entry
                      // expansion produces 2 cards sharing the same id.
                      key: ValueKey('${companies[index].id}-$index'),
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
// AppBar home — utilise AppTopBar.shell avec trailing adapté au contexte.
// ---------------------------------------------------------------------------

/// AppBar de la home (shell + guest).
///
/// Authentifié : wordmark seul (les actions bell/avatar sont dans le shell).
/// Guest : wordmark + icône langue + icône connexion.
class _HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(
      authStateProvider.select((s) => s.isAuthenticated),
    );

    return AppTopBar.shell(
      trailing: isAuthenticated
          ? null
          : [
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
