import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../employee_schedule/data/models/schedule_settings_models.dart';
import '../../data/datasources/my_company_remote_datasource.dart';
import '../../data/models/my_company_model.dart';
import '../providers/company_dashboard_provider.dart';
import '../widgets/add_day_off_dialog.dart';

// ---------------------------------------------------------------------------
// "Mon salon" — capacity-mode settings : breaks + days off.
//
// Capacity-override feature removed — the requested flow was : keep the two
// functionalities (pauses + jours fériés) with the SAME modal + conflict UX
// as the individual-mode screen ("Mes horaires"). See docs/PLANNING_CONTRACT.md.
// ---------------------------------------------------------------------------

final _capacityDatasourceProvider = Provider<MyCompanyRemoteDatasource>((ref) {
  return ref.watch(myCompanyDatasourceProvider);
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _CompanyScheduleState {
  final List<CompanyBreakModel> breaks;
  final List<_CompanyDayOff> daysOff;
  final bool isLoading;
  final String? error;

  const _CompanyScheduleState({
    this.breaks = const [],
    this.daysOff = const [],
    this.isLoading = false,
    this.error,
  });

  _CompanyScheduleState copyWith({
    List<CompanyBreakModel>? breaks,
    List<_CompanyDayOff>? daysOff,
    bool? isLoading,
    String? error,
  }) =>
      _CompanyScheduleState(
        breaks: breaks ?? this.breaks,
        daysOff: daysOff ?? this.daysOff,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// Lightweight DTO — we don't need a dedicated model file for a 3-field shape.
class _CompanyDayOff {
  final String id;
  final String date;
  final String? reason;

  const _CompanyDayOff({required this.id, required this.date, this.reason});

  factory _CompanyDayOff.fromJson(Map<String, dynamic> json) =>
      _CompanyDayOff(
        id: json['id']?.toString() ?? '',
        date: (json['date'] as String?) ?? '',
        reason: json['reason'] as String?,
      );
}

class _CompanyScheduleNotifier
    extends StateNotifier<_CompanyScheduleState> {
  final MyCompanyRemoteDatasource _datasource;

  _CompanyScheduleNotifier(this._datasource)
      : super(const _CompanyScheduleState());

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _datasource.getBreaks(),
        _datasource.getCompanyDaysOff(),
      ]);
      if (!mounted) return;
      state = state.copyWith(
        breaks: results[0] as List<CompanyBreakModel>,
        daysOff: (results[1] as List<Map<String, dynamic>>)
            .map(_CompanyDayOff.fromJson)
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Break CRUD ────────────────────────────────────────────────────────────

  Future<AddBreakResult> addBreak(AddBreakRequest request) async {
    try {
      final created = await _datasource.createBreak(request.toJson());
      if (!mounted) return const AddBreakResult.success();
      state = state.copyWith(breaks: [...state.breaks, created]);
      return const AddBreakResult.success();
    } on ScheduleConflictException catch (e) {
      return AddBreakResult.conflict(e.conflicts);
    } catch (e) {
      return AddBreakResult.error(e.toString());
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

  // ── Day-off CRUD ──────────────────────────────────────────────────────────

  Future<AddDayOffResult> addDayOff(AddDayOffRequest request) async {
    try {
      final created = await _datasource.createCompanyDayOff(request.toJson());
      if (!mounted) return const AddDayOffResult.success();
      final models = created.map(_CompanyDayOff.fromJson).toList();
      state = state.copyWith(daysOff: [...state.daysOff, ...models]);
      return const AddDayOffResult.success();
    } on ScheduleConflictException catch (e) {
      return AddDayOffResult.conflict(e.conflicts);
    } catch (e) {
      return AddDayOffResult.error(e.toString());
    }
  }

  Future<bool> deleteDayOff(String id) async {
    try {
      await _datasource.deleteCompanyDayOff(id);
      if (!mounted) return false;
      state = state.copyWith(
          daysOff: state.daysOff.where((d) => d.id != id).toList());
      return true;
    } catch (_) {
      return false;
    }
  }
}

final _companyScheduleProvider =
    StateNotifierProvider<_CompanyScheduleNotifier, _CompanyScheduleState>(
        (ref) =>
            _CompanyScheduleNotifier(ref.watch(_capacityDatasourceProvider)));

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
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(_companyScheduleProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_companyScheduleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          context.l10n.capacitySettings,
          style: AppTextStyles.h3,
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(_companyScheduleProvider.notifier).load(),
        child: state.isLoading && state.breaks.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                    AppSpacing.sm, AppSpacing.md, AppSpacing.xxl),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _BreaksCard(
                            breaks: state.breaks,
                            onAdd: () => _showAddBreakDialog(context),
                            onDelete: (id) =>
                                _confirmAndDeleteBreak(context, id),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _DaysOffCard(
                            daysOff: state.daysOff,
                            onAdd: () => _showAddDayOffDialog(context),
                            onDelete: (id) =>
                                _confirmAndDeleteDayOff(context, id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _showAddBreakDialog(BuildContext context) async {
    final notifier = ref.read(_companyScheduleProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

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
          messenger.showSnackBar(SnackBar(
              content: Text(message), backgroundColor: AppColors.error));
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _AddCompanyBreakDialog(
        onConfirm: (req) async {
          await attempt(req, () {
            if (Navigator.of(dialogCtx).canPop()) {
              Navigator.of(dialogCtx).pop();
            }
          });
        },
      ),
    );
  }

  Future<void> _showAddDayOffDialog(BuildContext context) async {
    final notifier = ref.read(_companyScheduleProvider.notifier);
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
            break;
          case AddDayOffError(:final message):
            messenger.showSnackBar(SnackBar(
                content: Text(message), backgroundColor: AppColors.error));
        }
        return result;
      },
    );
  }

  Future<void> _confirmAndDeleteBreak(BuildContext context, String id) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteBreakConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.cancel)),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(_companyScheduleProvider.notifier).deleteBreak(id);
    }
  }

  Future<void> _confirmAndDeleteDayOff(BuildContext context, String id) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteDayOffConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.cancel)),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(_companyScheduleProvider.notifier).deleteDayOff(id);
    }
  }
}

// ---------------------------------------------------------------------------
// Section card — mirror of the one used in ScheduleSettingsScreen so the two
// screens read identical. Icon + Fraunces title + optional trailing button.
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
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
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md,
                AppSpacing.md, AppSpacing.sm),
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
// Breaks list card
// ---------------------------------------------------------------------------

class _BreaksCard extends StatelessWidget {
  final List<CompanyBreakModel> breaks;
  final VoidCallback onAdd;
  final void Function(String id) onDelete;

  const _BreaksCard({
    required this.breaks,
    required this.onAdd,
    required this.onDelete,
  });

  String _dayLabel(BuildContext context, int? dow) {
    if (dow == null) return context.l10n.everyDay;
    final days = [
      context.l10n.monday,
      context.l10n.tuesday,
      context.l10n.wednesday,
      context.l10n.thursday,
      context.l10n.friday,
      context.l10n.saturday,
      context.l10n.sunday,
    ];
    return (dow >= 0 && dow <= 6) ? days[dow] : '?';
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: context.l10n.breaks,
      icon: Icons.coffee_rounded,
      trailing: IconButton(
        icon: const Icon(Icons.add_rounded, color: AppColors.primary),
        onPressed: onAdd,
        tooltip: context.l10n.addBreak,
      ),
      children: [
        if (breaks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              context.l10n.noBreaksYet,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textHint),
            ),
          )
        else
          ...breaks.map(
            (b) => ListTile(
              dense: true,
              leading: const Icon(Icons.coffee_outlined,
                  size: 18, color: AppColors.textHint),
              title: Text(
                (b.label?.isNotEmpty ?? false)
                    ? b.label!
                    : context.l10n.breakSlot,
                style: AppTextStyles.body
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${_dayLabel(context, b.dayOfWeek)} · '
                '${b.startTime} – ${b.endTime}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textHint),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                onPressed: () => onDelete(b.id),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Days-off list card
// ---------------------------------------------------------------------------

class _DaysOffCard extends StatelessWidget {
  final List<_CompanyDayOff> daysOff;
  final VoidCallback onAdd;
  final void Function(String id) onDelete;

  const _DaysOffCard({
    required this.daysOff,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...daysOff]..sort((a, b) => a.date.compareTo(b.date));
    return _SectionCard(
      title: context.l10n.daysOff,
      icon: Icons.event_busy_rounded,
      trailing: IconButton(
        icon: const Icon(Icons.add_rounded, color: AppColors.primary),
        onPressed: onAdd,
        tooltip: context.l10n.addDayOff,
      ),
      children: [
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              context.l10n.noDaysOffYet,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textHint),
            ),
          )
        else
          ...sorted.map(
            (d) => ListTile(
              dense: true,
              leading: const Icon(Icons.event_busy_outlined,
                  size: 18, color: AppColors.textHint),
              title: Text(
                _formatDate(d.date),
                style: AppTextStyles.body
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: d.reason != null && d.reason!.isNotEmpty
                  ? Text(
                      d.reason!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textHint),
                    )
                  : null,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                onPressed: () => onDelete(d.id),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse('${iso}T00:00:00');
      return FrenchDateFormatter.full(d);
    } catch (_) {
      return iso;
    }
  }
}

// ---------------------------------------------------------------------------
// Add-break dialog — company-level. Payload shape is shared with the
// employee side via AddBreakRequest, so the conflict flow reuses the same
// sealed result types.
// ---------------------------------------------------------------------------

class _AddCompanyBreakDialog extends StatefulWidget {
  final Future<void> Function(AddBreakRequest) onConfirm;
  const _AddCompanyBreakDialog({required this.onConfirm});

  @override
  State<_AddCompanyBreakDialog> createState() =>
      _AddCompanyBreakDialogState();
}

class _AddCompanyBreakDialogState extends State<_AddCompanyBreakDialog> {
  final _labelCtrl = TextEditingController();
  String _startTime = '12:00';
  String _endTime = '13:00';
  int? _dayOfWeek;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final req = AddBreakRequest(
      startTime: _startTime,
      endTime: _endTime,
      label: _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
      dayOfWeek: _dayOfWeek,
    );
    await widget.onConfirm(req);
    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _pickTime(bool isStart) async {
    final current = TimeOfDay(
      hour: int.parse((isStart ? _startTime : _endTime).split(':')[0]),
      minute: int.parse((isStart ? _startTime : _endTime).split(':')[1]),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final s =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isStart) {
        _startTime = s;
      } else {
        _endTime = s;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.coffee_rounded,
                      color: AppColors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(context.l10n.addBreak,
                        style: AppTextStyles.h3),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _labelCtrl,
                label: context.l10n.breakLabel,
                hint: 'Ex: Déjeuner',
                prefixIcon: Icons.label_outline_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _TimeTile(
                      label: context.l10n.startTimeLabel,
                      value: _startTime,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppColors.textHint),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _TimeTile(
                      label: context.l10n.endTimeLabel,
                      value: _endTime,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(context.l10n.dayOfWeekLabel,
                  style: AppTextStyles.bodySmall),
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
                        horizontal: AppSpacing.sm),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(context.l10n.everyDay),
                      ),
                      ..._dayDropdownItems(context),
                    ],
                    onChanged: (v) => setState(() => _dayOfWeek = v),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
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

  List<DropdownMenuItem<int?>> _dayDropdownItems(BuildContext context) {
    final labels = [
      context.l10n.monday,
      context.l10n.tuesday,
      context.l10n.wednesday,
      context.l10n.thursday,
      context.l10n.friday,
      context.l10n.saturday,
      context.l10n.sunday,
    ];
    return List.generate(
      7,
      (i) => DropdownMenuItem<int?>(
        value: i,
        child: Text(labels[i]),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TimeTile(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded,
                size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textHint)),
                Text(value,
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Suppress an unused-import analyzer hint on GoogleFonts when the tile above
// doesn't reference it — the other widgets in this file do, so the import
// stays. No-op symbol kept here to anchor the intent.
// ignore: unused_element
void _anchorGoogleFonts() {
  GoogleFonts.fraunces();
}
