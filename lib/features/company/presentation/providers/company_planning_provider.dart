import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/planning_appointment_model.dart';
import 'company_dashboard_provider.dart';

// ---------------------------------------------------------------------------
// View mode enum
// ---------------------------------------------------------------------------

enum CompanyPlanningViewMode { day, week, month }

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class CompanyPlanningState {
  final String selectedDate;
  final List<PlanningAppointmentModel> appointments;
  final bool isLoading;
  final bool isSubmittingWalkIn;
  final String? error;
  final CompanyPlanningViewMode viewMode;
  final Map<String, List<PlanningAppointmentModel>> rangeAppointments;

  const CompanyPlanningState({
    required this.selectedDate,
    this.appointments = const [],
    this.isLoading = false,
    this.isSubmittingWalkIn = false,
    this.error,
    this.viewMode = CompanyPlanningViewMode.day,
    this.rangeAppointments = const {},
  });

  CompanyPlanningState copyWith({
    String? selectedDate,
    List<PlanningAppointmentModel>? appointments,
    bool? isLoading,
    bool? isSubmittingWalkIn,
    String? error,
    CompanyPlanningViewMode? viewMode,
    Map<String, List<PlanningAppointmentModel>>? rangeAppointments,
  }) =>
      CompanyPlanningState(
        selectedDate: selectedDate ?? this.selectedDate,
        appointments: appointments ?? this.appointments,
        isLoading: isLoading ?? this.isLoading,
        isSubmittingWalkIn: isSubmittingWalkIn ?? this.isSubmittingWalkIn,
        error: error,
        viewMode: viewMode ?? this.viewMode,
        rangeAppointments: rangeAppointments ?? this.rangeAppointments,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class CompanyPlanningNotifier
    extends StateNotifier<CompanyPlanningState> {
  final Ref _ref;

  CompanyPlanningNotifier(this._ref)
      : super(CompanyPlanningState(
          selectedDate: _todayIso(),
        ));

  static String _todayIso() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _toIso(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final datasource = _ref.read(myCompanyDatasourceProvider);
      final appts = await datasource.listCompanyAppointments(
        state.selectedDate,
        statuses: const ['confirmed', 'pending'],
      );
      if (!mounted) return;
      state = state.copyWith(isLoading: false, appointments: appts);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadRange(DateTime start, DateTime endInclusive) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final datasource = _ref.read(myCompanyDatasourceProvider);
      final appts = await datasource.listCompanyAppointmentsRange(
        _toIso(start),
        _toIso(endInclusive),
        statuses: const ['confirmed', 'pending'],
      );
      if (!mounted) return;
      final map = <String, List<PlanningAppointmentModel>>{};
      for (var d = start;
          !d.isAfter(endInclusive);
          d = d.add(const Duration(days: 1))) {
        map[_toIso(d)] = const [];
      }
      for (final a in appts) {
        final key = a.date;
        map[key] = [...(map[key] ?? const []), a];
      }
      state = state.copyWith(isLoading: false, rangeAppointments: map);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setViewMode(CompanyPlanningViewMode mode) {
    if (!mounted) return;
    state = state.copyWith(viewMode: mode);
    _loadForCurrentMode();
  }

  void _loadForCurrentMode() {
    switch (state.viewMode) {
      case CompanyPlanningViewMode.day:
        load();
      case CompanyPlanningViewMode.week:
        final selected = DateTime.tryParse(state.selectedDate) ?? DateTime.now();
        final weekStart = _weekStart(selected);
        loadRange(weekStart, weekStart.add(const Duration(days: 6)));
      case CompanyPlanningViewMode.month:
        final selected = DateTime.tryParse(state.selectedDate) ?? DateTime.now();
        final monthStart = DateTime(selected.year, selected.month, 1);
        final monthEnd = DateTime(selected.year, selected.month + 1, 0);
        loadRange(monthStart, monthEnd);
    }
  }

  static DateTime _weekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void goPrevious() {
    final current = DateTime.tryParse(state.selectedDate) ?? DateTime.now();
    switch (state.viewMode) {
      case CompanyPlanningViewMode.day:
        setDate(current.subtract(const Duration(days: 1)));
      case CompanyPlanningViewMode.week:
        setDate(current.subtract(const Duration(days: 7)));
      case CompanyPlanningViewMode.month:
        setDate(DateTime(current.year, current.month - 1, 1));
    }
  }

  void goNext() {
    final current = DateTime.tryParse(state.selectedDate) ?? DateTime.now();
    switch (state.viewMode) {
      case CompanyPlanningViewMode.day:
        setDate(current.add(const Duration(days: 1)));
      case CompanyPlanningViewMode.week:
        setDate(current.add(const Duration(days: 7)));
      case CompanyPlanningViewMode.month:
        setDate(DateTime(current.year, current.month + 1, 1));
    }
  }

  void goToPreviousDay() => goPrevious();

  void goToNextDay() => goNext();

  void setDate(DateTime date) {
    final iso = _toIso(date);
    if (!mounted) return;
    state = state.copyWith(selectedDate: iso, appointments: []);
    _loadForCurrentMode();
  }

  Future<bool> addWalkIn({
    required String date,
    required String startTime,
    required String serviceId,
    required String firstName,
    String? lastName,
    String? phone,
  }) async {
    if (!mounted) return false;
    state = state.copyWith(isSubmittingWalkIn: true, error: null);
    try {
      final datasource = _ref.read(myCompanyDatasourceProvider);
      final json = await datasource.storeCompanyWalkIn({
        'date': date,
        'start_time': startTime,
        'service_id': serviceId,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
      }..removeWhere((_, v) => v == null));
      final newAppt = PlanningAppointmentModel.fromJson(json);
      if (!mounted) return false;
      state = state.copyWith(
        isSubmittingWalkIn: false,
        appointments: [...state.appointments, newAppt],
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSubmittingWalkIn: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> confirmAppointment(String id) =>
      _updateStatus(id, 'confirmed');

  Future<bool> rejectAppointment(String id) =>
      _updateStatus(id, 'rejected');

  Future<bool> cancelAppointment(String id) =>
      _updateStatus(id, 'cancelled');

  Future<bool> _updateStatus(String id, String newStatus) async {
    if (!mounted) return false;

    final previousAppointments = state.appointments;
    final previousRange = state.rangeAppointments;

    // Mirror the change into today's list.
    final updatedAppointments = previousAppointments.map((a) {
      if (a.id == id) return a.copyWith(status: newStatus);
      return a;
    }).toList();

    // Mirror into the month-range map so month view reflects the change
    // without waiting for a full reload.
    final updatedRange = <String, List<PlanningAppointmentModel>>{};
    previousRange.forEach((iso, list) {
      final isCancellation =
          newStatus == 'rejected' || newStatus == 'cancelled';
      final newList = <PlanningAppointmentModel>[];
      for (final a in list) {
        if (a.id == id) {
          if (isCancellation) {
            // Drop it — the month view only shows active appointments.
            continue;
          }
          newList.add(a.copyWith(status: newStatus));
        } else {
          newList.add(a);
        }
      }
      updatedRange[iso] = newList;
    });

    state = state.copyWith(
      appointments: updatedAppointments,
      rangeAppointments: updatedRange,
    );

    try {
      final datasource = _ref.read(myCompanyDatasourceProvider);
      await datasource.updateAppointmentStatus(id, newStatus);
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        appointments: previousAppointments,
        rangeAppointments: previousRange,
      );
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final companyPlanningProvider = StateNotifierProvider.autoDispose<
    CompanyPlanningNotifier, CompanyPlanningState>(
  (ref) => CompanyPlanningNotifier(ref),
);
