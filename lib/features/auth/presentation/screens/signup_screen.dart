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
import '../../../../core/network/dio_provider.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/place_autocomplete_field.dart';
import '../../../../core/network/places_datasource.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  /// 'user' or 'company'
  final String role;

  const SignupScreen({super.key, required this.role});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  // Separate form keys per step so validation is scoped correctly.
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step4FormKey = GlobalKey<FormState>();

  // Shared controllers
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Personal info controllers (user + company owner)
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  // City controller (user + company)
  final _cityController = TextEditingController();

  // Company-only controllers
  final _companyNameController = TextEditingController();
  final _addressController = TextEditingController();

  double? _latitude;
  double? _longitude;

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  /// Current step for company signup:
  /// 0 = personal info, 1 = company info, 2 = booking mode, 3 = security.
  int _currentStep = 0;

  String _bookingMode = 'employee_based';

  final FocusNode _emailFocusNode = FocusNode();
  String? _emailError;
  bool _checkingEmail = false;
  String _lastCheckedEmail = '';

  bool get _isCompany => widget.role == 'company';

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onEmailFocusChange);
  }

  void _onEmailFocusChange() {
    if (_emailFocusNode.hasFocus) return;
    final email = _emailController.text.trim();
    if (email.isEmpty || email == _lastCheckedEmail) return;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return;
    _checkEmailAvailability(email);
  }

  Future<void> _checkEmailAvailability(String email) async {
    setState(() {
      _checkingEmail = true;
      _emailError = null;
    });
    final repository = ref.read(authRepositoryProvider);
    final available = await repository.checkEmailAvailable(email);
    if (!mounted) return;
    setState(() {
      _checkingEmail = false;
      _lastCheckedEmail = email;
      _emailError = available ? null : context.l10n.emailAlreadyUsed;
    });
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _emailFocusNode.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    _companyNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ---- Actions ----

  void _goToStep2() {
    if (!(_step1FormKey.currentState?.validate() ?? false)) return;
    if (_emailError != null) return;
    if (_checkingEmail) return;
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = 1);
  }

  void _goToStep1() {
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = 0);
  }

  void _goToStep3() {
    if (!(_step2FormKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = 2);
  }

  void _goToStep4() {
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = 3);
  }

  void _goToStep2FromStep3() {
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = 2);
  }

  void _goBackToCompanyStep() {
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = 1);
  }

  Future<void> _submit() async {
    final formKey = _isCompany ? _step4FormKey : _step1FormKey;
    if (!(formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final userRole = _isCompany ? UserRole.company : UserRole.user;

    await ref.read(authStateProvider.notifier).signup(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
          firstName: _firstNameController.text.trim().titleCase,
          lastName: _lastNameController.text.trim().titleCase,
          phone: _phoneController.text.trim(),
          role: userRole,
          city: _cityController.text.trim(),
          companyName: _isCompany ? _companyNameController.text.trim().titleCase : null,
          address: _isCompany ? _addressController.text.trim() : null,
          bookingMode: _isCompany ? _bookingMode : null,
          latitude: _isCompany ? _latitude : null,
          longitude: _isCompany ? _longitude : null,
          locale: ref.read(localeProvider).languageCode,
        );

    if (!mounted) return;
    final error = ref.read(authStateProvider).error;
    if (error != null) {
      _passwordController.clear();
      _confirmPasswordController.clear();
      context.showErrorSnackBar(error);
    }
  }

  Future<void> _loginWithGoogle() async {
    await ref.read(authStateProvider.notifier).loginWithGoogle();
    if (!mounted) return;
    final error = ref.read(authStateProvider).error;
    if (error != null) context.showErrorSnackBar(error);
  }

  Future<void> _loginWithFacebook() async {
    await ref.read(authStateProvider.notifier).loginWithFacebook();
    if (!mounted) return;
    final error = ref.read(authStateProvider).error;
    if (error != null) context.showErrorSnackBar(error);
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _TopGradientDecoration(isCompany: _isCompany),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // ---- Back button ----
                  _BackButton(
                    onTap: _isCompany && _currentStep == 1
                        ? _goToStep1
                        : _isCompany && _currentStep == 2
                            ? _goBackToCompanyStep
                            : _isCompany && _currentStep == 3
                                ? _goToStep2FromStep3
                                : null,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ---- Role badge + title + optional step indicator ----
                  _SignupHeader(
                    isCompany: _isCompany,
                    currentStep: _currentStep,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ---- Form card ----
                  if (_isCompany)
                    _CompanySignupForm(
                      currentStep: _currentStep,
                      isLoading: isLoading,
                      step1FormKey: _step1FormKey,
                      step2FormKey: _step2FormKey,
                      step4FormKey: _step4FormKey,
                      emailController: _emailController,
                      emailFocusNode: _emailFocusNode,
                      emailError: _emailError,
                      phoneController: _phoneController,
                      cityController: _cityController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      firstNameController: _firstNameController,
                      lastNameController: _lastNameController,
                      companyNameController: _companyNameController,
                      addressController: _addressController,
                      passwordVisible: _passwordVisible,
                      confirmPasswordVisible: _confirmPasswordVisible,
                      bookingMode: _bookingMode,
                      onBookingModeChanged: (mode) =>
                          setState(() => _bookingMode = mode),
                      onTogglePassword: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                      onToggleConfirmPassword: () => setState(() =>
                          _confirmPasswordVisible = !_confirmPasswordVisible),
                      onNext: _goToStep2,
                      onBack: _goToStep1,
                      onNextFromStep2: _goToStep3,
                      onNextFromStep3: _goToStep4,
                      onBackFromStep3: _goBackToCompanyStep,
                      onBackFromStep4: _goToStep2FromStep3,
                      onSubmit: _submit,
                      onPlaceSelected: (details) => setState(() {
                        _latitude = details.latitude;
                        _longitude = details.longitude;
                        if (details.city != null && details.city!.isNotEmpty) {
                          _cityController.text = details.city!;
                        }
                      }),
                    )
                  else
                    _UserSignupFormCard(
                      formKey: _step1FormKey,
                      isLoading: isLoading,
                      emailController: _emailController,
                      emailFocusNode: _emailFocusNode,
                      emailError: _emailError,
                      phoneController: _phoneController,
                      cityController: _cityController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      firstNameController: _firstNameController,
                      lastNameController: _lastNameController,
                      passwordVisible: _passwordVisible,
                      confirmPasswordVisible: _confirmPasswordVisible,
                      onTogglePassword: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                      onToggleConfirmPassword: () => setState(() =>
                          _confirmPasswordVisible = !_confirmPasswordVisible),
                      onSubmit: _submit,
                    ),

                  // ---- Social section (user only) ----
                  if (!_isCompany) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _OrDivider(),
                    const SizedBox(height: AppSpacing.lg),
                    AppSocialButton(
                      text: context.l10n.continueWithGoogle,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _loginWithGoogle,
                      icon: const _GoogleIcon(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppSocialButton(
                      text: context.l10n.continueWithFacebook,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _loginWithFacebook,
                      icon: const _FacebookIcon(),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // ---- Login link ----
                  _LoginLink(),

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
// Top gradient decoration (color differs per role)
// ---------------------------------------------------------------------------
class _TopGradientDecoration extends StatelessWidget {
  final bool isCompany;
  const _TopGradientDecoration({required this.isCompany});

  @override
  Widget build(BuildContext context) {
    final color = isCompany ? AppColors.secondary : AppColors.primary;
    return Positioned(
      top: -80,
      left: -80,
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Back button — optionally overrides default pop with a custom callback.
// ---------------------------------------------------------------------------
class _BackButton extends StatelessWidget {
  /// When non-null, tapping calls this instead of the default pop/roleSelect.
  final VoidCallback? onTap;

  const _BackButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap ??
            () => context.canPop()
                ? context.pop()
                : context.goNamed(RouteNames.roleSelect),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header with role badge + title + optional step indicator (company only)
// ---------------------------------------------------------------------------
class _SignupHeader extends StatelessWidget {
  final bool isCompany;
  final int currentStep;

  const _SignupHeader({required this.isCompany, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final badgeColor = isCompany ? AppColors.secondary : AppColors.primary;
    final badgeText =
        isCompany ? context.l10n.iAmCompany : context.l10n.iAmUser;
    final badgeIcon =
        isCompany ? Icons.storefront_rounded : Icons.person_rounded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Role badge + step indicator on the same row
        Row(
          children: [
            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 14, color: badgeColor),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
            ),

            // Step indicator — only shown for company signup
            if (isCompany) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Text(
                  context.l10n.stepOf(currentStep + 1, 4),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Uppercase overline above the display title
        Text(
          'CRÉER UN COMPTE',
          style: AppTextStyles.overline.copyWith(letterSpacing: 2.0),
        ),
        const SizedBox(height: AppSpacing.xs),

        Text(
          context.l10n.signup,
          style: AppTextStyles.h1,
        ),

        const SizedBox(height: AppSpacing.xs),

        Text(
          context.l10n.signupSubtitle,
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// User signup — single-page form (unchanged behaviour)
// ---------------------------------------------------------------------------
class _UserSignupFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isLoading;

  final TextEditingController emailController;
  final FocusNode emailFocusNode;
  final String? emailError;
  final TextEditingController phoneController;
  final TextEditingController cityController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;

  final bool passwordVisible;
  final bool confirmPasswordVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSubmit;

  const _UserSignupFormCard({
    required this.formKey,
    required this.isLoading,
    required this.emailController,
    required this.emailFocusNode,
    this.emailError,
    required this.phoneController,
    required this.cityController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.firstNameController,
    required this.lastNameController,
    required this.passwordVisible,
    required this.confirmPasswordVisible,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // First name + last name side by side
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: firstNameController,
                    label: context.l10n.firstName,
                    hint: 'Arben',
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) => Validators.required(
                      v,
                      message: context.l10n.firstNameRequired,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    controller: lastNameController,
                    label: context.l10n.lastName,
                    hint: 'Krasniqi',
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) => Validators.required(
                      v,
                      message: context.l10n.lastNameRequired,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              controller: emailController,
              focusNode: emailFocusNode,
              errorText: emailError,
              label: context.l10n.email,
              hint: 'exemple@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => Validators.email(
                v,
                requiredMessage: context.l10n.emailRequired,
                invalidMessage: context.l10n.emailInvalid,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              controller: phoneController,
              label: context.l10n.phone,
              hint: '044 123 456',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => Validators.required(
                v,
                message: context.l10n.phoneRequired,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              controller: cityController,
              label: context.l10n.city,
              hint: context.l10n.cityHint,
              prefixIcon: Icons.location_city_outlined,
              validator: (v) => Validators.required(
                v,
                message: context.l10n.cityRequired,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 12, color: AppColors.textHint),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      context.l10n.cityDescription,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            _SecurityDivider(),
            const SizedBox(height: AppSpacing.md),

            _PasswordField(
              controller: passwordController,
              label: context.l10n.password,
              visible: passwordVisible,
              onToggle: onTogglePassword,
              validator: (v) => Validators.password(
                v,
                requiredMessage: context.l10n.passwordRequired,
                tooShortMessage: context.l10n.passwordTooShort,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            _PasswordField(
              controller: confirmPasswordController,
              label: context.l10n.confirmPassword,
              visible: confirmPasswordVisible,
              onToggle: onToggleConfirmPassword,
              validator: (v) => Validators.confirmPassword(
                v,
                passwordController.text,
                message: context.l10n.passwordsDoNotMatch,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _PasswordStrengthHint(),
            const SizedBox(height: AppSpacing.lg),

            AppButton(
              text: context.l10n.signup,
              isLoading: isLoading,
              onPressed: isLoading ? null : onSubmit,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Company signup — 4-step form with AnimatedSwitcher between steps
// ---------------------------------------------------------------------------
class _CompanySignupForm extends StatelessWidget {
  final int currentStep;
  final bool isLoading;

  final GlobalKey<FormState> step1FormKey;
  final GlobalKey<FormState> step2FormKey;
  final GlobalKey<FormState> step4FormKey;

  final TextEditingController emailController;
  final FocusNode emailFocusNode;
  final String? emailError;
  final TextEditingController phoneController;
  final TextEditingController cityController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController companyNameController;
  final TextEditingController addressController;

  final bool passwordVisible;
  final bool confirmPasswordVisible;
  final String bookingMode;
  final ValueChanged<String> onBookingModeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onNextFromStep2;
  final VoidCallback onNextFromStep3;
  final VoidCallback onBackFromStep3;
  final VoidCallback onBackFromStep4;
  final VoidCallback onSubmit;
  final void Function(PlaceDetails details) onPlaceSelected;

  const _CompanySignupForm({
    required this.currentStep,
    required this.isLoading,
    required this.step1FormKey,
    required this.step2FormKey,
    required this.step4FormKey,
    required this.emailController,
    required this.emailFocusNode,
    this.emailError,
    required this.phoneController,
    required this.cityController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.firstNameController,
    required this.lastNameController,
    required this.companyNameController,
    required this.addressController,
    required this.passwordVisible,
    required this.confirmPasswordVisible,
    required this.bookingMode,
    required this.onBookingModeChanged,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onNext,
    required this.onBack,
    required this.onNextFromStep2,
    required this.onNextFromStep3,
    required this.onBackFromStep3,
    required this.onBackFromStep4,
    required this.onSubmit,
    required this.onPlaceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        // Slide in from the right on advance, from the left on back.
        // We use a SlideTransition with a fixed direction; the key change
        // ensures the correct widget animates in.
        final offsetTween = Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offsetTween.animate(animation),
            child: child,
          ),
        );
      },
      child: switch (currentStep) {
        0 => _CompanyStep1(
            key: const ValueKey('step1'),
            formKey: step1FormKey,
            emailController: emailController,
            emailFocusNode: emailFocusNode,
            emailError: emailError,
            phoneController: phoneController,
            cityController: cityController,
            firstNameController: firstNameController,
            lastNameController: lastNameController,
            onNext: onNext,
          ),
        1 => _CompanyStep2(
            key: const ValueKey('step2'),
            formKey: step2FormKey,
            companyNameController: companyNameController,
            addressController: addressController,
            onBack: onBack,
            onNext: onNextFromStep2,
            onPlaceSelected: onPlaceSelected,
          ),
        2 => _CompanyStep3BookingMode(
            key: const ValueKey('step3'),
            bookingMode: bookingMode,
            onBookingModeChanged: onBookingModeChanged,
            onBack: onBackFromStep3,
            onNext: onNextFromStep3,
          ),
        _ => _CompanyStep4Security(
            key: const ValueKey('step4'),
            formKey: step4FormKey,
            isLoading: isLoading,
            passwordController: passwordController,
            confirmPasswordController: confirmPasswordController,
            passwordVisible: passwordVisible,
            confirmPasswordVisible: confirmPasswordVisible,
            onTogglePassword: onTogglePassword,
            onToggleConfirmPassword: onToggleConfirmPassword,
            onBack: onBackFromStep4,
            onSubmit: onSubmit,
          ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Company Step 1 — personal info (owner: firstName, lastName, email, phone)
// ---------------------------------------------------------------------------
class _CompanyStep1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final FocusNode emailFocusNode;
  final String? emailError;
  final TextEditingController phoneController;
  final TextEditingController cityController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final VoidCallback onNext;

  const _CompanyStep1({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.emailFocusNode,
    this.emailError,
    required this.phoneController,
    required this.cityController,
    required this.firstNameController,
    required this.lastNameController,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section label
            _StepSectionLabel(
              icon: Icons.person_outline_rounded,
              label: context.l10n.yourInfo,
              color: AppColors.secondary,
            ),
            const SizedBox(height: AppSpacing.md),

            // First name + last name side by side
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: firstNameController,
                    label: context.l10n.firstName,
                    hint: 'Arben',
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) => Validators.required(
                      v,
                      message: context.l10n.firstNameRequired,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    controller: lastNameController,
                    label: context.l10n.lastName,
                    hint: 'Krasniqi',
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) => Validators.required(
                      v,
                      message: context.l10n.lastNameRequired,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              controller: emailController,
              focusNode: emailFocusNode,
              errorText: emailError,
              label: context.l10n.email,
              hint: 'exemple@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => Validators.email(
                v,
                requiredMessage: context.l10n.emailRequired,
                invalidMessage: context.l10n.emailInvalid,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              controller: phoneController,
              label: context.l10n.phone,
              hint: '044 123 456',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => Validators.required(
                v,
                message: context.l10n.phoneRequired,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            const SizedBox(height: AppSpacing.lg),

            AppButton(
              text: context.l10n.next,
              onPressed: onNext,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Company Step 2 — company info only
// ---------------------------------------------------------------------------
class _CompanyStep2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController companyNameController;
  final TextEditingController addressController;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final void Function(PlaceDetails details) onPlaceSelected;

  const _CompanyStep2({
    super.key,
    required this.formKey,
    required this.companyNameController,
    required this.addressController,
    required this.onBack,
    required this.onNext,
    required this.onPlaceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepSectionLabel(
              icon: Icons.storefront_outlined,
              label: context.l10n.yourCompany,
              color: AppColors.secondary,
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              controller: companyNameController,
              label: context.l10n.companyName,
              hint: context.l10n.companyNameHint,
              prefixIcon: Icons.storefront_outlined,
              validator: (v) => Validators.required(
                v,
                message: context.l10n.companyNameRequired,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            PlaceAutocompleteField(
              controller: addressController,
              label: context.l10n.address,
              hint: context.l10n.addressHintExample,
              onPlaceSelected: onPlaceSelected,
              validator: (v) => Validators.required(
                v,
                message: context.l10n.addressRequired,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            AppButton(
              text: context.l10n.next,
              onPressed: onNext,
              width: double.infinity,
            ),

            const SizedBox(height: AppSpacing.sm),

            Center(
              child: TextButton(
                onPressed: onBack,
                child: Text(
                  context.l10n.previous,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
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
// Company Step 3 — Booking mode selection
// ---------------------------------------------------------------------------
class _CompanyStep3BookingMode extends StatelessWidget {
  final String bookingMode;
  final ValueChanged<String> onBookingModeChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _CompanyStep3BookingMode({
    super.key,
    required this.bookingMode,
    required this.onBookingModeChanged,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepSectionLabel(
            icon: Icons.calendar_today_outlined,
            label: context.l10n.bookingModeTitle,
            color: AppColors.secondary,
          ),
          const SizedBox(height: AppSpacing.md),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 340;
              final cards = [
                _BookingModeCard(
                  modeKey: 'capacity_based',
                  icon: Icons.storefront_rounded,
                  title: context.l10n.bookingModeCapacityBasedTitle,
                  shortBody: context.l10n.bookingModeCapacityBasedShort,
                  description: context.l10n.bookingModeCapacityBasedDescription,
                  selected: bookingMode == 'capacity_based',
                  onTap: () => onBookingModeChanged('capacity_based'),
                ),
                _BookingModeCard(
                  modeKey: 'employee_based',
                  icon: Icons.groups_rounded,
                  title: context.l10n.bookingModeEmployeeBasedTitle,
                  shortBody: context.l10n.bookingModeEmployeeBasedShort,
                  description: context.l10n.bookingModeEmployeeBasedDescription,
                  selected: bookingMode == 'employee_based',
                  onTap: () => onBookingModeChanged('employee_based'),
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: [
                    cards[0],
                    const SizedBox(height: AppSpacing.sm),
                    cards[1],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: cards[1]),
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Detailed explanation block for the currently-selected mode
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bookingMode == 'capacity_based'
                  ? [
                      _ExplainBullet(text: context.l10n.capacityBasedHint1),
                      _ExplainBullet(text: context.l10n.capacityBasedHint2),
                      _ExplainBullet(text: context.l10n.capacityBasedHint3),
                    ]
                  : [
                      _ExplainBullet(text: context.l10n.employeeBasedHint1),
                      _ExplainBullet(text: context.l10n.employeeBasedHint2),
                      _ExplainBullet(text: context.l10n.employeeBasedHint3),
                      _ExplainBullet(text: context.l10n.employeeBasedHint4),
                    ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              const Icon(Icons.info_outline, size: 13, color: AppColors.textHint),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  context.l10n.settingsEditableLater,
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          AppButton(
            text: context.l10n.next,
            onPressed: onNext,
            width: double.infinity,
          ),

          const SizedBox(height: AppSpacing.sm),

          Center(
            child: TextButton(
              onPressed: onBack,
              child: Text(
                context.l10n.previous,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplainBullet extends StatelessWidget {
  final String text;
  const _ExplainBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingModeCard extends StatelessWidget {
  final String modeKey;
  final IconData icon;
  final String title;
  final String shortBody;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _BookingModeCard({
    required this.modeKey,
    required this.icon,
    required this.title,
    required this.shortBody,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  void _showInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
          ],
        ),
        content: Text(description, style: const TextStyle(fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.secondary : AppColors.border;
    final borderWidth = selected ? 2.0 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondary.withValues(alpha: 0.06)
              : AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: selected ? AppColors.secondary : AppColors.textSecondary),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showInfo(context),
                  child: const Icon(Icons.info_outline, size: 16, color: AppColors.textHint),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.secondary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              shortBody,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Company Step 4 — Security (password)
// ---------------------------------------------------------------------------
class _CompanyStep4Security extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool passwordVisible;
  final bool confirmPasswordVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const _CompanyStep4Security({
    super.key,
    required this.formKey,
    required this.isLoading,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.passwordVisible,
    required this.confirmPasswordVisible,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Form(
        key: formKey,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepSectionLabel(
            icon: Icons.lock_outline_rounded,
            label: context.l10n.security,
            color: AppColors.secondary,
          ),
          const SizedBox(height: AppSpacing.md),

          _PasswordField(
            controller: passwordController,
            label: context.l10n.password,
            visible: passwordVisible,
            onToggle: onTogglePassword,
            validator: (v) => Validators.password(
              v,
              requiredMessage: context.l10n.passwordRequired,
              tooShortMessage: context.l10n.passwordTooShort,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          _PasswordField(
            controller: confirmPasswordController,
            label: context.l10n.confirmPassword,
            visible: confirmPasswordVisible,
            onToggle: onToggleConfirmPassword,
            validator: (v) => Validators.confirmPassword(
              v,
              passwordController.text,
              message: context.l10n.passwordsDoNotMatch,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          _PasswordStrengthHint(),
          const SizedBox(height: AppSpacing.lg),

          AppButton(
            text: context.l10n.signup,
            isLoading: isLoading,
            onPressed: isLoading ? null : onSubmit,
            width: double.infinity,
          ),

          const SizedBox(height: AppSpacing.sm),

          Center(
            child: TextButton(
              onPressed: isLoading ? null : onBack,
              child: Text(
                context.l10n.previous,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
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
// Shared white card shell — editorial: 1px hair border, soft shadow
// ---------------------------------------------------------------------------
class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Step section label — uppercase overline with icon
// ---------------------------------------------------------------------------
class _StepSectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StepSectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.overline.copyWith(
            color: color,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable password field (obscure + toggle)
// ---------------------------------------------------------------------------
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool visible;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.visible,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hint: '••••••••',
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: !visible,
      suffixIcon: IconButton(
        icon: Icon(
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textHint,
          size: 20,
        ),
        onPressed: onToggle,
      ),
      validator: validator,
    );
  }
}

// ---------------------------------------------------------------------------
// "Sécurité" section divider
// ---------------------------------------------------------------------------
class _SecurityDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(context.l10n.security, style: AppTextStyles.caption),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Password strength reminder
// ---------------------------------------------------------------------------
class _PasswordStrengthHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.slotAvailable,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hintRow(context.l10n.passwordTooShort),
          const SizedBox(height: 2),
          _hintRow(context.l10n.passwordNeedsUpper),
          const SizedBox(height: 2),
          _hintRow(context.l10n.passwordNeedsNumber),
        ],
      ),
    );
  }

  Widget _hintRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, size: 12, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "Or continue with" divider
// ---------------------------------------------------------------------------
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            context.l10n.orContinueWith.toUpperCase(),
            style: AppTextStyles.overline,
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "Already have an account?" link
// ---------------------------------------------------------------------------
class _LoginLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${context.l10n.alreadyHaveAccount} ',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
        GestureDetector(
          onTap: () => context.goNamed(RouteNames.login),
          child: Text(
            context.l10n.loginNow,
            style: GoogleFonts.instrumentSerif(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: AppColors.primary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Social brand icons — rendered via CustomPainter (no external packages)
// ---------------------------------------------------------------------------

/// Official Google multicolor "G" logo painted on a 24x24 canvas.
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Clip to circle
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);

    // Segment angles (degrees → radians): Red, Yellow, Green, Blue
    const double toRad = 3.14159265 / 180.0;
    final segments = [
      [-21.0, 90.0, const Color(0xFFEA4335)],  // Red
      [69.0,  90.0, const Color(0xFFFBBC05)],  // Yellow
      [159.0, 90.0, const Color(0xFF34A853)],  // Green
      [249.0, 90.0, const Color(0xFF4285F4)],  // Blue
    ];

    final strokeWidth = r * 0.38;
    final innerR = r - strokeWidth;

    for (final seg in segments) {
      final paint = Paint()
        ..color = seg[2] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: innerR + strokeWidth / 2),
        (seg[0] as double) * toRad,
        (seg[1] as double) * toRad,
        false,
        paint,
      );
    }

    // White cutout inner circle to form ring
    canvas.drawCircle(
      Offset(cx, cy),
      innerR - 0.5,
      Paint()..color = Colors.white,
    );

    // Blue horizontal bar (the crossbar of the G)
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barTop = cy - strokeWidth * 0.38;
    final barBottom = cy + strokeWidth * 0.38;
    final barLeft = cx - 0.5;
    final barRight = cx + innerR + 0.5;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(cx, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTRB(barLeft, barTop, barRight, barBottom), barPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Official Facebook "f" logo: blue rounded square with white f.
class _FacebookIcon extends StatelessWidget {
  const _FacebookIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _FacebookLogoPainter(),
    );
  }
}

class _FacebookLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rr = size.width * 0.22;

    // Blue rounded-square background
    final bgPaint = Paint()..color = const Color(0xFF1877F2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(rr),
      ),
      bgPaint,
    );

    // White "f" glyph via path
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Stem
    final stemW = w * 0.13;
    final stemLeft = w * 0.425;
    final stemTop = h * 0.33;
    canvas.drawRect(
      Rect.fromLTWH(stemLeft, stemTop, stemW, h * 0.56),
      paint,
    );

    // Crossbar
    canvas.drawRect(
      Rect.fromLTWH(w * 0.28, h * 0.48, w * 0.42, h * 0.10),
      paint,
    );

    // Rounded cap on top of stem
    final capPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = stemW
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(stemLeft + stemW * 2.2, stemTop),
        radius: stemW * 1.5,
      ),
      3.14159,
      3.14159,
      false,
      capPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
