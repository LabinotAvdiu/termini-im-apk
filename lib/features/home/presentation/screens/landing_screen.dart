import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/language_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/gender_filter.dart';
import '../providers/home_providers.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  GenderFilter _gender = GenderFilter.both;
  final TextEditingController _cityController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _onSearch() {
    ref.read(genderFilterProvider.notifier).state = _gender;
    ref.read(cityFilterProvider.notifier).state = _cityController.text.trim();
    ref.read(dateFilterProvider.notifier).state = _selectedDate;
    ref.read(authStateProvider.notifier).enterGuestMode();
    context.goNamed(RouteNames.home);
  }

  String _genderLabel(GenderFilter filter) {
    return switch (filter) {
      GenderFilter.men => context.l10n.filterMen,
      GenderFilter.women => context.l10n.filterWomen,
      GenderFilter.both => context.l10n.filterBoth,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroSection(
                  onLanguageTap: () => showLanguageSheet(context),
                ),
                _SearchFloatingCard(
                  gender: _gender,
                  cityController: _cityController,
                  selectedDate: _selectedDate,
                  genderLabel: _genderLabel,
                  onGenderChanged: (g) => setState(() => _gender = g),
                  onDateChanged: (d) => setState(() => _selectedDate = d),
                  onSearch: _onSearch,
                ),
                const SizedBox(height: AppSpacing.xl),
                _AuthLinks(),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero section — burgundy gradient with brand header and headline
// ---------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  final VoidCallback onLanguageTap;

  const _HeroSection({required this.onLanguageTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF511522),
            Color(0xFF7A2232),
            Color(0xFF9E3D4F),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Gold radial blob top-right
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFC89B47).withValues(alpha: 0.18),
                    const Color(0xFFC89B47).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar: brand + globe
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _BrandBadge(),
                      IconButton(
                        icon: const Icon(
                          Icons.language_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: onLanguageTap,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Serif headline
                  Text(
                    context.l10n.landingHeroLine1,
                    style: GoogleFonts.fraunces(
                      fontSize: 38,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: -0.95,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: context.l10n.landingHeroLine2,
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 38,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFFC89B47),
                            height: 1.0,
                          ),
                        ),
                        TextSpan(
                          text: '.',
                          style: GoogleFonts.fraunces(
                            fontSize: 38,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.l10n.landingHeroSubtitle,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
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
// Brand badge — "Termini im" top-left
// ---------------------------------------------------------------------------

class _BrandBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BrandLogo(variant: BrandLogoVariant.ivory, size: 44),
        const SizedBox(width: AppSpacing.sm),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Termini ',
                style: GoogleFonts.instrumentSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              TextSpan(
                text: 'im',
                style: GoogleFonts.instrumentSerif(
                  fontSize: 17,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFFC89B47),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Floating search card — overlaps hero with negative margin
// ---------------------------------------------------------------------------

class _SearchFloatingCard extends StatelessWidget {
  final GenderFilter gender;
  final TextEditingController cityController;
  final DateTime? selectedDate;
  final String Function(GenderFilter) genderLabel;
  final ValueChanged<GenderFilter> onGenderChanged;
  final ValueChanged<DateTime?> onDateChanged;
  final VoidCallback onSearch;

  const _SearchFloatingCard({
    required this.gender,
    required this.cityController,
    required this.selectedDate,
    required this.genderLabel,
    required this.onGenderChanged,
    required this.onDateChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF171311).withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Row: Ville
              _SearchRow(
                icon: Icons.location_on_outlined,
                label: context.l10n.city.toUpperCase(),
                child: TextField(
                  controller: cityController,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: context.l10n.filterCityHint,
                    hintStyle: AppTextStyles.body.copyWith(
                      color: AppColors.textHint,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
              // Row: Quand
              _SearchRow(
                icon: Icons.calendar_today_outlined,
                label: context.l10n.searchWhen.toUpperCase(),
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) onDateChanged(picked);
                  },
                  child: Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : context.l10n.filterDateLabel,
                    style: AppTextStyles.body.copyWith(
                      color: selectedDate != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
              // Row: Qui
              _SearchRow(
                icon: Icons.person_outline_rounded,
                label: context.l10n.searchWho.toUpperCase(),
                child: Row(
                  children: GenderFilter.values.map((filter) {
                    final isSelected = gender == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: GestureDetector(
                        onTap: () => onGenderChanged(filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.ivoryAlt,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            genderLabel(filter),
                            style: AppTextStyles.buttonSmall.copyWith(
                              color: isSelected
                                  ? AppColors.background
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // CTA button
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onSearch,
                    child: Text(
                      context.l10n.filterSearch.toUpperCase(),
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single row inside the search card
// ---------------------------------------------------------------------------

class _SearchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _SearchRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 15, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 46,
            child: Text(
              label,
              style: AppTextStyles.overline.copyWith(
                color: AppColors.textHint,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Auth links at the bottom — editorial two-button stack
// ---------------------------------------------------------------------------

class _AuthLinks extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          // Uppercase overline divider
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  context.l10n.orDivider.toUpperCase(),
                  style: AppTextStyles.overline,
                ),
              ),
              const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Primary: login — dark ink filled button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => context.pushNamed(RouteNames.login),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.background,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(
                context.l10n.login.toUpperCase(),
                style: AppTextStyles.button.copyWith(color: AppColors.background),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Ghost: signup
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => context.pushNamed(RouteNames.roleSelect),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.button.copyWith(color: AppColors.textHint),
                  children: [
                    TextSpan(text: '${context.l10n.noAccount} '),
                    TextSpan(
                      text: context.l10n.signupNow,
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
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
