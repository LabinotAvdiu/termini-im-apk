import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/ux_prefs_provider.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../appointments/data/models/appointment_model.dart';
import '../../../appointments/presentation/providers/appointments_provider.dart';
import '../providers/review_provider.dart';

/// Mobile full-screen submit review flow.
///
/// Preserved exactly from the original [SubmitReviewScreen] — zero-diff visual.
class SubmitReviewScreenMobile extends ConsumerStatefulWidget {
  final String appointmentId;

  const SubmitReviewScreenMobile({super.key, required this.appointmentId});

  @override
  ConsumerState<SubmitReviewScreenMobile> createState() =>
      _SubmitReviewScreenMobileState();
}

class _SubmitReviewScreenMobileState
    extends ConsumerState<SubmitReviewScreenMobile> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;
  final List<double> _starScales = List.filled(5, 1.0);

  @override
  void dispose() {
    _commentController.dispose();
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
      _starScales[index] = 1.15;
    });
    Future.delayed(const Duration(milliseconds: 150), () {
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
      SoundService.playSuccess(enabled: uxPrefs.soundsEnabled);

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar.modal(
        title: context.l10n.reviewSubmitTitle,
        onClose: () => context.pop(),
      ),
      body: _submitted
          ? _SuccessView(onClose: () => context.pop())
          : _FormView(
              appointment: appt,
              rating: _rating,
              starScales: _starScales,
              commentController: _commentController,
              isSubmitting: _isSubmitting,
              onTapStar: _onTapStar,
              onSubmit: _onSubmit,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form view
// ---------------------------------------------------------------------------

class _FormView extends StatelessWidget {
  final AppointmentModel? appointment;
  final int rating;
  final List<double> starScales;
  final TextEditingController commentController;
  final bool isSubmitting;
  final void Function(int) onTapStar;
  final VoidCallback onSubmit;

  const _FormView({
    required this.appointment,
    required this.rating,
    required this.starScales,
    required this.commentController,
    required this.isSubmitting,
    required this.onTapStar,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (appointment != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment!.companyName,
                          style: GoogleFonts.fraunces(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          appointment!.serviceName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          Text(
            context.l10n.reviewRatingLabel,
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < rating;
              return GestureDetector(
                onTap: () => onTapStar(i),
                child: AnimatedScale(
                  scale: starScales[i],
                  duration: const Duration(milliseconds: 150),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 48,
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

          const SizedBox(height: AppSpacing.xl),

          Text(
            context.l10n.reviewCommentLabel,
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          _CommentField(
            controller: commentController,
            hint: context.l10n.reviewCommentHint,
          ),

          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    rating > 0 ? AppColors.primary : AppColors.divider,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              onPressed: (rating > 0 && !isSubmitting) ? onSubmit : null,
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
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
// Comment field with char counter
// ---------------------------------------------------------------------------

class _CommentField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;

  const _CommentField({required this.controller, required this.hint});

  @override
  State<_CommentField> createState() => _CommentFieldState();
}

class _CommentFieldState extends State<_CommentField> {
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
          maxLines: 5,
          maxLength: 1000,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
              const SizedBox.shrink(),
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surface,
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
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
// Success view
// ---------------------------------------------------------------------------

class _SuccessView extends StatelessWidget {
  final VoidCallback onClose;

  const _SuccessView({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 44,
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
                    horizontal: AppSpacing.xl, vertical: 14),
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
      ),
    );
  }
}
