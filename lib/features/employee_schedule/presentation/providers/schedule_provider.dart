import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../company/data/datasources/my_company_remote_datasource.dart';
import '../../../company/data/models/my_company_model.dart';
import '../../../company/presentation/providers/company_dashboard_provider.dart';
import '../../data/datasources/schedule_remote_datasource.dart';
import '../../data/models/schedule_models.dart';

// ---------------------------------------------------------------------------
// Datasource provider
// ---------------------------------------------------------------------------

final scheduleDatasourceProvider = Provider<ScheduleRemoteDatasource>((ref) {
  return ScheduleRemoteDatasource(client: ref.watch(dioClientProvider));
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ScheduleState {
  final DayScheduleData? schedule;
  final bool isLoading;
  final String? error;
  final String selectedDate;
  final bool isSubmittingWalkIn;
  final List<MyServiceModel> services;
  /// Closest future appointment across all days — independent from the
  /// currently-viewed date so the banner at the top of the planning
  /// always shows the next booking, even when the user is browsing
  /// past/future days.
  final ScheduleAppointment? upcomingAppointment;

  ScheduleState({
    this.schedule,
    this.isLoading = false,
    this.error,
    required this.selectedDate,
    this.isSubmittingWalkIn = false,
    this.services = const [],
    this.upcomingAppointment,
  });

  ScheduleState copyWith({
    DayScheduleData? schedule,
    bool? isLoading,
    String? error,
    String? selectedDate,
    bool? isSubmittingWalkIn,
    List<MyServiceModel>? services,
    ScheduleAppointment? upcomingAppointment,
    bool clearUpcoming = false,
  }) =>
      ScheduleState(
        schedule:           schedule           ?? this.schedule,
        isLoading:          isLoading          ?? this.isLoading,
        error:              error,
        selectedDate:       selectedDate       ?? this.selectedDate,
        isSubmittingWalkIn: isSubmittingWalkIn ?? this.isSubmittingWalkIn,
        services:           services           ?? this.services,
        upcomingAppointment: clearUpcoming
            ? null
            : (upcomingAppointment ?? this.upcomingAppointment),
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final ScheduleRemoteDatasource _datasource;
  final MyCompanyRemoteDatasource _companyDatasource;

  ScheduleNotifier({
    required ScheduleRemoteDatasource datasource,
    required MyCompanyRemoteDatasource companyDatasource,
  })  : _datasource = datasource,
        _companyDatasource = companyDatasource,
        super(ScheduleState(selectedDate: _todayIso()));

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _todayIso() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _dateToIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> load({String? date}) async {
    final targetDate = date ?? state.selectedDate;
    state = state.copyWith(isLoading: true, error: null, selectedDate: targetDate);
    try {
      final results = await Future.wait([
        _datasource.getMySchedule(date: targetDate),
        _datasource.getUpcomingAppointment(),
        if (state.services.isEmpty) _companyDatasource.getCategories(),
      ]);

      final schedule = results[0] as DayScheduleData;
      final upcoming = results[1] as ScheduleAppointment?;
      final services = state.services.isNotEmpty
          ? state.services
          : (results[2] as List<MyCategoryModel>)
              .expand((c) => c.services)
              .toList();

      state = state.copyWith(
        isLoading: false,
        schedule: schedule,
        upcomingAppointment: upcoming,
        clearUpcoming: upcoming == null,
        services: services,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Date navigation ───────────────────────────────────────────────────────

  void goToPreviousDay() {
    final current = DateTime.parse(state.selectedDate);
    load(date: _dateToIso(current.subtract(const Duration(days: 1))));
  }

  void goToNextDay() {
    final current = DateTime.parse(state.selectedDate);
    load(date: _dateToIso(current.add(const Duration(days: 1))));
  }

  void goToDate(DateTime date) {
    load(date: _dateToIso(date));
  }

  // ── Walk-in ───────────────────────────────────────────────────────────────

  // ── Appointment mutations (cancel / no-show) ─────────────────────────────
  //
  // Mirror of CompanyPlanningNotifier._updateStatus but scoped to the
  // employee's own bookings. Reloads the day after a successful mutation so
  // the freed slot is immediately tappable again.
  Future<bool> cancelAppointment(String id, {String? reason}) =>
      _updateStatus(id, 'cancelled', reason: reason);

  Future<bool> markNoShow(String id) => _updateStatus(id, 'no_show');

  Future<bool> _updateStatus(String id, String newStatus, {String? reason}) async {
    try {
      await _datasource.updateMyAppointmentStatus(
        id,
        newStatus,
        reason: reason,
      );
      // Refresh the day (schedule + upcoming) — avoids client-side mirroring
      // gymnastics for a rarely-used action.
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> addWalkIn(WalkInRequest request) async {
    state = state.copyWith(isSubmittingWalkIn: true, error: null);
    try {
      final updatedSchedule = await _datasource.addWalkIn(request);
      state = state.copyWith(
        isSubmittingWalkIn: false,
        schedule: updatedSchedule,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmittingWalkIn: false, error: e.toString());
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  return ScheduleNotifier(
    datasource: ref.watch(scheduleDatasourceProvider),
    companyDatasource: ref.watch(myCompanyDatasourceProvider),
  );
});

/// Lightweight always-available provider for the "next appointment" banner
/// shown on the unified planning screen (employee_based mode). Independent
/// from the full schedule load so the banner updates without re-fetching a
/// whole day's grid. Call `ref.invalidate(upcomingAppointmentProvider)`
/// after a mutation (cancel / no-show) to refresh it.
final upcomingAppointmentProvider =
    FutureProvider.autoDispose<ScheduleAppointment?>((ref) async {
  final datasource = ref.watch(scheduleDatasourceProvider);
  return datasource.getUpcomingAppointment();
});
