import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../providers/auth_provider.dart';
import '../providers/company_setup_draft_provider.dart';
import '../widgets/booking_mode_picker.dart';

/// Step 2 of the owner onboarding (social signup): lets the owner choose the
/// booking mode (individual vs capacity). Reads [companySetupDraftProvider]
/// for the salon info gathered in Step 1. On "Valider", calls
/// [completeCompanySignup].
///
/// Guard: if the draft is null (e.g. deep-link or refresh), the GoRouter
/// redirect in [app_router.dart] will push back to [RouteNames.companySetup].
class CompanyModeScreen extends ConsumerStatefulWidget {
  const CompanyModeScreen({super.key});

  @override
  ConsumerState<CompanyModeScreen> createState() => _CompanyModeScreenState();
}

class _CompanyModeScreenState extends ConsumerState<CompanyModeScreen> {
  String _bookingMode = kEmployeeBased;

  Future<void> _submit() async {
    final draft = ref.read(companySetupDraftProvider);
    if (draft == null) {
      // Shouldn't happen (router guard), but be safe.
      context.goNamed(RouteNames.companySetup);
      return;
    }

    final ok =
        await ref.read(authStateProvider.notifier).completeCompanySignup(
              companyName: draft.name,
              address: draft.address,
              companyGender: draft.companyGender,
              city: draft.city.isEmpty ? null : draft.city,
              phone: draft.phone,
              bookingMode: _bookingMode,
              latitude: draft.latitude,
              longitude: draft.longitude,
            );

    if (!mounted) return;
    if (!ok) {
      final error = ref.read(authStateProvider).error;
      if (error != null) context.showErrorSnackBar(error);
    } else {
      // Clear the draft once the salon is created.
      ref.read(companySetupDraftProvider.notifier).clear();
    }
    // Router redirect watches needsCompanySetup + isAuthenticated and will
    // route to /home on success.
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.companySetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isLoading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar.standard(
        title: l.companyModeHeadline,
        onBack: _goBack,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),

                // Step indicator
                _StepIndicator(current: 2, total: 2),

                const SizedBox(height: AppSpacing.lg),

                Icon(
                  Icons.tune_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l.companyModeSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFamily: 'InstrumentSans',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: BookingModePicker(
                    value: _bookingMode,
                    onChanged: (m) => setState(() => _bookingMode = m),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                AppButton(
                  text: l.companySetupSubmitButton,
                  onPressed: isLoading ? null : _submit,
                  width: double.infinity,
                  isLoading: isLoading,
                ),

                const SizedBox(height: AppSpacing.sm),

                // Secondary back button — mirrors the pattern of the normal
                // signup flow which shows Next + Previous side by side.
                Center(
                  child: TextButton(
                    onPressed: isLoading ? null : _goBack,
                    child: Text(
                      l.previous,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StepIndicator (self-contained — each screen owns its layout)
// ---------------------------------------------------------------------------

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(total, (i) {
          final active = i + 1 == current;
          final done = i + 1 < current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: (active || done) ? AppColors.primary : AppColors.border,
            ),
          );
        }),
        const SizedBox(width: AppSpacing.sm),
        Text(
          l.companySetupStepIndicator(current, total),
          style: GoogleFonts.instrumentSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textHint,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
