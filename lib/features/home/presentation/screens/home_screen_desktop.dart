import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/auth_prompt_sheet.dart';
import '../../../../core/widgets/language_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/company_card_model.dart';
import '../../data/models/gender_filter.dart';
import '../providers/home_providers.dart';
import '../widgets/company_card.dart' show FavoriteBadge;
import '../widgets/complete_profile_banner.dart';
import '../widgets/diaspora_banner.dart';
import '../widgets/tomorrow_booking_banner.dart';
import '../../../company/presentation/widgets/salon_geocoding_banner.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';

/// Desktop (D1) editorial presentation for the home / search screen.
///
/// Ivory page, max-width 1360px centered. Sections:
///   1. Top brandbar
///   2. Large hero — left editorial lead + right image
///   3. Horizontal search bar (city, when, who) + dark "RECHERCHER" button
///   4. Results grid — 3-column salon cards
///
/// Stateless — reads providers via [ref]. Refresh callback comes from wrapper.
class HomeScreenDesktop extends ConsumerStatefulWidget {
  final Future<void> Function() onRefresh;

  const HomeScreenDesktop({super.key, required this.onRefresh});

  @override
  ConsumerState<HomeScreenDesktop> createState() => _HomeScreenDesktopState();
}

class _HomeScreenDesktopState extends ConsumerState<HomeScreenDesktop> {
  // Local search field state — mirrors provider values on submit
  final _cityController = TextEditingController();
  DateTime? _selectedDate;
  GenderFilter _gender = GenderFilter.both;

  @override
  void initState() {
    super.initState();
    // Sync text field from provider initial state
    _cityController.text = ref.read(searchQueryProvider);
    _selectedDate = ref.read(dateFilterProvider);
    _gender = ref.read(genderFilterProvider);
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _search() {
    // Unified fuzzy search: feeds the term into searchQueryProvider so the
    // backend matches it against name / address / city / employee names
    // via LIKE, instead of demanding an exact city match. The field is
    // still labelled "Ville" in the UI but acts as a general search.
    ref.read(searchQueryProvider.notifier).state = _cityController.text.trim();
    ref.read(dateFilterProvider.notifier).state = _selectedDate;
    ref.read(genderFilterProvider.notifier).state = _gender;
  }

  String _dateDisplayValue() {
    if (_selectedDate == null) return context.l10n.filterDateLabel;
    final d = _selectedDate!;
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final companyState = ref.watch(companyListProvider);
    final companies = companyState.companies;
    final isSearching = ref.watch(searchQueryProvider).isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Brandbar
            _DesktopBrandBar(onLanguageTap: () => showLanguageSheet(context)),

            // 2. Centered page content — max 1360px
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1360),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile completion nudge (gender / phone missing).
                    const CompleteProfileBanner(),

                    // Salon geocoding warning — owners whose salon has no
                    // Google address + no GPS won't be found in search.
                    const SalonGeocodingBanner(),

                    // C16 — Tomorrow booking reminder banner (self-gating)
                    const TomorrowBookingBanner(),

                    // E27 — Diaspora banner (Remote Config gate)
                    const DiasporaBanner(),

                    // Hero
                    _DesktopHero(),

                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: AppSpacing.sm,
                      ),
                      child: _DesktopSearchBar(
                        cityController: _cityController,
                        selectedDate: _selectedDate,
                        gender: _gender,
                        dateDisplayValue: _dateDisplayValue(),
                        onDateTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 60)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        onGenderChanged: (value) =>
                            setState(() => _gender = value),
                        onSearch: _search,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Results section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ResultsHeader(
                            count: companies.length,
                            isFiltered: isSearching,
                            query: ref.watch(searchQueryProvider),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          if (companyState.isLoading && companies.isEmpty)
                            _DesktopSkeletonGrid()
                          else if (companies.isEmpty)
                            _DesktopEmptyState()
                          else
                            _DesktopSalonGrid(companies: companies),
                        ],
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top brandbar
// ---------------------------------------------------------------------------

class _DesktopBrandBar extends ConsumerWidget {
  final VoidCallback onLanguageTap;

  const _DesktopBrandBar({required this.onLanguageTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuth = ref.watch(authStateProvider).isAuthenticated;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Row(
            children: [
              // Brand left
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Termini ',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        TextSpan(
                          text: 'im',
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Tagline centered
              Expanded(
                child: Center(
                  child: Text(
                    context.l10n.homeBrandTagline,
                    style: AppTextStyles.overline.copyWith(
                      color: AppColors.textHint,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),

              // Right actions
              Row(
                children: [
                  if (!isAuth) ...[
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: onLanguageTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusXl),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.language_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.l10n.language,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => showAuthPromptSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusXl),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: AppColors.background,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.l10n.login,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.background,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero — editorial split (left lead + right image)
// ---------------------------------------------------------------------------

class _DesktopHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left editorial lead — weight 1.2
          Expanded(
            flex: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Over-label
                Text(
                  context.l10n.homeHeroOverline.toUpperCase(),
                  style: AppTextStyles.overline.copyWith(
                    color: AppColors.textHint,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 14),

                // Headline — Fraunces display, 96px
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: context.l10n.homeHeroTitlePrefix,
                        style: GoogleFonts.fraunces(
                          fontSize: 64,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                          height: 0.95,
                          letterSpacing: -2.56,
                        ),
                      ),
                      TextSpan(
                        text: context.l10n.homeHeroTitleItalic,
                        style: GoogleFonts.instrumentSerif(
                          fontSize: 64,
                          fontStyle: FontStyle.italic,
                          color: AppColors.primary,
                          height: 0.95,
                          letterSpacing: -1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Sub-text
                Text(
                  context.l10n.homeHeroSubtitle,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 48),

          // Right image — weight 1
          Expanded(
            flex: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: AspectRatio(
                aspectRatio: 3 / 2,
                child: CachedNetworkImage(
                  imageUrl:
                      'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=800&q=80',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: AppColors.divider,
                    highlightColor: AppColors.background,
                    child: Container(color: AppColors.divider),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.ivoryAlt,
                    child: const Icon(
                      Icons.storefront_outlined,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop search bar — horizontal pill with 3 fields + dark go button
// ---------------------------------------------------------------------------

class _DesktopSearchBar extends StatelessWidget {
  final TextEditingController cityController;
  final DateTime? selectedDate;
  final GenderFilter gender;
  final String dateDisplayValue;
  final ValueChanged<GenderFilter> onGenderChanged;
  final VoidCallback onDateTap;
  final VoidCallback onSearch;

  const _DesktopSearchBar({
    required this.cityController,
    required this.selectedDate,
    required this.gender,
    required this.dateDisplayValue,
    required this.onGenderChanged,
    required this.onDateTap,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF171311).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Field: Où / City
          Expanded(
            child: _SearchField(
              label: context.l10n.city.toUpperCase(),
              showSeparator: true,
              child: TextField(
                controller: cityController,
                style: GoogleFonts.fraunces(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: context.l10n.filterCityHint,
                  hintStyle: GoogleFonts.fraunces(
                    fontSize: 16,
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),

          // Field: Quand / Date
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onDateTap,
                child: _SearchField(
                  label: context.l10n.searchWhen.toUpperCase(),
                  showSeparator: true,
                  child: Text(
                    dateDisplayValue,
                    style: GoogleFonts.fraunces(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: selectedDate != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Field: Qui / Gender — inline segmented chips
          Expanded(
            child: _SearchField(
              label: context.l10n.searchWho.toUpperCase(),
              showSeparator: false,
              child: _GenderSegmentedControl(
                selected: gender,
                onChanged: onGenderChanged,
              ),
            ),
          ),

          // Go button
          Padding(
            padding: const EdgeInsets.all(8),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.l10n.filterSearch.toUpperCase(),
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.background,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inline gender segmented control — three always-visible pill chips.
//
// Selected chip: ink fill + ivory label.
// Unselected chip: transparent, thin border; ivory-alt tint on hover.
// Icon + label side-by-side, compact so the search bar height is unchanged.
// ---------------------------------------------------------------------------

class _GenderSegmentedControl extends StatefulWidget {
  final GenderFilter selected;
  final ValueChanged<GenderFilter> onChanged;

  const _GenderSegmentedControl({
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_GenderSegmentedControl> createState() =>
      _GenderSegmentedControlState();
}

class _GenderSegmentedControlState extends State<_GenderSegmentedControl> {
  // Tracks which chip the pointer is currently over (null = none).
  GenderFilter? _hovered;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(
          context,
          value: GenderFilter.both,
          icon: Icons.groups_2_rounded,
          label: context.l10n.filterBoth,
        ),
        const SizedBox(width: 6),
        _chip(
          context,
          value: GenderFilter.men,
          icon: Icons.male_rounded,
          label: context.l10n.filterMen,
        ),
        const SizedBox(width: 6),
        _chip(
          context,
          value: GenderFilter.women,
          icon: Icons.female_rounded,
          label: context.l10n.filterWomen,
        ),
      ],
    );
  }

  Widget _chip(
    BuildContext context, {
    required GenderFilter value,
    required IconData icon,
    required String label,
  }) {
    final isSelected = widget.selected == value;
    final isHovered = _hovered == value && !isSelected;

    Color bgColor;
    Color fgColor;
    Color borderColor;

    if (isSelected) {
      bgColor = AppColors.textPrimary;
      fgColor = AppColors.background;
      borderColor = AppColors.textPrimary;
    } else if (isHovered) {
      bgColor = AppColors.ivoryAlt;
      fgColor = AppColors.textPrimary;
      borderColor = AppColors.border;
    } else {
      bgColor = Colors.transparent;
      fgColor = AppColors.textHint;
      borderColor = AppColors.border;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = value),
      onExit: (_) => setState(() => _hovered = null),
      child: GestureDetector(
        onTap: () => widget.onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: fgColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: fgColor,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool showSeparator;

  const _SearchField({
    required this.label,
    required this.child,
    required this.showSeparator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: showSeparator
          ? const BoxDecoration(
              border: Border(
                right: BorderSide(color: AppColors.border, width: 1),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.overline.copyWith(
              color: AppColors.textHint,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Results section header
// ---------------------------------------------------------------------------

class _ResultsHeader extends StatelessWidget {
  final int count;
  final bool isFiltered;
  final String query;

  const _ResultsHeader({
    required this.count,
    required this.isFiltered,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final plural = count > 1 ? 's' : '';
    final label = isFiltered
        ? context.l10n.resultsFound(count, plural)
        : context.l10n.salonsNearby(count, plural);

    final base = isFiltered
        ? context.l10n.homeResultsOverlineSearch
        : context.l10n.homeResultsOverline;
    final trimmedQuery = query.trim();
    final overline = trimmedQuery.isEmpty
        ? base
        : '$base · ${trimmedQuery.capitalize}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    overline.toUpperCase(),
                    style: AppTextStyles.overline.copyWith(
                      color: AppColors.textHint,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: label,
                          style: AppTextStyles.h2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              context.l10n.homeSortLabel,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Divider(height: 1, thickness: 1, color: AppColors.divider),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3-column salon grid
// ---------------------------------------------------------------------------

class _DesktopSalonGrid extends StatelessWidget {
  final List<CompanyCardModel> companies;

  const _DesktopSalonGrid({required this.companies});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Target ~300px min per card; fill 3 columns for desktop
        const crossAxisCount = 3;
        const spacing = 24.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final company in companies)
              SizedBox(
                width: (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                    crossAxisCount,
                child: _DesktopSalonCard(company: company),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop skeleton grid — 3 colonnes de SkeletonDesktopSalonCard
// ---------------------------------------------------------------------------

class _DesktopSkeletonGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 3;
        const spacing = 24.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (int i = 0; i < 6; i++)
              SizedBox(
                width: cardWidth,
                child: const SkeletonDesktopSalonCard(),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// D1 salon card — image header + body + footer
// ---------------------------------------------------------------------------

class _DesktopSalonCard extends ConsumerStatefulWidget {
  final CompanyCardModel company;

  const _DesktopSalonCard({required this.company});

  @override
  ConsumerState<_DesktopSalonCard> createState() => _DesktopSalonCardState();
}

class _DesktopSalonCardState extends ConsumerState<_DesktopSalonCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final company = widget.company;
    // Combine morning + afternoon slots, take first 4
    // Backend already trims to 4 day entries and collapses morning/afternoon
    // into a single `available` flag — just read `slots` as-is.
    final allSlots = company.slots;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.pushNamed(
          RouteNames.companyDetail,
          pathParameters: {'id': company.id},
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          transform: _hovered
              ? (Matrix4.identity()..translateByDouble(0.0, -4.0, 0.0, 1.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF171311).withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFF171311).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image header — 16:10 aspect ratio
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'company-photo-${company.id}',
                        child: CachedNetworkImage(
                          imageUrl: company.photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: AppColors.divider,
                            highlightColor: AppColors.background,
                            child: Container(color: AppColors.divider),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.ivoryAlt,
                            child: Center(
                              child: Text(
                                company.name.isNotEmpty
                                    ? company.name[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.fraunces(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Rating + review count badges — hidden when the salon
                      // has no reviews yet (nothing useful to show).
                      if (company.reviewCount > 0) ...[
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '★ ${company.rating.toStringAsFixed(1)}',
                              style: AppTextStyles.overline.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              context.l10n.reviews(company.reviewCount),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.background,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                      // Favorite badge — only shown when the company is
                      // already in the user's favorites.
                      if (company.isFavorite)
                        Positioned(
                          top: 14,
                          right: 14,
                          child: FavoriteBadge(
                            companyId: company.id,
                            companyName: company.name,
                            ref: ref,
                          ),
                        ),
                    ],
                  ),
                ),

                // Card body
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        company.name.titleCase,
                        style: GoogleFonts.fraunces(
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                          height: 1.1,
                          letterSpacing: -0.33,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Address
                      Text(
                        company.address,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 18),

                      // Slot chips — always reserves a single-row height
                      // (32px ≈ chip size) so salons with no upcoming slots
                      // don't make their card shorter than the others.
                      SizedBox(
                        height: 32,
                        child: allSlots.isEmpty
                            ? const SizedBox()
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: allSlots
                                    .map(
                                      (slot) => _DesktopSlotChip(slot: slot),
                                    )
                                    .toList(),
                              ),
                      ),

                      const SizedBox(height: 18),

                      // Footer — "Voir la fiche" + book CTA
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.divider,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Text(
                              '${context.l10n.moreInfo} →',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => context.pushNamed(
                                RouteNames.companyDetail,
                                pathParameters: {'id': company.id},
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  context.l10n.bookAppointment,
                                  style: AppTextStyles.buttonSmall.copyWith(
                                    color: AppColors.background,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop slot chip
// ---------------------------------------------------------------------------

class _DesktopSlotChip extends ConsumerWidget {
  final DaySlot slot;

  const _DesktopSlotChip({required this.slot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searched = ref.watch(dateFilterProvider);
    final isTarget = searched != null &&
        searched.year == slot.date.year &&
        searched.month == slot.date.month &&
        searched.day == slot.date.day;

    // Target day gets the bordeaux hero treatment. Same rules as mobile —
    // see company_card._UnifiedSlotChip for the reasoning.
    final Color bg;
    final Color borderColor;
    final Color textColor;

    if (isTarget && slot.available) {
      bg = AppColors.primary;
      borderColor = AppColors.primary;
      textColor = AppColors.background;
    } else if (isTarget) {
      bg = AppColors.background;
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
    } else if (slot.available) {
      bg = AppColors.textPrimary;
      borderColor = AppColors.textPrimary;
      textColor = AppColors.background;
    } else {
      bg = AppColors.background;
      borderColor = AppColors.border;
      textColor = AppColors.textHint;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderColor, width: isTarget ? 1.5 : 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${slot.date.day.toString().padLeft(2, '0')}/'
        '${slot.date.month.toString().padLeft(2, '0')}',
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state for desktop
// ---------------------------------------------------------------------------

class _DesktopEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
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
            style: AppTextStyles.h2,
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
