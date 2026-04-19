import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/appointment_model.dart';
import '../providers/appointments_provider.dart';

/// Bottom-sheet dialog to confirm and submit a client-side appointment
/// cancellation. Factorised so it can be reused from the appointment card
/// and from any future entry-point.
class CancelAppointmentDialog extends ConsumerStatefulWidget {
  final AppointmentModel appointment;

  const CancelAppointmentDialog({
    super.key,
    required this.appointment,
  });

  /// Convenience helper — shows the dialog as a modal bottom sheet.
  static Future<bool> show(
    BuildContext context,
    WidgetRef ref,
    AppointmentModel appointment,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CancelAppointmentDialog(appointment: appointment),
    );
    return result ?? false;
  }

  @override
  ConsumerState<CancelAppointmentDialog> createState() =>
      _CancelAppointmentDialogState();
}

class _CancelAppointmentDialogState
    extends ConsumerState<CancelAppointmentDialog> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDateTime(BuildContext context, DateTime dt) {
    final l = context.l10n;
    final dayNames = [
      l.monday, l.tuesday, l.wednesday, l.thursday,
      l.friday, l.saturday, l.sunday,
    ];
    final monthNames = [
      l.monthJan, l.monthFeb, l.monthMar, l.monthApr,
      l.monthMay, l.monthJun, l.monthJul, l.monthAug,
      l.monthSep, l.monthOct, l.monthNov, l.monthDec,
    ];
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dayNames[dt.weekday - 1]} ${dt.day} ${monthNames[dt.month - 1]} · $time';
  }

  Future<void> _onConfirm() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final reason = _reasonController.text.trim().isEmpty
        ? null
        : _reasonController.text.trim();

    final success = await ref
        .read(appointmentsProvider.notifier)
        .cancel(widget.appointment.id, reason: reason);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      // Pop with true to signal success to the parent.
      Navigator.of(context).pop(true);
      context.showSnackBar(context.l10n.appointmentCancelled);
    } else {
      // Attempt to build a message from the stored error.
      final state = ref.read(appointmentsProvider);
      final msg = state.error != null
          ? context.l10n.cancellationTooLate
          : context.l10n.actionFailed;
      context.showSnackBar(msg, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appt = widget.appointment;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title
          Text(
            context.l10n.cancelAppointmentTitle,
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Body
          Text(
            context.l10n.cancelAppointmentBody(
              appt.companyName,
              _formatDateTime(context, appt.dateTime),
            ),
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Reason field (optional)
          AppTextField(
            controller: _reasonController,
            label: context.l10n.cancelReasonLabel,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(context.l10n.back),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  onPressed: _isLoading ? null : _onConfirm,
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.surface,
                          ),
                        )
                      : Text(context.l10n.cancelAppointment),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
