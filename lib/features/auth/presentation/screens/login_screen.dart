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
import '../../../../core/widgets/language_sheet.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  // TODO: Remove default values before push
  final _emailController = TextEditingController(text: 'test2@test.com');
  final _passwordController = TextEditingController(text: 'Password1');
  bool _passwordVisible = false;

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
    final error = ref.read(authStateProvider).error;
    if (error != null) {
      // Clear only the password field, keep the email
      _passwordController.clear();
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
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Top decorative gradient arc
          _TopGradientDecoration(),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),

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
                    isLoading: isLoading,
                    onSubmit: _submit,
                    rememberMe: authState.rememberMe,
                    onToggleRememberMe: () =>
                        ref.read(authStateProvider.notifier).toggleRememberMe(),
                    errorMessage: authState.error,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ---- Divider "ou continuer avec" ----
                  _OrDivider(),

                  const SizedBox(height: AppSpacing.lg),

                  // ---- Social buttons ----
                  AppSocialButton(
                    text: context.l10n.continueWithGoogle,
                    onPressed: isLoading ? null : _loginWithGoogle,
                    icon: const _GoogleIcon(),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  AppSocialButton(
                    text: context.l10n.continueWithFacebook,
                    onPressed: isLoading ? null : _loginWithFacebook,
                    icon: const _FacebookIcon(),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ---- Sign-up link ----
                  _SignupLink(),

                  const SizedBox(height: AppSpacing.lg),
                ],
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
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.content_cut_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Termini im',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.loginSubtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
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
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
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
                onTap: () => context.go('/forgot-password'),
                child: Text(
                  context.l10n.forgotPassword,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
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
          style: AppTextStyles.body,
        ),
        GestureDetector(
          onTap: () => context.goNamed(RouteNames.roleSelect),
          child: Text(
            context.l10n.signupNow,
            style: const TextStyle(
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
    // Standard Google G arc: starts at ~-21° and sweeps 360° split into 4 segments
    const double toRad = 3.14159265 / 180.0;
    final segments = [
      // [startDeg, sweepDeg, color]
      [-21.0, 90.0, const Color(0xFFEA4335)],  // Red    (top-right → bottom-right)
      [69.0,  90.0, const Color(0xFFFBBC05)],  // Yellow (bottom-right → bottom-left)
      [159.0, 90.0, const Color(0xFF34A853)],  // Green  (bottom-left → top-left)
      [249.0, 90.0, const Color(0xFF4285F4)],  // Blue   (top-left → top-right)
    ];

    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
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

    // Bar sits in the right half, vertically centered, inset from center
    final barTop = cy - strokeWidth * 0.38;
    final barBottom = cy + strokeWidth * 0.38;
    final barLeft = cx - 0.5;          // starts at center
    final barRight = cx + innerR + 0.5; // reaches outer edge of ring

    // Clip to right semicircle so bar doesn't bleed left
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
    final rr = size.width * 0.22; // corner radius

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
    final crossH = h * 0.10;
    final crossTop = h * 0.48;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.28, crossTop, w * 0.42, crossH),
      paint,
    );

    // Rounded cap on top of stem (the arc of the f)
    final capPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = stemW
      ..strokeCap = StrokeCap.round;

    final capCenter = Offset(stemLeft + stemW * 2.2, stemTop);
    canvas.drawArc(
      Rect.fromCircle(center: capCenter, radius: stemW * 1.5),
      3.14159,
      3.14159,
      false,
      capPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
