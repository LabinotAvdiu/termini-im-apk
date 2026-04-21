import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../employee_schedule/data/models/schedule_settings_models.dart';

/// Shared "Ajouter un congé" modal + conflict block.
///
/// Used from :
///   - `ScheduleSettingsScreen` (individual mode → `/my-schedule/days-off`)
///   - Company settings (capacity mode → `/my-company/days-off`)
///
/// The modal is intentionally screen-agnostic : the caller wires [onSubmit]
/// to whatever provider it needs and interprets the returned [AddDayOffResult].
///
/// Design spec : `design-proposals/add-day-off-modal.html`.

/// Helper that pushes the modal with the correct barrier behaviour.
/// Returns the [AddDayOffResult] returned by the last [onSubmit] attempt,
/// or null if the user dismissed the modal.
Future<AddDayOffResult?> showAddDayOffDialog(
  BuildContext context, {
  required Future<AddDayOffResult> Function(AddDayOffRequest) onSubmit,
}) async {
  AddDayOffResult? lastResult;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => AddDayOffDialog(
      onSubmit: (req) async {
        final r = await onSubmit(req);
        lastResult = r;
        if (r is AddDayOffSuccess && Navigator.of(dialogCtx).canPop()) {
          Navigator.of(dialogCtx).pop();
        }
        return r;
      },
    ),
  );
  return lastResult;
}

/// Public for tests / direct usage. Prefer [showAddDayOffDialog] in screens.
class AddDayOffDialog extends StatefulWidget {
  /// Submit handler — must call the provider and return the structured result.
  final Future<AddDayOffResult> Function(AddDayOffRequest) onSubmit;

  const AddDayOffDialog({super.key, required this.onSubmit});

  @override
  State<AddDayOffDialog> createState() => _AddDayOffDialogState();
}

class _AddDayOffDialogState extends State<AddDayOffDialog> {
  final _reasonCtrl = TextEditingController();
  late DateTime _startDate;
  late DateTime _untilDate;
  bool _isSubmitting = false;
  List<ScheduleConflictAppointment>? _conflicts;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _startDate = DateTime(today.year, today.month, today.day);
    _untilDate = _startDate;
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: _pickerTheme,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_untilDate.isBefore(picked)) _untilDate = picked;
        _conflicts = null;
      });
    }
  }

  Future<void> _pickUntilDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _untilDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365)),
      builder: _pickerTheme,
    );
    if (picked != null) {
      setState(() {
        _untilDate = picked;
        _conflicts = null;
      });
    }
  }

  Widget _pickerTheme(BuildContext ctx, Widget? child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      );

  String _iso(DateTime d) =>
      '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  int get _dayCount => _untilDate.difference(_startDate).inDays + 1;
  bool get _isRange => !_isSameDay(_startDate, _untilDate);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _conflicts = null;
    });
    final request = AddDayOffRequest(
      date: _iso(_startDate),
      untilDate: _isRange ? _iso(_untilDate) : null,
      reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
    );
    final result = await widget.onSubmit(request);
    if (!mounted) return;

    switch (result) {
      case AddDayOffSuccess():
        // Caller pops the dialog.
        break;
      case AddDayOffConflict(:final conflicts):
        setState(() {
          _conflicts = conflicts;
          _isSubmitting = false;
        });
      case AddDayOffError():
        setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasConflict = _conflicts != null && _conflicts!.isNotEmpty;
    final disabled = _isSubmitting || hasConflict;
    final l = context.l10n;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.13), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.28),
                blurRadius: 48,
                offset: const Offset(0, 24),
              ),
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DayOffHeader(onClose: () => Navigator.of(context).pop()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md + 4,
                    AppSpacing.md,
                    AppSpacing.md + 4,
                    AppSpacing.md + 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FieldGroupLabel(
                        prefixItalic: l.fromDate.toLowerCase(),
                        suffixText: l.untilDate.toLowerCase(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _DatePickerTile(
                              label: l.fromDate,
                              date: _startDate,
                              onTap: _pickStartDate,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const _DateArrow(),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DatePickerTile(
                              label: l.untilDate,
                              date: _untilDate,
                              onTap: _pickUntilDate,
                              dimmed: !_isRange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PreviewBadge(
                        days: _dayCount,
                        startDate: _startDate,
                        untilDate: _untilDate,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FieldGroupLabel(text: l.reason),
                      const SizedBox(height: AppSpacing.xs + 2),
                      _ReasonField(
                        controller: _reasonCtrl,
                        hint: l.dayOffReasonHint,
                        optionalLabel: l.optional.toUpperCase(),
                      ),
                      if (hasConflict) ...[
                        const SizedBox(height: AppSpacing.md),
                        ScheduleConflictBlock(conflicts: _conflicts!),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      const _EditorialRule(),
                      const SizedBox(height: AppSpacing.md),
                      _DayOffConfirmButton(
                        label: l.confirmClosure,
                        isSubmitting: _isSubmitting,
                        onPressed: disabled ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header — bordeaux accent stripe + kicker + Fraunces title + subtitle
// ---------------------------------------------------------------------------

class _DayOffHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _DayOffHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md + 4,
            AppSpacing.md + 6,
            AppSpacing.md + 4,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Text(
                    l.closureKicker.toUpperCase(),
                    style: GoogleFonts.instrumentSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.8,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    height: 1.05,
                    letterSpacing: -0.36,
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    TextSpan(text: '${l.addDayOffPrefix} '),
                    TextSpan(
                      text: l.addDayOffAccent,
                      style: GoogleFonts.instrumentSerif(
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                l.closureSubtitle,
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  color: AppColors.textHint,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 14,
          right: 14,
          child: Material(
            color: AppColors.background,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClose,
              child: const SizedBox(
                width: 28,
                height: 28,
                child: Icon(Icons.close_rounded,
                    size: 14, color: AppColors.textHint),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldGroupLabel extends StatelessWidget {
  final String? text;
  final String? prefixItalic;
  final String? suffixText;
  const _FieldGroupLabel({this.text, this.prefixItalic, this.suffixText});

  @override
  Widget build(BuildContext context) {
    if (text != null) {
      return Text(
        text!.toUpperCase(),
        style: GoogleFonts.instrumentSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0,
          color: AppColors.textHint,
        ),
      );
    }
    return RichText(
      text: TextSpan(
        style: GoogleFonts.instrumentSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0,
          color: AppColors.textHint,
        ),
        children: [
          TextSpan(
            text: prefixItalic,
            style: GoogleFonts.instrumentSerif(
              fontStyle: FontStyle.italic,
              fontSize: 13,
              letterSpacing: 0,
              color: AppColors.primary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const TextSpan(text: '   ·   '),
          TextSpan(text: suffixText?.toUpperCase()),
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  final bool dimmed;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onTap,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = dimmed
        ? AppColors.border.withValues(alpha: 0.7)
        : AppColors.primary.withValues(alpha: 0.55);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 16, color: AppColors.textHint),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.instrumentSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                      color: AppColors.textHint,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    FrenchDateFormatter.compact(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fraunces(
                      fontSize: 15,
                      letterSpacing: -0.15,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.expand_more_rounded,
                size: 16, color: AppColors.textHint.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

class _DateArrow extends StatelessWidget {
  const _DateArrow();

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.arrow_forward_rounded,
        size: 16, color: AppColors.textHint.withValues(alpha: 0.6));
  }
}

class _PreviewBadge extends StatelessWidget {
  final int days;
  final DateTime startDate;
  final DateTime untilDate;

  const _PreviewBadge({
    required this.days,
    required this.startDate,
    required this.untilDate,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isRange = !(startDate.year == untilDate.year &&
        startDate.month == untilDate.month &&
        startDate.day == untilDate.day);
    final range = isRange
        ? '${FrenchDateFormatter.compact(startDate)} → '
            '${FrenchDateFormatter.compactWithYear(untilDate)}'
        : FrenchDateFormatter.full(startDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.04),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.schedule_rounded,
                size: 15, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.fraunces(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    ),
                    children: [
                      TextSpan(
                        text: l.dayOffRangePreview(days),
                        style: GoogleFonts.instrumentSerif(
                          fontStyle: FontStyle.italic,
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextSpan(text: ' ${l.ofClosure}'),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  range,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String optionalLabel;

  const _ReasonField({
    required this.controller,
    required this.hint,
    required this.optionalLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 78),
            child: TextField(
              controller: controller,
              style: GoogleFonts.instrumentSans(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                border: InputBorder.none,
                hintText: hint,
                hintStyle: GoogleFonts.instrumentSans(
                    fontSize: 13, color: AppColors.textHint),
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                optionalLabel,
                style: GoogleFonts.instrumentSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: AppColors.textHint.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorialRule extends StatelessWidget {
  const _EditorialRule();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(height: 1, color: AppColors.border),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.divider,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayOffConfirmButton extends StatelessWidget {
  final String label;
  final bool isSubmitting;
  final VoidCallback? onPressed;

  const _DayOffConfirmButton({
    required this.label,
    required this.isSubmitting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isSubmitting;
    return SizedBox(
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: -6,
                  ),
                ]
              : const [],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                AppColors.textHint.withValues(alpha: 0.35),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            padding: EdgeInsets.zero,
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded, size: 16),
                    const SizedBox(width: 10),
                    Text(
                      label.toUpperCase(),
                      style: GoogleFonts.instrumentSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// French date formatter (screen-local — intl is available but not initialised
// app-wide yet).
// ---------------------------------------------------------------------------

class FrenchDateFormatter {
  static const _months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  static const _weekdaysLong = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi',
    'Vendredi', 'Samedi', 'Dimanche',
  ];
  static const _weekdaysShort = [
    'Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.',
  ];

  /// "Lun. 28 avril"
  static String compact(DateTime d) {
    final w = _weekdaysShort[d.weekday - 1];
    final m = _months[d.month - 1];
    return '$w ${d.day} $m';
  }

  /// "Lun. 28 avril 2026"
  static String compactWithYear(DateTime d) => '${compact(d)} ${d.year}';

  /// "Lundi 28 avril 2026"
  static String full(DateTime d) {
    final w = _weekdaysLong[d.weekday - 1];
    final m = _months[d.month - 1];
    return '$w ${d.day} $m ${d.year}';
  }

  /// "Lun. 28 · 09h30" — used in the conflict row.
  static String conflictWhen(String isoDate, String hhmm) {
    try {
      final d = DateTime.parse('${isoDate}T00:00:00');
      final w = _weekdaysShort[d.weekday - 1];
      final time = hhmm.replaceAll(':', 'h');
      return '$w ${d.day} · $time';
    } catch (_) {
      return '$isoDate · $hhmm';
    }
  }
}

// ---------------------------------------------------------------------------
// Conflict block — shared between break + day-off modals
// ---------------------------------------------------------------------------

class ScheduleConflictBlock extends StatelessWidget {
  final List<ScheduleConflictAppointment> conflicts;
  /// When true, renders the break-conflict title instead of the day-off title.
  final bool isBreakConflict;

  const ScheduleConflictBlock({
    super.key,
    required this.conflicts,
    this.isBreakConflict = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final shown = conflicts.take(5).toList();
    final extra = conflicts.length - shown.length;
    final title = isBreakConflict
        ? l.breakConflictTitle
        : l.dayOffConflictTitle(conflicts.length);
    final hint = isBreakConflict ? l.breakConflictHint : l.dayOffConflictHint;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDF3F3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded,
                      size: 13, color: AppColors.error),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.fraunces(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.error,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hint,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 12,
                          color: AppColors.textHint,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
              height: 1, color: AppColors.error.withValues(alpha: 0.22)),
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0)
              Container(
                  height: 1, color: AppColors.error.withValues(alpha: 0.10)),
            _ConflictRow(appt: shown[i]),
          ],
          if (extra > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Text(
                l.andNOthers(extra),
                style: GoogleFonts.instrumentSerif(
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                  color: AppColors.error.withValues(alpha: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConflictRow extends StatelessWidget {
  final ScheduleConflictAppointment appt;
  const _ConflictRow({required this.appt});

  @override
  Widget build(BuildContext context) {
    final client = appt.clientFullName.isEmpty ? '—' : appt.clientFullName;
    final service = appt.serviceName;
    final tail = service != null && service.isNotEmpty
        ? '$client — $service'
        : client;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              FrenchDateFormatter.conflictWhen(appt.date, appt.startTime),
              style: GoogleFonts.fraunces(
                fontSize: 13,
                color: AppColors.error,
                height: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              tail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.instrumentSans(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Break-conflict soft confirm — used after a 409 on POST /breaks.
// Returns true when the user wants to save anyway (→ retry with force=true).
// ---------------------------------------------------------------------------

Future<bool> showBreakConflictDialog(
  BuildContext context,
  List<ScheduleConflictAppointment> conflicts,
) async {
  final l = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      title: Text(
        l.breakConflictTitle,
        style: GoogleFonts.fraunces(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColors.error,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.breakConflictMessage(conflicts.length)),
            const SizedBox(height: AppSpacing.sm),
            ScheduleConflictBlock(
              conflicts: conflicts,
              isBreakConflict: true,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(l.breakConflictContinue),
        ),
      ],
    ),
  );
  return result ?? false;
}
