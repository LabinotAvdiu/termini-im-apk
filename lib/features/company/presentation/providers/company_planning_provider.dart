import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../employee_schedule/presentation/providers/schedule_provider.dart'
    show upcomingAppointmentProvider;

import '../../data/models/planning_appointment_model.dart';
import '../../data/models/planning_overlay_model.dart';
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

  /// Ids of appointments with an in-flight status mutation (accept / reject /
  /// cancel / no-show / free-slot). Callers gate their CTAs on
  /// `mutatingIds.isNotEmpty` so tapping accept on one card while reject is
  /// pending on another card can't fire two requests in parallel.
  final Set<String> mutatingIds;

  /// Non-appointment overlays — recurring breaks + concrete days off.
  /// Scoped server-side to the caller's role.
  final PlanningOverlaysModel overlays;

  /// UI-driving flags — see docs/PLANNING_CONTRACT.md. The screens read
  /// these instead of deriving from bookingMode/role.
  final PlanningSettingsModel settings;

  const CompanyPlanningState({
    required this.selectedDate,
    this.appointments = const [],
    this.isLoading = false,
    this.isSubmittingWalkIn = false,
    this.error,
    this.viewMode = CompanyPlanningViewMode.day,
    this.rangeAppointments = const {},
    this.mutatingIds = const <String>{},
    this.overlays = const PlanningOverlaysModel(),
    this.settings = const PlanningSettingsModel(),
  });

  bool get isMutating => mutatingIds.isNotEmpty;

  CompanyPlanningState copyWith({
    String? selectedDate,
    List<PlanningAppointmentModel>? appointments,
    bool? isLoading,
    bool? isSubmittingWalkIn,
    String? error,
    CompanyPlanningViewMode? viewMode,
    Map<String, List<PlanningAppointmentModel>>? rangeAppointments,
    Set<String>? mutatingIds,
    PlanningOverlaysModel? overlays,
    PlanningSettingsModel? settings,
  }) =>
      CompanyPlanningState(
        selectedDate: selectedDate ?? this.selectedDate,
        appointments: appointments ?? this.appointments,
        isLoading: isLoading ?? this.isLoading,
        isSubmittingWalkIn: isSubmittingWalkIn ?? this.isSubmittingWalkIn,
        error: error,
        viewMode: viewMode ?? this.viewMode,
        rangeAppointments: rangeAppointments ?? this.rangeAppointments,
        mutatingIds: mutatingIds ?? this.mutatingIds,
        overlays: overlays ?? this.overlays,
        settings: settings ?? this.settings,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class CompanyPlanningNotifier
    extends StateNotifier<CompanyPlanningState> {
  final Ref _ref;

  /// Pending debounce for rapid arrow-clicks. Each call to
  /// `_loadForCurrentMode` cancels the previous timer so only the LAST
  /// selection within the window fires a network request.
  Timer? _debounceTimer;
  static const Duration _debounceWindow = Duration(milliseconds: 220);

  /// Monotonic counter bumped on every dispatched request. The response
  /// handler drops state updates from stale (non-latest) requests, so even
  /// if two fetches race, only the most recent one wins.
  int _latestRequestId = 0;

  CompanyPlanningNotifier(this._ref)
      : super(CompanyPlanningState(
          selectedDate: _todayIso(),
        ));

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  static String _todayIso() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _toIso(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    if (!mounted) return;
    final reqId = ++_latestRequestId;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final datasource = _ref.read(myCompanyDatasourceProvider);
      // Fetch appointments + overlays + settings in parallel. Settings are
      // cheap (a few bools) and rarely change, but refreshing them on each
      // load keeps things simple — the user never sees a stale capacity-mode
      // vs individual-mode layout after switching the booking mode.
      final results = await Future.wait([
        datasource.listCompanyAppointments(state.selectedDate),
        datasource.getPlanningOverlays(
          state.selectedDate,
          state.selectedDate,
        ),
        datasource.getPlanningSettings(),
      ]);
      if (!mounted || reqId != _latestRequestId) return; // stale
      state = state.copyWith(
        isLoading: false,
        appointments: results[0] as List<PlanningAppointmentModel>,
        overlays: results[1] as PlanningOverlaysModel,
        settings: results[2] as PlanningSettingsModel,
      );
    } catch (e) {
      if (!mounted || reqId != _latestRequestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadRange(DateTime start, DateTime endInclusive) async {
    if (!mounted) return;
    final reqId = ++_latestRequestId;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final datasource = _ref.read(myCompanyDatasourceProvider);
      final results = await Future.wait([
        datasource.listCompanyAppointmentsRange(
          _toIso(start),
          _toIso(endInclusive),
        ),
        datasource.getPlanningOverlays(
          _toIso(start),
          _toIso(endInclusive),
        ),
        datasource.getPlanningSettings(),
      ]);
      if (!mounted || reqId != _latestRequestId) return; // stale
      final appts = results[0] as List<PlanningAppointmentModel>;
      final overlays = results[1] as PlanningOverlaysModel;
      final settings = results[2] as PlanningSettingsModel;
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
      state = state.copyWith(
        isLoading: false,
        rangeAppointments: map,
        overlays: overlays,
        settings: settings,
      );
    } catch (e) {
      if (!mounted || reqId != _latestRequestId) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setViewMode(CompanyPlanningViewMode mode) {
    if (!mounted) return;
    state = state.copyWith(viewMode: mode);
    _loadForCurrentMode();
  }

  void _loadForCurrentMode() {
    // Debounce: if the user taps the arrow multiple times quickly, only the
    // last navigation fires a request. Prevents the 20/04 flash when the
    // user is actually headed to 21/04.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceWindow, _dispatchLoad);
  }

  void _dispatchLoad() {
    if (!mounted) return;
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
    // Drop concurrent taps — the submit button is already gated on
    // isSubmittingWalkIn in the dialog, but a rapid double-tap can sneak past
    // the first rebuild.
    if (state.isSubmittingWalkIn) return false;
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

  /// Reject a pending appointment, optionally providing a [reason] that will
  /// be stored as [rejectionReason] on the resource and shown to the owner.
  /// The slot stays blocked after rejection — use [freeRejectedSlot] to release it.
  Future<bool> rejectAppointment(String id, {String? reason}) =>
      _updateStatus(id, 'rejected', reason: reason);

  /// Cancel an appointment as the owner (confirmed → cancelled).
  /// Optionally pass a [reason] stored as [cancellation_reason].
  Future<bool> cancelAppointment(String id, {String? reason}) =>
      _updateStatus(id, 'cancelled', reason: reason);

  /// Transition a previously-rejected appointment to cancelled, releasing the
  /// capacity slot. No client notification is sent (backend contract).
  /// The original [rejectionReason] is preserved by the backend.
  Future<bool> freeRejectedSlot(String id) =>
      _updateStatus(id, 'cancelled');

  /// Feature 4 — Mark a client as no-show (owner only).
  Future<bool> markNoShow(String id) => _updateStatus(id, 'no_show');

  Future<bool> _updateStatus(String id, String newStatus, {String? reason}) async {
    if (!mounted) return false;
    // Drop the call if the same appointment is already being mutated (rapid
    // double-tap on the same CTA). Other appointments can still be in flight —
    // UI-level gating (mutatingIds.isNotEmpty) prevents cross-card races.
    if (state.mutatingIds.contains(id)) return false;

    final previousAppointments = state.appointments;
    final previousRange = state.rangeAppointments;
    state = state.copyWith(mutatingIds: {...state.mutatingIds, id});

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
      await datasource.updateAppointmentStatus(id, newStatus, reason: reason);
      // Refresh the "next appointment" banner — a cancel or no-show might
      // have invalidated the current upcoming (or unveiled a later one).
      _ref.invalidate(upcomingAppointmentProvider);
      if (mounted) {
        state = state.copyWith(
          mutatingIds: state.mutatingIds.difference({id}),
        );
      }
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        appointments: previousAppointments,
        rangeAppointments: previousRange,
        mutatingIds: state.mutatingIds.difference({id}),
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
