import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/ux_prefs_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';

/// Shows a modal dialog asking the owner to confirm rejection of an appointment,
/// with an optional free-text reason field.
///
/// Returns a record `{confirmed, reason}` or null if the dialog was dismissed.
Future<({bool confirmed, String? reason})?> showRejectAppointmentDialog(
  BuildContext context, {
  required String clientName,
}) {
  return showDialog<({bool confirmed, String? reason})>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => _RejectAppointmentDialog(clientName: clientName),
  );
}

// ---------------------------------------------------------------------------
// Internal widget
// ---------------------------------------------------------------------------

class _RejectAppointmentDialog extends ConsumerStatefulWidget {
  final String clientName;

  const _RejectAppointmentDialog({required this.clientName});

  @override
  ConsumerState<_RejectAppointmentDialog> createState() =>
      _RejectAppointmentDialogState();
}

class _RejectAppointmentDialogState
    extends ConsumerState<_RejectAppointmentDialog> {
  final _controller = TextEditingController();
  static const int _maxLength = 500;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onReject() {
    ref.read(uxPrefsProvider.notifier).mediumImpact();
    final reason = _controller.text.trim().isEmpty ? null : _controller.text.trim();
    Navigator.of(context).pop((confirmed: true, reason: reason));
  }

  void _onCancel() {
    Navigator.of(context).pop((confirmed: false, reason: null));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: isWide
          ? const EdgeInsets.symmetric(horizontal: 0, vertical: 0)
          : const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                l.rejectAppointmentTitle,
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Subtitle
              Text(
                l.rejectAppointmentSubtitle(widget.clientName),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Warning banner — bordeaux très atténué
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l.rejectAppointmentWarning,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Reason text field
              TextField(
                controller: _controller,
                maxLines: 3,
                maxLength: _maxLength,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: l.rejectAppointmentReasonLabel,
                  hintStyle: AppTextStyles.body.copyWith(
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(AppSpacing.sm),
                  counterStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm),
                      ),
                      child: Text(
                        l.cancel,
                        style: GoogleFonts.instrumentSans(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: _onReject,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: Text(
                        l.rejectAppointmentButton,
                        style: GoogleFonts.instrumentSans(
                          fontWeight: FontWeight.w600,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
