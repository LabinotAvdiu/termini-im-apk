import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/salon_location_fields.dart';
import '../providers/company_setup_draft_provider.dart';
import '../widgets/company_clientele_selector.dart';

/// Step 1 of the owner onboarding: collects salon name, address, clientele,
/// phone and optional description. On "Next" it writes a [CompanySetupDraft]
/// to [companySetupDraftProvider] and pushes to `/company-mode` (Step 2).
class CompanySetupScreen extends ConsumerStatefulWidget {
  const CompanySetupScreen({super.key});

  @override
  ConsumerState<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends ConsumerState<CompanySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _companyGender;
  double? _latitude;
  double? _longitude;
  bool _showClienteleError = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate fields if the user navigated back from Step 2.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draft = ref.read(companySetupDraftProvider);
      if (draft != null) {
        _companyNameController.text = draft.name;
        _addressController.text = draft.address;
        _cityController.text = draft.city;
        _phoneController.text = draft.phone ?? '';
        setState(() {
          _companyGender = draft.companyGender;
          _latitude = draft.latitude;
          _longitude = draft.longitude;
        });
      }
    });
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _goNext() {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (_companyGender == null) {
      setState(() => _showClienteleError = true);
    }
    if (!formValid || _companyGender == null) return;

    // Persist draft so Step 2 can read it and submit.
    ref.read(companySetupDraftProvider.notifier).save(
          CompanySetupDraft(
            name: _companyNameController.text.trim().titleCase,
            address: _addressController.text.trim(),
            city: _cityController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            latitude: _latitude,
            longitude: _longitude,
            companyGender: _companyGender!,
          ),
        );

    context.goNamed(RouteNames.companyMode);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar.modal(title: l.companySetupHeadline),
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
                _StepIndicator(current: 1, total: 2),

                const SizedBox(height: AppSpacing.lg),

                Icon(
                  Icons.storefront_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l.companySetupSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          controller: _companyNameController,
                          label: l.companyName,
                          hint: l.companyNameHint,
                          prefixIcon: Icons.storefront_outlined,
                          validator: (v) => Validators.required(
                            v,
                            message: l.companyNameRequired,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SalonLocationFields(
                          addressController: _addressController,
                          cityController: _cityController,
                          latitude: _latitude,
                          longitude: _longitude,
                          onLocationCaptured: (lat, lng) => setState(() {
                            _latitude = lat;
                            _longitude = lng;
                          }),
                          onLocationInvalidated: () => setState(() {
                            _latitude = null;
                            _longitude = null;
                          }),
                          onPlaceSelected: (details) => setState(() {
                            _latitude = details.latitude;
                            _longitude = details.longitude;
                            if (details.city != null &&
                                details.city!.isNotEmpty) {
                              _cityController.text = details.city!;
                            }
                          }),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _phoneController,
                          label: l.phone,
                          hint: '+383 44 123 456',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CompanyClienteleSelector(
                          value: _companyGender,
                          onChanged: (g) {
                            setState(() {
                              _showClienteleError = false;
                              _companyGender = g;
                            });
                          },
                          errorText: _showClienteleError
                              ? l.salonClienteleRequired
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          text: l.companySetupNextButton,
                          onPressed: _goNext,
                          width: double.infinity,
                        ),
                      ],
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
// _StepIndicator — "Étape 1 / 2" pill
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
        // Progress dots
        ...List.generate(total, (i) {
          final active = i + 1 == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: active ? AppColors.primary : AppColors.border,
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
