import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/language_sheet.dart';
import '../../../support/data/models/support_models.dart';
import '../../../support/presentation/widgets/contact_support_dialog.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  // final _emailController = TextEditingController( text: 'karim@barbier-parisien.fr');
  final _emailController = TextEditingController( text: 'donjeta@termini.im');
  final _passwordController = TextEditingController(text: 'Password1');
  bool _passwordVisible = false;

  /// Which social provider is currently running — null / 'google' / 'facebook' /
  /// 'apple'. Used so only the tapped button shows a spinner.
  String? _loadingSocial;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---- Actions ----

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref.read(authStateProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    final authState = ref.read(authStateProvider);
    if (authState.error != null) {
      // Clear only the password field, keep the email
      _passwordController.clear();
      context.showErrorSnackBar(authState.error);
      return;
    }
    // Explicit fallback navigation. The router's redirect on auth state
    // change normally handles this, but after the session-expired flow
    // (state was wiped, then re-built mid-flight) we've seen the
    // refreshListenable miss the second update. Going explicitly is cheap
    // and idempotent — the redirect will not double-bounce because /home
    // is already the resolved target.
    if (authState.isAuthenticated && mounted) {
      _afterLoginNav(authState);
    }
  }

  void _afterLoginNav(AuthState authState) {
    if (authState.needsCompanySetup) {
      context.go('/company-setup');
    } else {
      context.go('/home');
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loadingSocial = 'google');
    try {
      await ref.read(authStateProvider.notifier).loginWithGoogle();
    } finally {
      if (mounted) setState(() => _loadingSocial = null);
    }
    if (!mounted) return;
    final authState = ref.read(authStateProvider);
    if (authState.error != null) {
      context.showErrorSnackBar(authState.error);
      return;
    }
    if (authState.isAuthenticated && mounted) _afterLoginNav(authState);
  }

  Future<void> _loginWithFacebook() async {
    setState(() => _loadingSocial = 'facebook');
    try {
      await ref.read(authStateProvider.notifier).loginWithFacebook();
    } finally {
      if (mounted) setState(() => _loadingSocial = null);
    }
    if (!mounted) return;
    final authState = ref.read(authStateProvider);
    if (authState.error != null) {
      context.showErrorSnackBar(authState.error);
      return;
    }
    if (authState.isAuthenticated && mounted) _afterLoginNav(authState);
  }

  Future<void> _loginWithApple() async {
    setState(() => _loadingSocial = 'apple');
    try {
      await ref.read(authStateProvider.notifier).loginWithApple();
    } finally {
      if (mounted) setState(() => _loadingSocial = null);
    }
    if (!mounted) return;
    final authState = ref.read(authStateProvider);
    if (authState.error != null) {
      context.showErrorSnackBar(authState.error);
      return;
    }
    if (authState.isAuthenticated && mounted) _afterLoginNav(authState);
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;
    // Keep the email-submit button out of the social-login loading state:
    // if the user taps Google, only the Google button should spin.
    final submitLoading = isLoading && _loadingSocial == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar.minimal(
        onBack: () => context.canPop()
            ? context.pop()
            : context.go('/landing'),
      ),
      body: Stack(
        children: [
          // Top decorative gradient arc
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
                  const SizedBox(height: AppSpacing.md),

                  // ---- Logo + title ----
                  _LogoHeader(),

                  const SizedBox(height: AppSpacing.xxl),

                  // ---- Form card ----
                  _FormCard(
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    passwordVisible: _passwordVisible,
                    onTogglePassword: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                    isLoading: submitLoading,
                    onSubmit: _submit,
                    rememberMe: authState.rememberMe,
                    onToggleRememberMe: () =>
                        ref.read(authStateProvider.notifier).toggleRememberMe(),
                    errorMessage: authState.error == null
                        ? null
                        : context.errorMessage(authState.error),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ---- Divider "ou continuer avec" ----
                  _OrDivider(),

                  const SizedBox(height: AppSpacing.lg),

                  // ---- Social buttons (only the tapped one spins) ----
                  AppSocialButton(
                    text: context.l10n.continueWithGoogle,
                    isLoading: _loadingSocial == 'google',
                    onPressed: _loadingSocial != null || isLoading
                        ? null
                        : _loginWithGoogle,
                    icon: const _GoogleIcon(),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  AppSocialButton(
                    text: context.l10n.continueWithFacebook,
                    isLoading: _loadingSocial == 'facebook',
                    onPressed: _loadingSocial != null || isLoading
                        ? null
                        : _loginWithFacebook,
                    icon: const _FacebookIcon(),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  AppSocialButton(
                    text: context.l10n.continueWithApple,
                    isLoading: _loadingSocial == 'apple',
                    onPressed: _loadingSocial != null || isLoading
                        ? null
                        : _loginWithApple,
                    icon: const _AppleIcon(),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ---- Sign-up link ----
                  _SignupLink(),

                  const SizedBox(height: AppSpacing.md),

                  // ---- Contact support footer (guest) ----
                  _SupportLink(ref: ref),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
                ),
              ),
            ),
          ),

          // Language toggle — positioned last so it stays on top of scroll view
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: IconButton(
                  icon: const Icon(
                    Icons.language_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  tooltip: context.l10n.language,
                  onPressed: () => showLanguageSheet(context),
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
// Top gradient decoration blob
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
// Logo + title
// ---------------------------------------------------------------------------
class _LogoHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Full wordmark — same mark as the landing page and OG card.
        // Pre-launch, the monogram alone doesn't read as "Termini im";
        // the wordmark builds recognition across every touchpoint.
        const BrandLogo(variant: BrandLogoVariant.wordmark, size: 40),
        const SizedBox(height: AppSpacing.lg),
        // Display serif headline
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: context.l10n.welcome,
                style: GoogleFonts.fraunces(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                  height: 1.1,
                  letterSpacing: -0.6,
                ),
              ),
              TextSpan(
                text: '.',
                style: GoogleFonts.instrumentSerif(
                  fontSize: 30,
                  fontStyle: FontStyle.italic,
                  color: AppColors.secondary,
                  height: 1.1,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.loginSubtitle,
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Form card
// ---------------------------------------------------------------------------
class _FormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool passwordVisible;
  final VoidCallback onTogglePassword;
  final bool isLoading;
  final VoidCallback onSubmit;
  final bool rememberMe;
  final VoidCallback onToggleRememberMe;
  final String? errorMessage;

  const _FormCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.passwordVisible,
    required this.onTogglePassword,
    required this.isLoading,
    required this.onSubmit,
    required this.rememberMe,
    required this.onToggleRememberMe,
    this.errorMessage,
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
            // Fraunces serif card title
            Text(
              context.l10n.login,
              style: AppTextStyles.h2,
            ),

            const SizedBox(height: AppSpacing.xs),

            Text(
              context.l10n.loginSubtitle,
              style: AppTextStyles.bodySmall,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Email
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

            // Password
            AppTextField(
              controller: passwordController,
              label: context.l10n.password,
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
              validator: (v) => Validators.required(
                v,
                message: context.l10n.passwordRequired,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.push('/forgot-password'),
                child: Text(
                  context.l10n.forgotPassword,
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Remember me
            _RememberMeRow(
              value: rememberMe,
              onToggle: onToggleRememberMe,
            ),

            // Error message
            if (errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Submit button
            AppButton(
              text: context.l10n.login,
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
// Remember me row
// ---------------------------------------------------------------------------
class _RememberMeRow extends StatelessWidget {
  final bool value;
  final VoidCallback onToggle;

  const _RememberMeRow({required this.value, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Make the entire row tappable (wider touch target than the checkbox alone)
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: (_) => onToggle(),
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            context.l10n.rememberMe,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
// "No account? Sign up" link
// ---------------------------------------------------------------------------
class _SignupLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${context.l10n.noAccount} ',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
        GestureDetector(
          onTap: () => context.pushNamed(RouteNames.roleSelect),
          child: Text(
            context.l10n.signupNow,
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

class _SupportLink extends StatelessWidget {
  final WidgetRef ref;
  const _SupportLink({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${context.l10n.needHelpFooter} ',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
        GestureDetector(
          onTap: () => showContactSupportDialog(
            context,
            ref: ref,
            sourcePage: SupportSourcePage.login,
          ),
          child: Text(
            context.l10n.needHelpFooterLink,
            style: GoogleFonts.instrumentSerif(
              fontSize: 13,
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
    return SvgPicture.asset(
      'assets/icons/google.svg',
      width: 24,
      height: 24,
    );
  }
}

class _FacebookIcon extends StatelessWidget {
  const _FacebookIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/facebook.svg',
      width: 24,
      height: 24,
    );
  }
}

// ---------------------------------------------------------------------------
// Apple glyph — monochrome Material icon for crisp rendering at any DPI.
// ---------------------------------------------------------------------------
class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.apple, size: 22, color: AppColors.textPrimary);
  }
}
