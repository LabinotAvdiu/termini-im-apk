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

  ScheduleState({
    this.schedule,
    this.isLoading = false,
    this.error,
    required this.selectedDate,
    this.isSubmittingWalkIn = false,
    this.services = const [],
  });

  ScheduleState copyWith({
    DayScheduleData? schedule,
    bool? isLoading,
    String? error,
    String? selectedDate,
    bool? isSubmittingWalkIn,
    List<MyServiceModel>? services,
  }) =>
      ScheduleState(
        schedule:           schedule           ?? this.schedule,
        isLoading:          isLoading          ?? this.isLoading,
        error:              error,
        selectedDate:       selectedDate       ?? this.selectedDate,
        isSubmittingWalkIn: isSubmittingWalkIn ?? this.isSubmittingWalkIn,
        services:           services           ?? this.services,
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
        if (state.services.isEmpty) _companyDatasource.getCategories(),
      ]);

      final schedule = results[0] as DayScheduleData;
      final services = state.services.isNotEmpty
          ? state.services
          : (results[1] as List<MyCategoryModel>)
              .expand((c) => c.services)
              .toList();

      state = state.copyWith(
        isLoading: false,
        schedule: schedule,
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
