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

/// Two-step forgot-password flow:
///
/// Step 1 — user enters their email → we call forgotPassword.
/// Step 2 — user enters the token received by email + new password → we call resetPassword.
///
/// On success of step 2, navigate back to /login with a success snackbar.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  // Step 1 state
  final _emailFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  // Step 2 state
  final _resetFormKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  // Which step we are on
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Step 1 — send reset email
  // ---------------------------------------------------------------------------

  Future<void> _submitEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref
        .read(authStateProvider.notifier)
        .forgotPassword(email: _emailController.text.trim());

    if (!mounted) return;
    final error = ref.read(authStateProvider).error;
    if (error != null) {
      context.showErrorSnackBar(error);
    } else {
      setState(() => _emailSent = true);
    }
  }

  // ---------------------------------------------------------------------------
  // Step 2 — apply token + new password
  // ---------------------------------------------------------------------------

  Future<void> _submitReset() async {
    if (!_resetFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref.read(authStateProvider.notifier).resetPassword(
          token: _tokenController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          passwordConfirmation: _confirmController.text,
        );

    if (!mounted) return;
    final error = ref.read(authStateProvider).error;
    if (error != null) {
      context.showErrorSnackBar(error);
    } else {
      // Navigate to login and show success message
      context.goNamed(RouteNames.login);
      context.showSnackBar(context.l10n.resetPasswordSuccess);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _TopGradientDecoration(),
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

                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _BackButton(),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Header illustration + title
                  _Header(emailSent: _emailSent),

                  const SizedBox(height: AppSpacing.xxl),

                  // Card with form
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _emailSent
                        ? _ResetCard(
                            key: const ValueKey('reset'),
                            formKey: _resetFormKey,
                            tokenController: _tokenController,
                            passwordController: _passwordController,
                            confirmController: _confirmController,
                            passwordVisible: _passwordVisible,
                            confirmVisible: _confirmVisible,
                            onTogglePassword: () => setState(
                                () => _passwordVisible = !_passwordVisible),
                            onToggleConfirm: () => setState(
                                () => _confirmVisible = !_confirmVisible),
                            isLoading: isLoading,
                            onSubmit: _submitReset,
                          )
                        : _EmailCard(
                            key: const ValueKey('email'),
                            formKey: _emailFormKey,
                            emailController: _emailController,
                            isLoading: isLoading,
                            onSubmit: _submitEmail,
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
// Top gradient decoration (same as login screen)
// ---------------------------------------------------------------------------

class _TopGradientDecoration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -60,
      right: -60,
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              AppColors.primary.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Back button
// ---------------------------------------------------------------------------

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.canPop() ? context.pop() : context.goNamed('login'),
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
          size: 16,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header — icon + title + subtitle — editorial style
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final bool emailSent;

  const _Header({required this.emailSent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Icon(
            emailSent ? Icons.lock_reset_rounded : Icons.lock_open_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Overline
        Text(
          emailSent ? 'RÉINITIALISATION' : 'MOT DE PASSE',
          style: AppTextStyles.overline.copyWith(letterSpacing: 2.2),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Fraunces display title
        Text(
          emailSent
              ? context.l10n.resetPasswordTitle
              : context.l10n.forgotPasswordTitle,
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            emailSent
                ? context.l10n.resetEmailSent
                : context.l10n.forgotPasswordSubtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 card — email input
// ---------------------------------------------------------------------------

class _EmailCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _EmailCard({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.onSubmit,
  });

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
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.email.toUpperCase(),
              style: AppTextStyles.overline.copyWith(letterSpacing: 1.8),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(context.l10n.forgotPasswordSubtitle, style: AppTextStyles.h2.copyWith(fontSize: 20)),
            const SizedBox(height: AppSpacing.lg),
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
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: context.l10n.sendResetLink,
              isLoading: isLoading,
              onPressed: isLoading ? null : onSubmit,
              width: double.infinity,
              icon: Icons.send_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 card — token + new password
// ---------------------------------------------------------------------------

class _ResetCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController tokenController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool passwordVisible;
  final bool confirmVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _ResetCard({
    super.key,
    required this.formKey,
    required this.tokenController,
    required this.passwordController,
    required this.confirmController,
    required this.passwordVisible,
    required this.confirmVisible,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.isLoading,
    required this.onSubmit,
  });

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
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'RÉINITIALISATION',
              style: AppTextStyles.overline.copyWith(letterSpacing: 1.8),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(context.l10n.resetPasswordTitle, style: AppTextStyles.h2.copyWith(fontSize: 20)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.resetEmailSent,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Reset token received by email
            AppTextField(
              controller: tokenController,
              label: context.l10n.resetToken,
              hint: 'xxxxxxxx',
              prefixIcon: Icons.vpn_key_outlined,
              keyboardType: TextInputType.text,
              validator: (v) => Validators.required(
                v,
                message: context.l10n.resetToken,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // New password
            AppTextField(
              controller: passwordController,
              label: context.l10n.newPassword,
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: !passwordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textHint,
                  size: 20,
                ),
                onPressed: onTogglePassword,
              ),
              validator: (v) => Validators.password(
                v,
                requiredMessage: context.l10n.passwordRequired,
                tooShortMessage: context.l10n.passwordTooShort,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Confirm new password
            AppTextField(
              controller: confirmController,
              label: context.l10n.confirmPassword,
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: !confirmVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  confirmVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textHint,
                  size: 20,
                ),
                onPressed: onToggleConfirm,
              ),
              validator: (v) => Validators.confirmPassword(
                v,
                passwordController.text,
                message: context.l10n.passwordsDoNotMatch,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            AppButton(
              text: context.l10n.resetPassword,
              isLoading: isLoading,
              onPressed: isLoading ? null : onSubmit,
              width: double.infinity,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
