import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/language_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/gender_filter.dart';
import '../providers/home_providers.dart';

/// Full-screen landing page — the very first screen every visitor sees.
/// Guests can search directly; authenticated users are redirected from here
/// by the router to /home.
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
      begin: const Offset(0, 0.08),
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
    // Push filter values into Riverpod providers before navigating.
    ref.read(genderFilterProvider.notifier).state = _gender;
    ref.read(cityFilterProvider.notifier).state = _cityController.text.trim();
    ref.read(dateFilterProvider.notifier).state = _selectedDate;

    // Enter guest mode so the router allows /home access.
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
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ──────────────────────────────────────
          const _GradientBackground(),

          // ── Decorative blurred circles ───────────────────────────────
          const Positioned.fill(
            child: IgnorePointer(child: _DecorativeCircles()),
          ),

          // ── Scrollable content ───────────────────────────────────────
          SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * 0.06),

                          // Brand logo + name
                          _BrandHeader(),

                          SizedBox(height: AppSpacing.sm),

                          // Tagline
                          Text(
                            context.l10n.findYourSalon,
                            style: AppTextStyles.subtitle.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: AppSpacing.xl),

                          // Search card
                          _SearchCard(
                            gender: _gender,
                            cityController: _cityController,
                            selectedDate: _selectedDate,
                            genderLabel: _genderLabel,
                            onGenderChanged: (g) =>
                                setState(() => _gender = g),
                            onDateChanged: (d) =>
                                setState(() => _selectedDate = d),
                            onSearch: _onSearch,
                          ),

                          SizedBox(height: AppSpacing.xl),

                          // Auth links at the bottom
                          _AuthLinks(),

                          SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ),

                // Globe language toggle — placed last so it stays on top of scroll view
                Positioned(
                  top: 0,
                  right: AppSpacing.sm,
                  child: IconButton(
                    icon: const Icon(
                      Icons.language_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: context.l10n.language,
                    onPressed: () => showLanguageSheet(context),
                  ),
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
// Gradient background
// ---------------------------------------------------------------------------

class _GradientBackground extends StatelessWidget {
  const _GradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A42E8), // primaryDark
            Color(0xFF6C63FF), // primary
            Color(0xFF9B59B6), // mid-purple
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Decorative blurred circles (glassmorphism depth effect)
// ---------------------------------------------------------------------------

class _DecorativeCircles extends StatelessWidget {
  const _DecorativeCircles();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Top-right large circle
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ),
        // Bottom-left medium circle
        Positioned(
          bottom: 60,
          left: -80,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        // Centre accent circle
        Positioned(
          top: 180,
          right: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Brand header: logo circle + app name
// ---------------------------------------------------------------------------

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo container
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.content_cut_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Takimi IM',
          style: AppTextStyles.h1.copyWith(
            color: Colors.white,
            letterSpacing: -0.5,
            fontSize: 32,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Search card — white glassmorphism card containing all filter fields
// ---------------------------------------------------------------------------

class _SearchCard extends StatelessWidget {
  final GenderFilter gender;
  final TextEditingController cityController;
  final DateTime? selectedDate;
  final String Function(GenderFilter) genderLabel;
  final ValueChanged<GenderFilter> onGenderChanged;
  final ValueChanged<DateTime?> onDateChanged;
  final VoidCallback onSearch;

  const _SearchCard({
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gender pills
            _SectionHeader(
              icon: Icons.person_outline_rounded,
              label: context.l10n.filterGenderLabel,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: GenderFilter.values.map((filter) {
                final isSelected = gender == filter;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: filter != GenderFilter.both ? AppSpacing.sm : 0,
                    ),
                    child: _GenderPill(
                      label: genderLabel(filter),
                      isSelected: isSelected,
                      onTap: () => onGenderChanged(filter),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.md),

            // City/Salon text field
            _SectionHeader(
              icon: Icons.location_on_outlined,
              label: context.l10n.filterCitySalonLabel,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: cityController,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: context.l10n.filterCityHint,
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.textHint),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textHint,
                  size: 20,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm + 2,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Search CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_rounded, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      context.l10n.filterSearch,
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
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
// Section header inside card
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Gender pill button
// ---------------------------------------------------------------------------

class _GenderPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact date selector for the landing card
// ---------------------------------------------------------------------------
// Bottom auth links — "Se connecter" / "S'inscrire"
// ---------------------------------------------------------------------------

class _AuthLinks extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Divider with "ou"
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                context.l10n.orDivider,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // "Se connecter" button (outlined, white)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => context.goNamed(RouteNames.login),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Text(
              context.l10n.login,
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // "S'inscrire" text button
        TextButton(
          onPressed: () => context.goNamed(RouteNames.roleSelect),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.body.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
              ),
              children: [
                TextSpan(text: '${context.l10n.noAccount} '),
                TextSpan(
                  text: context.l10n.signupNow,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
