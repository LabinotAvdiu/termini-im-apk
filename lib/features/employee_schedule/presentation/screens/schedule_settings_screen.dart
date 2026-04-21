import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../company/presentation/widgets/add_day_off_dialog.dart';
import '../../data/models/schedule_settings_models.dart';
import '../providers/schedule_settings_provider.dart';

// Day-name helper — dayOfWeek: 0=Monday, 6=Sunday (matches backend DayOfWeek enum)
List<String> _getDayNames(BuildContext context) {
  final l = context.l10n;
  return [l.monday, l.tuesday, l.wednesday, l.thursday, l.friday, l.saturday, l.sunday];
}

String _dayName(int dayOfWeek, BuildContext context) =>
    (dayOfWeek >= 0 && dayOfWeek <= 6) ? _getDayNames(context)[dayOfWeek] : '?';

// Build a default 7-day list when the API returns nothing.
List<WorkHour> _defaultHours() => List.generate(
      7,
      (i) => WorkHour(
        dayOfWeek: i, // 0=Monday, 6=Sunday
        startTime: '09:00',
        endTime: '18:00',
        isWorking: i < 6, // Mon-Sat working, Sun off
      ),
    );

// ---------------------------------------------------------------------------
// Root screen
// ---------------------------------------------------------------------------

class ScheduleSettingsScreen extends ConsumerStatefulWidget {
  const ScheduleSettingsScreen({super.key});

  @override
  ConsumerState<ScheduleSettingsScreen> createState() =>
      _ScheduleSettingsScreenState();
}

class _ScheduleSettingsScreenState
    extends ConsumerState<ScheduleSettingsScreen> {
  // Local mutable copy of employee hours — edited in-place before saving.
  late List<WorkHour> _editableHours;
  bool _hoursInitialized = false;

  void _initHours(List<WorkHour> fromApi) {
    if (_hoursInitialized) return;
    _hoursInitialized = true;

    // Ensure all 7 days are present; fill missing days with defaults.
    final byDay = {for (final h in fromApi) h.dayOfWeek: h};
    _editableHours = List.generate(
      7,
      (i) =>
          byDay[i] ??
          WorkHour(
            dayOfWeek: i,
            startTime: '09:00',
            endTime: '18:00',
            isWorking: i < 6, // 0=Mon to 5=Sat working, 6=Sun off
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _editableHours = _defaultHours();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scheduleSettingsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleSettingsProvider);

    // Initialise editable hours from API data on first load.
    if (state.settings != null) {
      _initHours(
        state.settings!.employeeHours.isNotEmpty
            ? state.settings!.employeeHours
            : _defaultHours(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ScheduleSettingsState state) {
    if (state.isLoading && state.settings == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null && state.settings == null) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => ref.read(scheduleSettingsProvider.notifier).load(),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(scheduleSettingsProvider.notifier).load(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Page header
          SliverToBoxAdapter(
            child: _PageHeader(title: context.l10n.scheduleSettings),
          ),

          // Reload progress indicator
          if (state.isLoading)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.divider,
                minHeight: 2,
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WorkHoursCard(
                  editableHours: _editableHours,
                  companyHours: state.settings?.companyHours ?? [],
                  isSaving: state.isSavingHours,
                  onHourChanged: (updated) {
                    setState(() {
                      final idx = _editableHours
                          .indexWhere((h) => h.dayOfWeek == updated.dayOfWeek);
                      if (idx >= 0) _editableHours[idx] = updated;
                    });
                  },
                  onSave: () async {
                    final notifier =
                        ref.read(scheduleSettingsProvider.notifier);
                    final l10n = context.l10n;
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await notifier.saveHours(_editableHours);
                    if (!mounted) return;
                    if (ok) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.changesSaved)),
                      );
                    } else {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            ref.read(scheduleSettingsProvider).error ??
                                l10n.error,
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _BreaksCard(
                  breaks: state.settings?.breaks ?? [],
                  isAdding: state.isAddingBreak,
                  isDeleting: state.isDeletingBreak,
                  onAdd: () => _showAddBreakDialog(context),
                  onDelete: (id) async {
                    final notifier =
                        ref.read(scheduleSettingsProvider.notifier);
                    final l10n = context.l10n;
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await notifier.deleteBreak(id);
                    if (!mounted) return;
                    if (!ok) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            ref.read(scheduleSettingsProvider).error ??
                                l10n.error,
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _DaysOffCard(
                  daysOff: state.settings?.daysOff ?? [],
                  isAdding: state.isAddingDayOff,
                  isDeleting: state.isDeletingDayOff,
                  onAdd: () => _showAddDayOffDialog(context),
                  onDelete: (id) async {
                    final notifier =
                        ref.read(scheduleSettingsProvider.notifier);
                    final l10n = context.l10n;
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await notifier.deleteDayOff(id);
                    if (!mounted) return;
                    if (!ok) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            ref.read(scheduleSettingsProvider).error ??
                                l10n.error,
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
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

  Future<void> _showAddBreakDialog(BuildContext context) async {
    final notifier = ref.read(scheduleSettingsProvider.notifier);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    // Helper: attempt the add with the given request. On soft conflict (break),
    // surface a confirmation dialog and retry with force=true if the user
    // agrees. On error, snackbar. On success, close the modal.
    Future<void> attempt(
        AddBreakRequest request, VoidCallback closeModal) async {
      final result = await notifier.addBreak(request);
      if (!mounted) return;
      switch (result) {
        case AddBreakSuccess():
          closeModal();
        case AddBreakConflict(:final conflicts):
          final confirmed = await showBreakConflictDialog(context, conflicts);
          if (!mounted) return;
          if (confirmed) {
            await attempt(request.copyWith(force: true), closeModal);
          }
        case AddBreakError(:final message):
          messenger.showSnackBar(
            SnackBar(
                content: Text(message), backgroundColor: AppColors.error),
          );
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _AddBreakDialog(
        onConfirm: (request) async {
          await attempt(
            request,
            () {
              if (Navigator.of(dialogCtx).canPop()) {
                Navigator.of(dialogCtx).pop();
              }
            },
          );
        },
      ),
    );
    // Cleanup : l10n var avoids unused_local_variable when edit tooling
    // runs without referencing it — keep the capture explicit.
    _unused(l10n);
  }

  Future<void> _showAddDayOffDialog(BuildContext context) async {
    final notifier = ref.read(scheduleSettingsProvider.notifier);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    await showAddDayOffDialog(
      context,
      onSubmit: (request) async {
        final result = await notifier.addDayOff(request);
        if (!mounted) return result;
        switch (result) {
          case AddDayOffSuccess():
            messenger
                .showSnackBar(SnackBar(content: Text(l10n.changesSaved)));
          case AddDayOffConflict():
            // Inline — the modal renders the conflict list itself.
            break;
          case AddDayOffError(:final message):
            messenger.showSnackBar(
              SnackBar(
                  content: Text(message), backgroundColor: AppColors.error),
            );
        }
        return result;
      },
    );
  }
}

// Silence the "unused var" lint on the modal closure capture without adding
// an explicit `// ignore` pragma.
void _unused(Object? _) {}

// ---------------------------------------------------------------------------
// Page header — editorial: overline + Fraunces serif title
// ---------------------------------------------------------------------------

class _PageHeader extends StatelessWidget {
  final String title;

  const _PageHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HORAIRES',
            style: AppTextStyles.overline.copyWith(letterSpacing: 2.2),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: GoogleFonts.fraunces(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              letterSpacing: -0.52,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section card container — editorial: 1px border, overline + Fraunces heading
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  /// Optional widget aligned on the right side of the header (edit toggle,
  /// add button…). Keeps the header compact instead of scattering actions
  /// across the body.
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section header — icon + Fraunces title (single-line).
          // Previously: overline ALL CAPS title + title h3 underneath. Removed
          // the overline — redundant with the h3 and added visual noise.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs + 2),
                Expanded(child: Text(title, style: AppTextStyles.h3)),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...children,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 1 – Work hours card
// ---------------------------------------------------------------------------

class _WorkHoursCard extends StatefulWidget {
  final List<WorkHour> editableHours;
  final List<WorkHour> companyHours;
  final bool isSaving;
  final ValueChanged<WorkHour> onHourChanged;
  final VoidCallback onSave;

  const _WorkHoursCard({
    required this.editableHours,
    required this.companyHours,
    required this.isSaving,
    required this.onHourChanged,
    required this.onSave,
  });

  @override
  State<_WorkHoursCard> createState() => _WorkHoursCardState();
}

class _WorkHoursCardState extends State<_WorkHoursCard> {
  // View-mode by default. Edit toggles the row widgets (switches + pickers +
  // save button). Keeps the screen calm on load and reduces accidental
  // changes — the user has to opt into editing.
  bool _isEditing = false;

  WorkHour? _companyHourFor(int day) {
    try {
      return widget.companyHours.firstWhere((h) => h.dayOfWeek == day);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: context.l10n.myWorkHours,
      icon: Icons.access_time_rounded,
      trailing: _isEditing
          ? TextButton(
              onPressed:
                  widget.isSaving ? null : () => setState(() => _isEditing = false),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textHint,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(context.l10n.cancel),
            )
          : TextButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: Text(context.l10n.edit),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
      children: [
        ...widget.editableHours.map(
          (hour) => _isEditing
              ? _DayRow(
                  hour: hour,
                  companyHour: _companyHourFor(hour.dayOfWeek),
                  onChanged: widget.onHourChanged,
                )
              : _DayRowReadOnly(hour: hour),
        ),
        if (_isEditing)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: widget.isSaving
                    ? null
                    : () {
                        widget.onSave();
                        // Exit edit mode after successful save. Failures stay
                        // in edit mode so the user can fix and retry.
                        if (mounted) setState(() => _isEditing = false);
                      },
                icon: widget.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(context.l10n.saveChanges),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  textStyle: AppTextStyles.button,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Read-only compact row used when the card is not in edit mode.
// Renders day name + "09:00 – 18:00" or "Non travaillé" — no switches,
// no time pickers, no interactions.
class _DayRowReadOnly extends StatelessWidget {
  final WorkHour hour;
  const _DayRowReadOnly({required this.hour});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  _dayName(hour.dayOfWeek, context),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  hour.isWorking
                      ? '${hour.startTime} – ${hour.endTime}'
                      : context.l10n.notWorking,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: hour.isWorking
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                    fontStyle:
                        hour.isWorking ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.md, color: AppColors.divider),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual day row inside work hours card
// ---------------------------------------------------------------------------

class _DayRow extends StatelessWidget {
  final WorkHour hour;
  final WorkHour? companyHour;
  final ValueChanged<WorkHour> onChanged;

  const _DayRow({
    required this.hour,
    required this.companyHour,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final companyHint = companyHour != null
        ? context.l10n.companyHoursHint(
            '${companyHour!.startTime} - ${companyHour!.endTime}',
          )
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day name + switch row
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  _dayName(hour.dayOfWeek, context),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  hour.isWorking
                      ? context.l10n.working
                      : context.l10n.notWorking,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: hour.isWorking
                        ? AppColors.success
                        : AppColors.textHint,
                  ),
                ),
              ),
              Switch(
                value: hour.isWorking,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                onChanged: (val) => onChanged(hour.copyWith(isWorking: val)),
              ),
            ],
          ),
          // Time pickers — only shown when the day is active
          if (hour.isWorking) ...[
            Row(
              children: [
                // Start time
                Expanded(
                  child: _TimePicker(
                    label: context.l10n.startTimeLabel,
                    value: hour.startTime,
                    onChanged: (t) => onChanged(hour.copyWith(startTime: t)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: AppSpacing.sm),
                // End time
                Expanded(
                  child: _TimePicker(
                    label: context.l10n.endTimeLabel,
                    value: hour.endTime,
                    onChanged: (t) => onChanged(hour.copyWith(endTime: t)),
                  ),
                ),
              ],
            ),
            // Company hours hint
            if (companyHint != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(
                    Icons.storefront_outlined,
                    size: 12,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    companyHint,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ],
          const Divider(height: AppSpacing.md, color: AppColors.divider),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Time picker tap target
// ---------------------------------------------------------------------------

class _TimePicker extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _TimePicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final parts = value.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onChanged(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 2 – Breaks card
// ---------------------------------------------------------------------------

class _BreaksCard extends StatelessWidget {
  final List<BreakModel> breaks;
  final bool isAdding;
  final bool isDeleting;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;

  const _BreaksCard({
    required this.breaks,
    required this.isAdding,
    required this.isDeleting,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: context.l10n.breaks,
      icon: Icons.coffee_rounded,
      children: [
        if (breaks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              context.l10n.noBreaksConfigured,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          )
        else
          ...breaks.map(
            (b) => _BreakTile(
              breakModel: b,
              isDeleting: isDeleting,
              onDelete: () => onDelete(b.id),
            ),
          ),
        // Add button
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: OutlinedButton.icon(
            onPressed: isAdding ? null : onAdd,
            icon: isAdding
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.add_rounded, size: 18),
            label: Text(context.l10n.addBreak),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              minimumSize: const Size(double.infinity, 44),
              textStyle: AppTextStyles.button,
            ),
          ),
        ),
      ],
    );
  }
}

class _BreakTile extends StatelessWidget {
  final BreakModel breakModel;
  final bool isDeleting;
  final VoidCallback onDelete;

  const _BreakTile({
    required this.breakModel,
    required this.isDeleting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dayLabel = breakModel.dayOfWeek != null
        ? _dayName(breakModel.dayOfWeek!, context)
        : context.l10n.everyDay;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(
              Icons.coffee_outlined,
              size: 18,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  breakModel.label?.isNotEmpty == true
                      ? breakModel.label!
                      : '${breakModel.startTime} – ${breakModel.endTime}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$dayLabel  •  ${breakModel.startTime} – ${breakModel.endTime}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          // Delete button — 48dp touch target
          Semantics(
            label: context.l10n.delete,
            button: true,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isDeleting ? null : onDelete,
                  borderRadius: BorderRadius.circular(24),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.error,
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
// Section 3 – Days off card
// ---------------------------------------------------------------------------

class _DaysOffCard extends StatelessWidget {
  final List<DayOffModel> daysOff;
  final bool isAdding;
  final bool isDeleting;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;

  const _DaysOffCard({
    required this.daysOff,
    required this.isAdding,
    required this.isDeleting,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Sort by date ascending — closest day off first.
    final sorted = [...daysOff]
      ..sort((a, b) => a.date.compareTo(b.date));

    return _SectionCard(
      title: context.l10n.daysOff,
      icon: Icons.event_busy_rounded,
      children: [
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              context.l10n.noLeavePlanned,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          )
        else
          ...sorted.map(
            (d) => _DayOffTile(
              dayOff: d,
              isDeleting: isDeleting,
              onDelete: () => onDelete(d.id),
            ),
          ),
        // Add button
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: OutlinedButton.icon(
            onPressed: isAdding ? null : onAdd,
            icon: isAdding
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.add_rounded, size: 18),
            label: Text(context.l10n.addDayOff),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              minimumSize: const Size(double.infinity, 44),
              textStyle: AppTextStyles.button,
            ),
          ),
        ),
      ],
    );
  }
}

class _DayOffTile extends StatelessWidget {
  final DayOffModel dayOff;
  final bool isDeleting;
  final VoidCallback onDelete;

  const _DayOffTile({
    required this.dayOff,
    required this.isDeleting,
    required this.onDelete,
  });

  static String _formatDate(BuildContext context, String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;
    final l = context.l10n;
    final months = [
      l.monthShortJan, l.monthShortFeb, l.monthShortMar, l.monthShortApr,
      l.monthShortMay, l.monthShortJun, l.monthShortJul, l.monthShortAug,
      l.monthShortSep, l.monthShortOct, l.monthShortNov, l.monthShortDec,
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(
              Icons.beach_access_rounded,
              size: 18,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(context, dayOff.date),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (dayOff.reason != null && dayOff.reason!.isNotEmpty)
                  Text(dayOff.reason!, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          // Delete button
          Semantics(
            label: context.l10n.delete,
            button: true,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isDeleting ? null : onDelete,
                  borderRadius: BorderRadius.circular(24),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.error,
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
// Add break dialog
// ---------------------------------------------------------------------------

class _AddBreakDialog extends StatefulWidget {
  final Future<void> Function(AddBreakRequest) onConfirm;

  const _AddBreakDialog({required this.onConfirm});

  @override
  State<_AddBreakDialog> createState() => _AddBreakDialogState();
}

class _AddBreakDialogState extends State<_AddBreakDialog> {
  final _labelCtrl = TextEditingController();
  String _startTime = '12:00';
  String _endTime = '13:00';
  // null = every day; 1–7 = specific day
  int? _dayOfWeek;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final request = AddBreakRequest(
      startTime: _startTime,
      endTime: _endTime,
      label: _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
      dayOfWeek: _dayOfWeek,
    );
    await widget.onConfirm(request);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      // Cap modal width so it doesn't stretch across a desktop screen.
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.coffee_rounded, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(context.l10n.addBreak, style: AppTextStyles.h3),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Label
            AppTextField(
              controller: _labelCtrl,
              label: context.l10n.breakLabel,
              hint: 'Ex: Déjeuner',
              prefixIcon: Icons.label_outline_rounded,
            ),
            const SizedBox(height: AppSpacing.md),

            // Time range
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: context.l10n.startTimeLabel,
                    value: _startTime,
                    onChanged: (t) => setState(() => _startTime = t),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _TimePicker(
                    label: context.l10n.endTimeLabel,
                    value: _endTime,
                    onChanged: (t) => setState(() => _endTime = t),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Day of week
            Text(
              context.l10n.dayOfWeekLabel,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _dayOfWeek,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(context.l10n.everyDay),
                    ),
                    ...List.generate(
                      7,
                      (i) => DropdownMenuItem<int?>(
                        value: i,
                        child: Text(_dayName(i, context)),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _dayOfWeek = v),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Confirm
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(context.l10n.confirm),
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
// Error view
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.retry),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
