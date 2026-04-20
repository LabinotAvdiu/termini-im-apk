import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/salon_location_fields.dart';
import '../providers/auth_provider.dart';
import '../widgets/company_clientele_selector.dart';

/// Shown to users who authenticated via a social provider and picked
/// role=company, but whose Company record isn't provisioned yet.
///
/// Collects the minimum business info (name, address, clientele, booking
/// mode) and calls `/auth/complete-company`. On success the router clears
/// [needsCompanySetup] and drops the owner on their dashboard.
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
  String _bookingMode = 'employee_based';
  double? _latitude;
  double? _longitude;
  bool _showClienteleError = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (_companyGender == null) {
      setState(() => _showClienteleError = true);
    }
    if (!formValid || _companyGender == null) return;

    final ok = await ref.read(authStateProvider.notifier).completeCompanySignup(
          companyName: _companyNameController.text.trim().titleCase,
          address: _addressController.text.trim(),
          companyGender: _companyGender!,
          city: _cityController.text.trim().isEmpty
              ? null
              : _cityController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          bookingMode: _bookingMode,
          latitude: _latitude,
          longitude: _longitude,
        );

    if (!mounted) return;
    if (!ok) {
      final error = ref.read(authStateProvider).error;
      if (error != null) context.showErrorSnackBar(error);
    }
    // Router redirect watches needsCompanySetup + isAuthenticated and will
    // send the user to /home on success.
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isLoading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  Icon(
                    Icons.storefront_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l.companySetupHeadline,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
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
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
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
                          const SizedBox(height: AppSpacing.md),
                          _BookingModeToggle(
                            value: _bookingMode,
                            onChanged: (m) =>
                                setState(() => _bookingMode = m),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            text: l.next,
                            onPressed: isLoading ? null : _submit,
                            width: double.infinity,
                            isLoading: isLoading,
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
      ),
    );
  }
}

class _BookingModeToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _BookingModeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _ModeChip(
                label: l.bookingModeEmployeeBasedTitle,
                selected: value == 'employee_based',
                onTap: () => onChanged('employee_based'),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _ModeChip(
                label: l.bookingModeCapacityBasedTitle,
                selected: value == 'capacity_based',
                onTap: () => onChanged('capacity_based'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.instrumentSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  selected ? AppColors.surface : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
