import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
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

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  /// Current step for company signup: 0 = personal info, 1 = company info.
  int _currentStep = 0;

  bool get _isCompany => widget.role == 'company';

  @override
  void dispose() {
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

  /// Validates step 1 and advances to step 2.
  void _goToStep2() {
    if (!(_step1FormKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = 1);
  }

  /// Goes back to step 1.
  void _goToStep1() {
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = 0);
  }

  Future<void> _submit() async {
    // For company flow, validate step 2; for user flow, validate the single form.
    final formKey = _isCompany ? _step2FormKey : _step1FormKey;
    if (!(formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final userRole = _isCompany ? UserRole.company : UserRole.user;

    await ref.read(authStateProvider.notifier).signup(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phone: _phoneController.text.trim(),
          role: userRole,
          city: _cityController.text.trim(),
          companyName: _isCompany ? _companyNameController.text.trim() : null,
          address: _isCompany ? _addressController.text.trim() : null,
        );

    if (!mounted) return;
    final error = ref.read(authStateProvider).error;
    if (error != null) {
      _passwordController.clear();
      _confirmPasswordController.clear();
      context.showSnackBar(error, isError: true);
    }
  }

  Future<void> _loginWithGoogle() async {
    await ref.read(authStateProvider.notifier).loginWithGoogle();
    if (!mounted) return;
    final error = ref.read(authStateProvider).error;
    if (error != null) context.showSnackBar(error, isError: true);
  }

  Future<void> _loginWithFacebook() async {
    await ref.read(authStateProvider.notifier).loginWithFacebook();
    if (!mounted) return;
    final error = ref.read(authStateProvider).error;
    if (error != null) context.showSnackBar(error, isError: true);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // ---- Back button ----
                  _BackButton(
                    onTap: _isCompany && _currentStep == 1
                        ? _goToStep1
                        : null, // null = default pop/roleSelect behaviour
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
                      emailController: _emailController,
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
                      onTogglePassword: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                      onToggleConfirmPassword: () => setState(() =>
                          _confirmPasswordVisible = !_confirmPasswordVisible),
                      onNext: _goToStep2,
                      onBack: _goToStep1,
                      onSubmit: _submit,
                    )
                  else
                    _UserSignupFormCard(
                      formKey: _step1FormKey,
                      isLoading: isLoading,
                      emailController: _emailController,
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
                      icon: _GoogleIcon(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppSocialButton(
                      text: context.l10n.continueWithFacebook,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _loginWithFacebook,
                      icon: _FacebookIcon(),
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
                  context.l10n.stepOf(currentStep + 1, 2),
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

        Text(
          context.l10n.signup,
          style: AppTextStyles.h1,
        ),

        const SizedBox(height: AppSpacing.xs),

        Text(
          'Créez votre compte en quelques secondes',
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
                    hint: 'Jean',
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
                    hint: 'Dupont',
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
              hint: '+33 6 00 00 00 00',
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
// Company signup — 2-step form with AnimatedSwitcher between steps
// ---------------------------------------------------------------------------
class _CompanySignupForm extends StatelessWidget {
  final int currentStep;
  final bool isLoading;

  final GlobalKey<FormState> step1FormKey;
  final GlobalKey<FormState> step2FormKey;

  final TextEditingController emailController;
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
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const _CompanySignupForm({
    required this.currentStep,
    required this.isLoading,
    required this.step1FormKey,
    required this.step2FormKey,
    required this.emailController,
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
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onNext,
    required this.onBack,
    required this.onSubmit,
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
      child: currentStep == 0
          ? _CompanyStep1(
              key: const ValueKey('step1'),
              formKey: step1FormKey,
              emailController: emailController,
              phoneController: phoneController,
              cityController: cityController,
              firstNameController: firstNameController,
              lastNameController: lastNameController,
              onNext: onNext,
            )
          : _CompanyStep2(
              key: const ValueKey('step2'),
              formKey: step2FormKey,
              isLoading: isLoading,
              passwordController: passwordController,
              confirmPasswordController: confirmPasswordController,
              companyNameController: companyNameController,
              addressController: addressController,
              passwordVisible: passwordVisible,
              confirmPasswordVisible: confirmPasswordVisible,
              onTogglePassword: onTogglePassword,
              onToggleConfirmPassword: onToggleConfirmPassword,
              onBack: onBack,
              onSubmit: onSubmit,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Company Step 1 — personal info (owner: firstName, lastName, email, phone)
// ---------------------------------------------------------------------------
class _CompanyStep1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController cityController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final VoidCallback onNext;

  const _CompanyStep1({
    super.key,
    required this.formKey,
    required this.emailController,
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
                    hint: 'Jean',
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
                    hint: 'Dupont',
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
              hint: '+33 6 00 00 00 00',
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
              label: context.l10n.cityCompany,
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
                      context.l10n.cityCompanyDescription,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
// Company Step 2 — company info + password
// ---------------------------------------------------------------------------
class _CompanyStep2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isLoading;

  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController companyNameController;
  final TextEditingController addressController;

  final bool passwordVisible;
  final bool confirmPasswordVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const _CompanyStep2({
    super.key,
    required this.formKey,
    required this.isLoading,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.companyNameController,
    required this.addressController,
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
            // Section label
            _StepSectionLabel(
              icon: Icons.storefront_outlined,
              label: context.l10n.yourCompany,
              color: AppColors.secondary,
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              controller: companyNameController,
              label: context.l10n.companyName,
              hint: 'Mon Salon',
              prefixIcon: Icons.storefront_outlined,
              validator: (v) => Validators.required(
                v,
                message: context.l10n.companyNameRequired,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              controller: addressController,
              label: context.l10n.address,
              hint: '12 Rue de la Paix, Paris',
              prefixIcon: Icons.location_on_outlined,
              validator: (v) => Validators.required(
                v,
                message: context.l10n.addressRequired,
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

            // Submit button
            AppButton(
              text: context.l10n.signup,
              isLoading: isLoading,
              onPressed: isLoading ? null : onSubmit,
              width: double.infinity,
            ),

            const SizedBox(height: AppSpacing.sm),

            // Back text button
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
// Shared white card shell
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
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Step section label (icon + coloured title)
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
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
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
          child: Text('Sécurité', style: AppTextStyles.caption),
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
            context.l10n.orContinueWith,
            style: AppTextStyles.caption,
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
          style: AppTextStyles.body,
        ),
        GestureDetector(
          onTap: () => context.goNamed(RouteNames.login),
          child: const Text(
            'Connectez-vous',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Social brand icons
// ---------------------------------------------------------------------------
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: Text(
        'G',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4285F4),
          height: 1.4,
        ),
      ),
    );
  }
}

class _FacebookIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'f',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.4,
        ),
      ),
    );
  }
}
