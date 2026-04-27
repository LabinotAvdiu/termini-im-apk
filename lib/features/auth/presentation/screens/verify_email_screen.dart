import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../providers/auth_provider.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  // Six individual controllers + focus nodes for each OTP cell.
  final List<TextEditingController> _cells =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focuses = List.generate(6, (_) => FocusNode());

  // Resend cooldown — 60 seconds.
  static const _cooldownSeconds = 60;
  int _secondsLeft = 0;
  Timer? _cooldownTimer;

  // Toggled once the server accepts the code — swaps the form for a
  // success card with a "back to home" CTA.
  bool _verified = false;

  String get _code => _cells.map((c) => c.text).join();

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (final c in _cells) {
      c.dispose();
    }
    for (final f in _focuses) {
      f.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    final code = _code.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.verifyEmailCodeLength),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    final success =
        await ref.read(authStateProvider.notifier).verifyEmail(code: code);

    if (!mounted) return;
    if (success) {
      setState(() => _verified = true);
    } else {
      final error = ref.read(authStateProvider).error;
      if (error != null) context.showErrorSnackBar(error);
    }
  }

  // ---------------------------------------------------------------------------
  // Resend
  // ---------------------------------------------------------------------------

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;

    await ref.read(authStateProvider.notifier).resendVerification();
    if (!mounted) return;

    final error = ref.read(authStateProvider).error;
    if (error != null) {
      context.showErrorSnackBar(error);
      return;
    }

    // Start cooldown.
    setState(() => _secondsLeft = _cooldownSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) t.cancel();
      });
    });
  }

  // ---------------------------------------------------------------------------
  // OTP cell input handling
  // ---------------------------------------------------------------------------

  void _onCellChanged(int index, String value) {
    if (value.isEmpty) {
      // Backspace — move focus back.
      if (index > 0) {
        _focuses[index - 1].requestFocus();
      }
      setState(() {});
      return;
    }

    // Any value longer than one character is a paste (or a keystroke on
    // a cell that was already filled) — distribute across cells.
    if (value.length > 1) {
      _onCellPasted(value, index);
      return;
    }

    final char = value.toUpperCase();
    _cells[index].text = char;
    _cells[index].selection = TextSelection.fromPosition(
      const TextPosition(offset: 1),
    );

    if (index < 5) {
      _focuses[index + 1].requestFocus();
    } else {
      _focuses[index].unfocus();
    }
    setState(() {});
  }

  /// Distribute a multi-character value across the remaining cells. For a
  /// full 6-character paste we always fill from cell 0 (matches the user's
  /// expectation that pasting the whole code drops it in); shorter pastes
  /// fill from whichever cell had focus.
  void _onCellPasted(String pasted, int startIndex) {
    final cleaned = pasted
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    if (cleaned.isEmpty) {
      _cells[startIndex].text = '';
      setState(() {});
      return;
    }

    final startAt = cleaned.length >= 6 ? 0 : startIndex;
    final room = 6 - startAt;
    final take = cleaned.length > room ? room : cleaned.length;

    for (var i = 0; i < take; i++) {
      _cells[startAt + i].text = cleaned[i];
      _cells[startAt + i].selection = TextSelection.fromPosition(
        const TextPosition(offset: 1),
      );
    }

    final lastFilled = startAt + take - 1;
    if (lastFilled < 5) {
      _focuses[lastFilled + 1].requestFocus();
    } else {
      _focuses[5].unfocus();
    }
    setState(() {});

    // Auto-submit if the whole code is filled.
    if (_code.length == 6) {
      _submit();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(authStateProvider.select((s) => s.isLoading));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar.modal(
        title: context.l10n.verifyEmailTitle,
        onClose: () => context.canPop() ? context.pop() : null,
      ),
      body: Stack(
        children: [
          _BackgroundAccent(),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    _Header(email: widget.email),
                    const SizedBox(height: AppSpacing.xxl),
                    if (_verified)
                      _SuccessCard(
                        onBackHome: () {
                          // Return to wherever the user came from rather
                          // than always landing on /home — if they hit
                          // verify from the booking flow, /settings, or
                          // /my-salon, we want to drop them back there
                          // so they can continue where they left off.
                          // Falls back to /home only when no nav stack
                          // is available (deep link, fresh app launch).
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                      )
                    else
                      _OtpCard(
                        cells: _cells,
                        focuses: _focuses,
                        onCellChanged: _onCellChanged,
                        isLoading: isLoading,
                        onSubmit: _submit,
                        secondsLeft: _secondsLeft,
                        onResend: _resend,
                      ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
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
// Background decorative blob (mirrors login_screen pattern)
// ---------------------------------------------------------------------------

class _BackgroundAccent extends StatelessWidget {
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
              AppColors.primary.withValues(alpha: 0.13),
              AppColors.primary.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header — editorial icon + Fraunces headline
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final String email;

  const _Header({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Small icon container with a bourgogne envelope mark
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.mail_outline_rounded,
                color: AppColors.primary,
                size: 28,
              ),
              // Gold accent dot — upper right
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        Text(
          context.l10n.verifyEmailOverline,
          style: AppTextStyles.overline.copyWith(letterSpacing: 2.2),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Fraunces headline with italic serif accent on the period
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: context.l10n.verifyEmailTitle,
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                  height: 1.1,
                  letterSpacing: -0.56,
                ),
              ),
              TextSpan(
                text: '.',
                style: GoogleFonts.instrumentSerif(
                  fontSize: 28,
                  fontStyle: FontStyle.italic,
                  color: AppColors.secondary,
                  height: 1.1,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.sm),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            context.l10n.verifyEmailSubtitle(email),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// OTP card — 6 cells + confirm button + resend link
// ---------------------------------------------------------------------------

class _OtpCard extends StatelessWidget {
  final List<TextEditingController> cells;
  final List<FocusNode> focuses;
  final void Function(int index, String value) onCellChanged;
  final bool isLoading;
  final VoidCallback onSubmit;
  final int secondsLeft;
  final VoidCallback onResend;

  const _OtpCard({
    required this.cells,
    required this.focuses,
    required this.onCellChanged,
    required this.isLoading,
    required this.onSubmit,
    required this.secondsLeft,
    required this.onResend,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.verifyEmailTitle.toUpperCase(),
            style: AppTextStyles.overline.copyWith(letterSpacing: 1.8),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.verifyEmailTitle,
            style: AppTextStyles.h2.copyWith(fontSize: 20),
          ),
          const SizedBox(height: AppSpacing.lg),

          // OTP cells row
          _OtpRow(
            cells: cells,
            focuses: focuses,
            onCellChanged: onCellChanged,
          ),

          const SizedBox(height: AppSpacing.xl),

          AppButton(
            text: context.l10n.verifyEmailConfirm,
            isLoading: isLoading,
            onPressed: isLoading ? null : onSubmit,
            width: double.infinity,
            icon: Icons.check_rounded,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Resend link — centered, disabled during cooldown
          Center(
            child: GestureDetector(
              onTap: secondsLeft > 0 ? null : onResend,
              child: Text(
                secondsLeft > 0
                    ? context.l10n.verifyEmailResendCooldown(secondsLeft)
                    : context.l10n.verifyEmailResend,
                style: secondsLeft > 0
                    ? AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      )
                    : GoogleFonts.instrumentSerif(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
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
// OTP row — 6 individual styled cells
// ---------------------------------------------------------------------------

class _OtpRow extends StatelessWidget {
  final List<TextEditingController> cells;
  final List<FocusNode> focuses;
  final void Function(int index, String value) onCellChanged;

  const _OtpRow({
    required this.cells,
    required this.focuses,
    required this.onCellChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return _OtpCell(
          controller: cells[i],
          focusNode: focuses[i],
          onChanged: (v) => onCellChanged(i, v),
        );
      }),
    );
  }
}

class _OtpCell extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpCell({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  State<_OtpCell> createState() => _OtpCellState();
}

class _OtpCellState extends State<_OtpCell> {
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _hasFocus = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.controller.text.isNotEmpty;

    return SizedBox(
      width: 44,
      height: 54,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: filled
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: _hasFocus
                ? AppColors.primary
                : filled
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.border,
            width: _hasFocus ? 1.5 : 1,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          // No maxLength — otherwise the framework truncates a pasted
          // 6-character code down to 1 char before onChanged fires, and
          // the paste detection never sees the full string.
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          ],
          style: GoogleFonts.instrumentSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            letterSpacing: 0,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success card — shown in place of the OTP card once the code is accepted.
// Mirrors the editorial style of the rest of the auth flow: ivory surface,
// gold accent ring around the check, Fraunces title + italic serif period,
// bourgogne primary CTA to return to the home feed.
// ---------------------------------------------------------------------------

class _SuccessCard extends StatelessWidget {
  final VoidCallback onBackHome;

  const _SuccessCard({required this.onBackHome});

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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Check inside a bourgogne disc, surrounded by a soft gold ring.
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.12),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.surface,
                  size: 34,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.verifyEmailOverline,
            textAlign: TextAlign.center,
            style: AppTextStyles.overline.copyWith(letterSpacing: 2.2),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Fraunces title with italic serif period — matches the auth header.
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: context.l10n.verifyEmailSuccessTitle,
                  style: GoogleFonts.fraunces(
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    height: 1.1,
                    letterSpacing: -0.52,
                  ),
                ),
                TextSpan(
                  text: '.',
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 26,
                    fontStyle: FontStyle.italic,
                    color: AppColors.secondary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              context.l10n.verifyEmailSuccessMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: context.l10n.verifyEmailSuccessCta,
            onPressed: onBackHome,
            width: double.infinity,
            icon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }
}
