import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/ux_prefs_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';

/// Shows a modal dialog asking the owner to confirm cancellation of an
/// appointment (pending or confirmed), with an optional free-text reason.
///
/// Unlike rejection, cancellation FREES the slot and notifies the client.
/// Returns `{confirmed, reason}` or null if dismissed.
Future<({bool confirmed, String? reason})?> showCancelAppointmentOwnerDialog(
  BuildContext context, {
  required String clientName,
  bool isWalkIn = false,
}) {
  return showDialog<({bool confirmed, String? reason})>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => _CancelAppointmentOwnerDialog(
      clientName: clientName,
      isWalkIn: isWalkIn,
    ),
  );
}

class _CancelAppointmentOwnerDialog extends ConsumerStatefulWidget {
  final String clientName;
  final bool isWalkIn;

  const _CancelAppointmentOwnerDialog({
    required this.clientName,
    required this.isWalkIn,
  });

  @override
  ConsumerState<_CancelAppointmentOwnerDialog> createState() =>
      _CancelAppointmentOwnerDialogState();
}

class _CancelAppointmentOwnerDialogState
    extends ConsumerState<_CancelAppointmentOwnerDialog> {
  final _controller = TextEditingController();
  static const int _maxLength = 500;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onConfirm() {
    ref.read(uxPrefsProvider.notifier).mediumImpact();
    final reason =
        _controller.text.trim().isEmpty ? null : _controller.text.trim();
    Navigator.of(context).pop((confirmed: true, reason: reason));
  }

  void _onBack() {
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
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.cancelAppointmentOwnerTitle,
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                // Walk-ins drop the "will be notified" half — no user
                // account backing a walk-in, nobody to ping.
                widget.isWalkIn
                    ? l.cancelAppointmentOwnerSubtitleWalkIn(widget.clientName)
                    : l.cancelAppointmentOwnerSubtitle(widget.clientName),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Info banner — bordeaux atténué (slot sera libéré)
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
                      Icons.lock_open_rounded,
                      size: 16,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        // Walk-ins have no backing user account → drop the
                        // "client will be notified" half-sentence, keep only
                        // the "slot will be freed" part.
                        widget.isWalkIn
                            ? l.cancelAppointmentOwnerWarningWalkIn
                            : l.cancelAppointmentOwnerWarning,
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

              TextField(
                controller: _controller,
                maxLines: 3,
                maxLength: _maxLength,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: l.cancelAppointmentOwnerReasonLabel,
                  hintStyle: AppTextStyles.body.copyWith(
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(color: AppColors.border),
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

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _onBack,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm),
                      ),
                      child: Text(
                        l.back,
                        style: GoogleFonts.instrumentSans(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: _onConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: Text(
                        l.cancelAppointment,
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
