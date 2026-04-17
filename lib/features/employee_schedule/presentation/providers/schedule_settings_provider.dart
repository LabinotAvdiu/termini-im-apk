import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/schedule_remote_datasource.dart';
import '../../data/models/schedule_settings_models.dart';
import '../providers/schedule_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ScheduleSettingsState {
  final ScheduleSettings? settings;
  final bool isLoading;
  final String? error;
  final bool isSavingHours;
  final bool isAddingBreak;
  final bool isDeletingBreak;
  final bool isAddingDayOff;
  final bool isDeletingDayOff;

  const ScheduleSettingsState({
    this.settings,
    this.isLoading = false,
    this.error,
    this.isSavingHours = false,
    this.isAddingBreak = false,
    this.isDeletingBreak = false,
    this.isAddingDayOff = false,
    this.isDeletingDayOff = false,
  });

  bool get isAnyMutating =>
      isSavingHours ||
      isAddingBreak ||
      isDeletingBreak ||
      isAddingDayOff ||
      isDeletingDayOff;

  ScheduleSettingsState copyWith({
    ScheduleSettings? settings,
    bool? isLoading,
    String? error,
    bool? isSavingHours,
    bool? isAddingBreak,
    bool? isDeletingBreak,
    bool? isAddingDayOff,
    bool? isDeletingDayOff,
  }) =>
      ScheduleSettingsState(
        settings:         settings         ?? this.settings,
        isLoading:        isLoading        ?? this.isLoading,
        error:            error,
        isSavingHours:    isSavingHours    ?? this.isSavingHours,
        isAddingBreak:    isAddingBreak    ?? this.isAddingBreak,
        isDeletingBreak:  isDeletingBreak  ?? this.isDeletingBreak,
        isAddingDayOff:   isAddingDayOff   ?? this.isAddingDayOff,
        isDeletingDayOff: isDeletingDayOff ?? this.isDeletingDayOff,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ScheduleSettingsNotifier
    extends StateNotifier<ScheduleSettingsState> {
  final ScheduleRemoteDatasource _datasource;

  ScheduleSettingsNotifier({required ScheduleRemoteDatasource datasource})
      : _datasource = datasource,
        super(const ScheduleSettingsState());

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final settings = await _datasource.getSettings();
      state = state.copyWith(isLoading: false, settings: settings, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Update work hours ─────────────────────────────────────────────────────

  Future<bool> saveHours(List<WorkHour> hours) async {
    state = state.copyWith(isSavingHours: true, error: null);
    try {
      await _datasource.updateHours(hours);
      // Patch local state — no full reload needed.
      final updated = ScheduleSettings(
        companyHours:  state.settings?.companyHours  ?? [],
        employeeHours: hours,
        breaks:        state.settings?.breaks        ?? [],
        daysOff:       state.settings?.daysOff       ?? [],
      );
      state = state.copyWith(
        isSavingHours: false,
        settings: updated,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSavingHours: false, error: e.toString());
      return false;
    }
  }

  // ── Add break ─────────────────────────────────────────────────────────────

  Future<bool> addBreak(AddBreakRequest request) async {
    state = state.copyWith(isAddingBreak: true, error: null);
    try {
      final newBreak = await _datasource.addBreak(request);
      final updated = ScheduleSettings(
        companyHours:  state.settings?.companyHours  ?? [],
        employeeHours: state.settings?.employeeHours ?? [],
        breaks:        [...(state.settings?.breaks ?? []), newBreak],
        daysOff:       state.settings?.daysOff       ?? [],
      );
      state = state.copyWith(
        isAddingBreak: false,
        settings: updated,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isAddingBreak: false, error: e.toString());
      return false;
    }
  }

  // ── Delete break ──────────────────────────────────────────────────────────

  Future<bool> deleteBreak(String id) async {
    state = state.copyWith(isDeletingBreak: true, error: null);
    try {
      await _datasource.deleteBreak(id);
      final updated = ScheduleSettings(
        companyHours:  state.settings?.companyHours  ?? [],
        employeeHours: state.settings?.employeeHours ?? [],
        breaks: (state.settings?.breaks ?? [])
            .where((b) => b.id != id)
            .toList(),
        daysOff: state.settings?.daysOff ?? [],
      );
      state = state.copyWith(
        isDeletingBreak: false,
        settings: updated,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isDeletingBreak: false, error: e.toString());
      return false;
    }
  }

  // ── Add day off ───────────────────────────────────────────────────────────

  Future<bool> addDayOff(AddDayOffRequest request) async {
    state = state.copyWith(isAddingDayOff: true, error: null);
    try {
      final newDayOff = await _datasource.addDayOff(request);
      final updated = ScheduleSettings(
        companyHours:  state.settings?.companyHours  ?? [],
        employeeHours: state.settings?.employeeHours ?? [],
        breaks:        state.settings?.breaks        ?? [],
        daysOff:       [...(state.settings?.daysOff ?? []), newDayOff],
      );
      state = state.copyWith(
        isAddingDayOff: false,
        settings: updated,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isAddingDayOff: false, error: e.toString());
      return false;
    }
  }

  // ── Delete day off ────────────────────────────────────────────────────────

  Future<bool> deleteDayOff(String id) async {
    state = state.copyWith(isDeletingDayOff: true, error: null);
    try {
      await _datasource.deleteDayOff(id);
      final updated = ScheduleSettings(
        companyHours:  state.settings?.companyHours  ?? [],
        employeeHours: state.settings?.employeeHours ?? [],
        breaks:        state.settings?.breaks        ?? [],
        daysOff: (state.settings?.daysOff ?? [])
            .where((d) => d.id != id)
            .toList(),
      );
      state = state.copyWith(
        isDeletingDayOff: false,
        settings: updated,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isDeletingDayOff: false, error: e.toString());
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final scheduleSettingsProvider =
    StateNotifierProvider<ScheduleSettingsNotifier, ScheduleSettingsState>(
  (ref) => ScheduleSettingsNotifier(
    datasource: ref.watch(scheduleDatasourceProvider),
  ),
);
