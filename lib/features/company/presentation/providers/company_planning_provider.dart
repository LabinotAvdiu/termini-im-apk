import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/planning_appointment_model.dart';
import 'company_dashboard_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class CompanyPlanningState {
  final String selectedDate;
  final List<PlanningAppointmentModel> appointments;
  final bool isLoading;
  final bool isSubmittingWalkIn;
  final String? error;

  const CompanyPlanningState({
    required this.selectedDate,
    this.appointments = const [],
    this.isLoading = false,
    this.isSubmittingWalkIn = false,
    this.error,
  });

  CompanyPlanningState copyWith({
    String? selectedDate,
    List<PlanningAppointmentModel>? appointments,
    bool? isLoading,
    bool? isSubmittingWalkIn,
    String? error,
  }) =>
      CompanyPlanningState(
        selectedDate: selectedDate ?? this.selectedDate,
        appointments: appointments ?? this.appointments,
        isLoading: isLoading ?? this.isLoading,
        isSubmittingWalkIn: isSubmittingWalkIn ?? this.isSubmittingWalkIn,
        error: error,
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

  void goToPreviousDay() {
    final current = DateTime.tryParse(state.selectedDate) ?? DateTime.now();
    setDate(current.subtract(const Duration(days: 1)));
  }

  void goToNextDay() {
    final current = DateTime.tryParse(state.selectedDate) ?? DateTime.now();
    setDate(current.add(const Duration(days: 1)));
  }

  void setDate(DateTime date) {
    final iso =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (!mounted) return;
    state = state.copyWith(selectedDate: iso, appointments: []);
    load();
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

    final previous = state.appointments;
    final updated = previous.map((a) {
      if (a.id == id) return a.copyWith(status: newStatus);
      return a;
    }).toList();

    state = state.copyWith(appointments: updated);

    try {
      final datasource = _ref.read(myCompanyDatasourceProvider);
      await datasource.updateAppointmentStatus(id, newStatus);
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(appointments: previous);
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
