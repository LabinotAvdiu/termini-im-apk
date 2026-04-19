import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/ux_prefs_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../appointments/data/models/appointment_model.dart';
import '../../../appointments/presentation/providers/appointments_provider.dart';
import '../providers/review_provider.dart';

// ---------------------------------------------------------------------------
// Desktop modal dialog — submit review
//
// Displayed via [showSubmitReviewDialog] rather than as a full-screen route.
// The dialog is max-width 560 px, max-height 75vh, surface ivoire, radius 24.
// ---------------------------------------------------------------------------

/// Opens a compact review dialog on desktop.
///
/// Call this from the appointments screen on desktop instead of navigating
/// to the route. Returns true if the review was submitted successfully.
Future<bool?> showSubmitReviewDialog(
  BuildContext context, {
  required String appointmentId,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: const Color(0xFF171311).withValues(alpha: 0.45),
    builder: (_) => _SubmitReviewDialog(appointmentId: appointmentId),
  );
}

class _SubmitReviewDialog extends ConsumerStatefulWidget {
  final String appointmentId;

  const _SubmitReviewDialog({required this.appointmentId});

  @override
  ConsumerState<_SubmitReviewDialog> createState() =>
      _SubmitReviewDialogState();
}

class _SubmitReviewDialogState extends ConsumerState<_SubmitReviewDialog>
    with SingleTickerProviderStateMixin {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  // Per-star scale for tap animation
  final List<double> _starScales = List.filled(5, 1.0);

  late final AnimationController _entryCtrl;
  late final Animation<double> _entryScale;
  late final Animation<double> _entryOpacity;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _entryScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
    );
    _entryOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  AppointmentModel? _findAppointment() {
    final appointments = ref.read(appointmentsProvider).appointments;
    try {
      return appointments.firstWhere((a) => a.id == widget.appointmentId);
    } catch (_) {
      return null;
    }
  }

  void _onTapStar(int index) {
    final uxPrefs = ref.read(uxPrefsProvider);
    if (uxPrefs.hapticEnabled) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _rating = index + 1;
      _starScales[index] = 1.2;
    });
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() => _starScales[index] = 1.0);
    });
  }

  Future<void> _onSubmit() async {
    if (_rating == 0 || _isSubmitting) return;

    final uxPrefs = ref.read(uxPrefsProvider);
    setState(() => _isSubmitting = true);

    try {
      final datasource = ref.read(reviewDatasourceProvider);
      final comment = _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim();

      await datasource.submitReview(
        widget.appointmentId,
        rating: _rating,
        comment: comment,
      );

      if (!mounted) return;

      if (uxPrefs.hapticEnabled) {
        await HapticFeedback.mediumImpact();
      }

      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });

      ref.invalidate(appointmentsProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      context.showErrorSnackBar(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appt = _findAppointment();
    final screenH = MediaQuery.sizeOf(context).height;

    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (context, child) {
        return FadeTransition(
          opacity: _entryOpacity,
          child: ScaleTransition(
            scale: _entryScale,
            child: child,
          ),
        );
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: screenH * 0.75,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF171311).withValues(alpha: 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _submitted
                ? _DesktopSuccessView(
                    onClose: () => Navigator.of(context).pop(true),
                  )
                : _DesktopFormContent(
                    appointment: appt,
                    rating: _rating,
                    starScales: _starScales,
                    commentController: _commentController,
                    isSubmitting: _isSubmitting,
                    onTapStar: _onTapStar,
                    onSubmit: _onSubmit,
                    onClose: () => Navigator.of(context).pop(false),
                  ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop form content
// ---------------------------------------------------------------------------

class _DesktopFormContent extends StatelessWidget {
  final AppointmentModel? appointment;
  final int rating;
  final List<double> starScales;
  final TextEditingController commentController;
  final bool isSubmitting;
  final void Function(int) onTapStar;
  final VoidCallback onSubmit;
  final VoidCallback onClose;

  const _DesktopFormContent({
    required this.appointment,
    required this.rating,
    required this.starScales,
    required this.commentController,
    required this.isSubmitting,
    required this.onTapStar,
    required this.onSubmit,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.reviewSubmitTitle,
                      style: GoogleFonts.fraunces(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (appointment != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        appointment!.companyName,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Close button
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          // Or divider
          Container(
            height: 1,
            color: AppColors.secondary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 24),

          // ── Rating section ───────────────────────────────────────────────
          Text(
            context.l10n.reviewRatingLabel,
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          // 5 stars — centered, 36px each
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < rating;
              return GestureDetector(
                onTap: () => onTapStar(i),
                child: AnimatedScale(
                  scale: starScales[i],
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 36,
                      color: filled ? AppColors.secondary : AppColors.divider,
                    ),
                  ),
                ),
              );
            }),
          ),

          if (rating > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                _ratingLabel(rating),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Comment section ──────────────────────────────────────────────
          Text(
            context.l10n.reviewCommentLabel,
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          _DesktopCommentField(
            controller: commentController,
            hint: context.l10n.reviewCommentHint,
          ),

          const SizedBox(height: 24),

          // ── Submit button ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    rating > 0 ? AppColors.primary : AppColors.divider,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              onPressed: (rating > 0 && !isSubmitting) ? onSubmit : null,
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.surface,
                      ),
                    )
                  : Text(
                      context.l10n.reviewSubmit,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _ratingLabel(int r) {
    const labels = ['', '★', '★★', '★★★', '★★★★', '★★★★★'];
    return labels[r];
  }
}

// ---------------------------------------------------------------------------
// Desktop comment field (maxLines 4 as per spec)
// ---------------------------------------------------------------------------

class _DesktopCommentField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;

  const _DesktopCommentField({required this.controller, required this.hint});

  @override
  State<_DesktopCommentField> createState() => _DesktopCommentFieldState();
}

class _DesktopCommentFieldState extends State<_DesktopCommentField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.controller.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: widget.controller,
          maxLines: 4,
          maxLength: 1000,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
              const SizedBox.shrink(),
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$count / 1000',
          style: AppTextStyles.caption.copyWith(
            color: count > 900 ? AppColors.error : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop success view (inside the dialog)
// ---------------------------------------------------------------------------

class _DesktopSuccessView extends StatelessWidget {
  final VoidCallback onClose;

  const _DesktopSuccessView({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              size: 38,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.reviewSubmitted,
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            onPressed: onClose,
            child: Text(
              context.l10n.back,
              style: AppTextStyles.subtitle.copyWith(color: AppColors.surface),
            ),
          ),
        ],
      ),
    );
  }
}
