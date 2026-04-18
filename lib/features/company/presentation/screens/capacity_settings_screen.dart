import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/datasources/my_company_remote_datasource.dart';
import '../../data/models/my_company_model.dart';
import '../providers/company_dashboard_provider.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _capacityDatasourceProvider = Provider<MyCompanyRemoteDatasource>((ref) {
  return ref.watch(myCompanyDatasourceProvider);
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _CapacitySettingsState {
  final List<CompanyBreakModel> breaks;
  final List<CapacityOverrideModel> overrides;
  final bool isLoading;
  final String? error;

  const _CapacitySettingsState({
    this.breaks = const [],
    this.overrides = const [],
    this.isLoading = false,
    this.error,
  });

  _CapacitySettingsState copyWith({
    List<CompanyBreakModel>? breaks,
    List<CapacityOverrideModel>? overrides,
    bool? isLoading,
    String? error,
  }) =>
      _CapacitySettingsState(
        breaks: breaks ?? this.breaks,
        overrides: overrides ?? this.overrides,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class _CapacitySettingsNotifier
    extends StateNotifier<_CapacitySettingsState> {
  final MyCompanyRemoteDatasource _datasource;

  _CapacitySettingsNotifier(this._datasource)
      : super(const _CapacitySettingsState());

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      final breaks = await _datasource.getBreaks();
      final overrides = await _datasource.getCapacityOverrides();
      if (!mounted) return;
      state = state.copyWith(
          breaks: breaks, overrides: overrides, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addBreak(Map<String, dynamic> data) async {
    try {
      final created = await _datasource.createBreak(data);
      if (!mounted) return false;
      state = state.copyWith(breaks: [...state.breaks, created]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteBreak(String id) async {
    try {
      await _datasource.deleteBreak(id);
      if (!mounted) return false;
      state = state.copyWith(
          breaks: state.breaks.where((b) => b.id != id).toList());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addOverride(Map<String, dynamic> data) async {
    try {
      final created = await _datasource.createCapacityOverride(data);
      if (!mounted) return false;
      state = state.copyWith(overrides: [...state.overrides, created]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteOverride(String id) async {
    try {
      await _datasource.deleteCapacityOverride(id);
      if (!mounted) return false;
      state = state.copyWith(
          overrides: state.overrides.where((o) => o.id != id).toList());
      return true;
    } catch (_) {
      return false;
    }
  }
}

final _capacitySettingsProvider = StateNotifierProvider.autoDispose<
    _CapacitySettingsNotifier, _CapacitySettingsState>(
  (ref) => _CapacitySettingsNotifier(ref.watch(_capacityDatasourceProvider)),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CapacitySettingsScreen extends ConsumerStatefulWidget {
  const CapacitySettingsScreen({super.key});

  @override
  ConsumerState<CapacitySettingsScreen> createState() =>
      _CapacitySettingsScreenState();
}

class _CapacitySettingsScreenState
    extends ConsumerState<CapacitySettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_capacitySettingsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_capacitySettingsProvider);
    final company = ref.watch(
        companyDashboardProvider.select((s) => s.company));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.capacitySettingsTitle,
            style: AppTextStyles.h3),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.cardShadow,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () =>
                  ref.read(_capacitySettingsProvider.notifier).load(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (company != null)
                    _ModeSection(company: company),
                  const SizedBox(height: AppSpacing.md),
                  _BreaksSection(
                    breaks: state.breaks,
                    onAdd: () => _showAddBreakDialog(context),
                    onDelete: (id) async {
                      await ref
                          .read(_capacitySettingsProvider.notifier)
                          .deleteBreak(id);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _OverridesSection(
                    overrides: state.overrides,
                    onAdd: () => _showAddOverrideDialog(context),
                    onDelete: (id) async {
                      await ref
                          .read(_capacitySettingsProvider.notifier)
                          .deleteOverride(id);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
                  ),
                ),
              ),
            ),
    );
  }

  void _showAddBreakDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AddBreakDialog(
        onSave: (data) async {
          final ok = await ref
              .read(_capacitySettingsProvider.notifier)
              .addBreak(data);
          if (ctx.mounted) Navigator.of(ctx).pop();
          if (ok && context.mounted) {
            context.showSnackBar(context.l10n.changesSaved);
          }
        },
      ),
    );
  }

  void _showAddOverrideDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AddOverrideDialog(
        onSave: (data) async {
          final ok = await ref
              .read(_capacitySettingsProvider.notifier)
              .addOverride(data);
          if (ctx.mounted) Navigator.of(ctx).pop();
          if (ok && context.mounted) {
            context.showSnackBar(context.l10n.changesSaved);
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mode section
// ---------------------------------------------------------------------------

class _ModeSection extends ConsumerWidget {
  final dynamic company;

  const _ModeSection({required this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = (company.bookingMode as String?) ?? 'employee_based';
    final isCapacity = mode == 'capacity_based';
    final modeLabel = isCapacity
        ? context.l10n.bookingModeCapacityBasedTitle
        : context.l10n.bookingModeEmployeeBasedTitle;
    final switchTo =
        isCapacity ? 'employee_based' : 'capacity_based';
    final switchToLabel = isCapacity
        ? context.l10n.bookingModeEmployeeBasedTitle
        : context.l10n.bookingModeCapacityBasedTitle;

    return _SettingsCard(
      title: context.l10n.bookingModeTitle,
      icon: Icons.tune_rounded,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(modeLabel, style: AppTextStyles.body),
            ),
            TextButton(
              onPressed: () => _confirmSwitch(
                  context, ref, switchTo, switchToLabel),
              child: Text(context.l10n.editProfile,
                  style: const TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSwitch(BuildContext context, WidgetRef ref,
      String newMode, String newModeLabel) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.bookingModeTitle,
            style: AppTextStyles.h3),
        content: Text(
          context.l10n.changeBookingModeWarning(newModeLabel),
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.cancel,
                style:
                    const TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(myCompanyDatasourceProvider)
                    .updateBookingSettings(newMode);
                await ref
                    .read(companyDashboardProvider.notifier)
                    .load();
                if (context.mounted) {
                  context.showSnackBar(context.l10n.changesSaved);
                }
              } catch (_) {}
            },
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Breaks section
// ---------------------------------------------------------------------------

class _BreaksSection extends StatelessWidget {
  final List<CompanyBreakModel> breaks;
  final VoidCallback onAdd;
  final Future<void> Function(String) onDelete;

  const _BreaksSection({
    required this.breaks,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: context.l10n.breaks,
      icon: Icons.pause_circle_outline_rounded,
      trailing: IconButton(
        icon:
            const Icon(Icons.add_rounded, size: 22, color: AppColors.primary),
        tooltip: context.l10n.addBreak,
        onPressed: onAdd,
      ),
      child: breaks.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(context.l10n.noBreaksConfigured,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint)),
            )
          : Column(
              children: breaks.map((b) {
                final dayLabel = b.dayOfWeek == null
                    ? context.l10n.everyDay
                    : _dayLabel(context, b.dayOfWeek!);
                return ListTile(
                  dense: true,
                  title: Text(
                    b.label != null && b.label!.isNotEmpty
                        ? b.label!
                        : context.l10n.breakSlot,
                    style: AppTextStyles.body,
                  ),
                  subtitle: Text(
                    '$dayLabel  ${b.startTime.substring(0, 5)} – ${b.endTime.substring(0, 5)}',
                    style: AppTextStyles.bodySmall,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.error),
                    onPressed: () => onDelete(b.id),
                  ),
                );
              }).toList(),
            ),
    );
  }

  String _dayLabel(BuildContext context, int day) {
    final l = context.l10n;
    switch (day) {
      case 0: return l.monday;
      case 1: return l.tuesday;
      case 2: return l.wednesday;
      case 3: return l.thursday;
      case 4: return l.friday;
      case 5: return l.saturday;
      case 6: return l.sunday;
      default: return '';
    }
  }
}

// ---------------------------------------------------------------------------
// Capacity overrides section
// ---------------------------------------------------------------------------

class _OverridesSection extends StatelessWidget {
  final List<CapacityOverrideModel> overrides;
  final VoidCallback onAdd;
  final Future<void> Function(String) onDelete;

  const _OverridesSection({
    required this.overrides,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: context.l10n.reducedCapacityDays,
      icon: Icons.event_busy_outlined,
      trailing: IconButton(
        icon:
            const Icon(Icons.add_rounded, size: 22, color: AppColors.primary),
        tooltip: context.l10n.reducedCapacityDays,
        onPressed: onAdd,
      ),
      child: overrides.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(context.l10n.noBreaksConfigured,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint)),
            )
          : Column(
              children: overrides.map((o) {
                return ListTile(
                  dense: true,
                  title: Text(o.date, style: AppTextStyles.body),
                  subtitle: Text(
                    '${context.l10n.maxConcurrent}: ${o.capacity}',
                    style: AppTextStyles.bodySmall,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.error),
                    onPressed: () => onDelete(o.id),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add break dialog
// ---------------------------------------------------------------------------

class _AddBreakDialog extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _AddBreakDialog({required this.onSave});

  @override
  State<_AddBreakDialog> createState() => _AddBreakDialogState();
}

class _AddBreakDialogState extends State<_AddBreakDialog> {
  int? _dayOfWeek;
  TimeOfDay _start = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 13, minute: 0);
  final _labelCtrl = TextEditingController();

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayLabels = <String?>[
      null,
      context.l10n.monday,
      context.l10n.tuesday,
      context.l10n.wednesday,
      context.l10n.thursday,
      context.l10n.friday,
      context.l10n.saturday,
      context.l10n.sunday,
    ];

    return AlertDialog(
      title: Text(context.l10n.addBreak, style: AppTextStyles.h3),
      contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: DropdownButtonFormField<int?>(
                initialValue: _dayOfWeek,
                decoration: InputDecoration(
                  labelText: context.l10n.dayOfWeekLabel,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                items: List.generate(8, (i) {
                  final val = i == 0 ? null : i - 1;
                  return DropdownMenuItem<int?>(
                    value: val,
                    child: Text(dayLabels[i] ?? context.l10n.everyDay),
                  );
                }),
                onChanged: (v) => setState(() => _dayOfWeek = v),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(true),
                    child: _TimeChipSmall(
                        label: context.l10n.startTimeLabel,
                        time: _fmt(_start)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text('–'),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(false),
                    child: _TimeChipSmall(
                        label: context.l10n.endTimeLabel,
                        time: _fmt(_end)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _labelCtrl,
              label: context.l10n.breakLabel,
              prefixIcon: Icons.label_outline,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () => widget.onSave({
            'day_of_week': _dayOfWeek,
            'start_time': _fmt(_start),
            'end_time': _fmt(_end),
            if (_labelCtrl.text.trim().isNotEmpty)
              'label': _labelCtrl.text.trim(),
          }),
          child: Text(context.l10n.saveChanges),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Add capacity override dialog
// ---------------------------------------------------------------------------

class _AddOverrideDialog extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _AddOverrideDialog({required this.onSave});

  @override
  State<_AddOverrideDialog> createState() => _AddOverrideDialogState();
}

class _AddOverrideDialogState extends State<_AddOverrideDialog> {
  DateTime? _date;
  final _capacityCtrl = TextEditingController();

  @override
  void dispose() {
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.reducedCapacityDays, style: AppTextStyles.h3),
      contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            dense: true,
            leading:
                const Icon(Icons.calendar_today_outlined, size: 18),
            title: Text(
              _date != null
                  ? '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}'
                  : context.l10n.selectDate,
              style: AppTextStyles.body,
            ),
            onTap: _pickDate,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: AppTextField(
              controller: _capacityCtrl,
              label: context.l10n.maxConcurrent,
              prefixIcon: Icons.people_outline_rounded,
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () {
            if (_date == null) return;
            final cap = int.tryParse(_capacityCtrl.text.trim()) ?? 0;
            if (cap <= 0) return;
            widget.onSave({
              'date':
                  '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
              'capacity': cap,
            });
          },
          child: Text(context.l10n.saveChanges),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared card wrapper — editorial: 1px border, overline + Fraunces heading
// ---------------------------------------------------------------------------

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.child,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 12, color: AppColors.textHint),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            title.toUpperCase(),
                            style: AppTextStyles.overline.copyWith(
                              letterSpacing: 1.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: GoogleFonts.fraunces(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.17,
                        ),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          child,
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

class _TimeChipSmall extends StatelessWidget {
  final String label;
  final String time;

  const _TimeChipSmall({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textHint)),
          Text(time,
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
