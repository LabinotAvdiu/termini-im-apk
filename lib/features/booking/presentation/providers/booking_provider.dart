import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../company_detail/data/datasources/company_detail_remote_datasource.dart';
import '../../../company_detail/data/models/company_detail_model.dart';
import '../../../company_detail/presentation/providers/company_detail_provider.dart';
import '../../data/datasources/booking_remote_datasource.dart';
import '../../data/models/available_slot_model.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/day_availability_model.dart';

// ---------------------------------------------------------------------------
// Datasource provider
// ---------------------------------------------------------------------------

final bookingDatasourceProvider = Provider<BookingRemoteDatasource>((ref) {
  final client = ref.watch(dioClientProvider);
  return BookingRemoteDatasource(client: client);
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class BookingState {
  final int currentStep;
  final EmployeeModel? selectedEmployee;
  final bool noPreference;
  final DateTime? selectedDate;
  final AvailableSlotModel? selectedSlot;
  final bool isLoading;
  final bool isLoadingSlots;
  final bool isConfirmed;
  final List<EmployeeModel> employees;
  final List<DayAvailability> availability;
  final List<AvailableSlotModel> availableSlots;
  final String? companyId;
  final String? serviceId;
  final String? serviceName;
  final double? servicePrice;
  final int? serviceDuration;
  final String bookingMode;
  /// When true and bookingMode == 'capacity_based', the booking will land as
  /// confirmed (no pending queue). Used to show the correct success dialog copy.
  final bool capacityAutoApprove;
  /// Salon's cancellation policy — shown on the confirmation step so the
  /// client knows their cancellation window upfront. `0` = no restriction.
  final int minCancelHours;
  /// Locks the employee selector to the preselected employee (set by a
  /// shared link carrying `?employee=<id>`). Hides the employee picker in
  /// the UI and skips availability fetches on manual selection since that
  /// can't happen.
  final bool employeeLocked;

  /// Date the user was searching for on the home screen. Kept so every
  /// re-fetch of availability (employee change mid-flow) can re-apply the
  /// same "window starts on target-1" trim the initial load uses.
  final DateTime? targetDate;

  const BookingState({
    this.currentStep = 0,
    this.selectedEmployee,
    this.noPreference = false,
    this.selectedDate,
    this.selectedSlot,
    this.isLoading = false,
    this.isLoadingSlots = false,
    this.isConfirmed = false,
    this.employees = const [],
    this.availability = const [],
    this.availableSlots = const [],
    this.companyId,
    this.serviceId,
    this.serviceName,
    this.servicePrice,
    this.serviceDuration,
    this.bookingMode = 'employee_based',
    this.capacityAutoApprove = false,
    this.minCancelHours = 2,
    this.employeeLocked = false,
    this.targetDate,
  });

  bool get canProceedStep0 =>
      (noPreference || selectedEmployee != null) && selectedSlot != null;
  bool get canProceedStep1 => true;

  /// Returns the selected employee's display name, or `null` when no specific
  /// employee is chosen ("no preference" / capacity-based mode). UI code is
  /// expected to handle the null case with its own localized fallback so this
  /// getter stays free of any i18n concern.
  String? get selectedEmployeeName {
    if (noPreference) return null;
    return selectedEmployee?.name;
  }

  /// True when the employee selector is irrelevant — capacity-based salons
  /// whose only "team member" is the owner themselves. In that case there is
  /// no real choice to offer the client so the whole selector (and the summary
  /// row) should be hidden.
  bool get hideEmployeePicker =>
      bookingMode == 'capacity_based' && employees.length <= 1;

  BookingState copyWith({
    int? currentStep,
    EmployeeModel? selectedEmployee,
    bool? noPreference,
    DateTime? selectedDate,
    AvailableSlotModel? selectedSlot,
    bool? isLoading,
    bool? isLoadingSlots,
    bool? isConfirmed,
    List<EmployeeModel>? employees,
    List<DayAvailability>? availability,
    List<AvailableSlotModel>? availableSlots,
    String? companyId,
    String? serviceId,
    String? serviceName,
    double? servicePrice,
    int? serviceDuration,
    String? bookingMode,
    bool? capacityAutoApprove,
    int? minCancelHours,
    bool? employeeLocked,
    DateTime? targetDate,
  }) {
    return BookingState(
      currentStep: currentStep ?? this.currentStep,
      selectedEmployee: selectedEmployee ?? this.selectedEmployee,
      noPreference: noPreference ?? this.noPreference,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedSlot: selectedSlot ?? this.selectedSlot,
      isLoading: isLoading ?? this.isLoading,
      isLoadingSlots: isLoadingSlots ?? this.isLoadingSlots,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      employees: employees ?? this.employees,
      availability: availability ?? this.availability,
      availableSlots: availableSlots ?? this.availableSlots,
      companyId: companyId ?? this.companyId,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      servicePrice: servicePrice ?? this.servicePrice,
      serviceDuration: serviceDuration ?? this.serviceDuration,
      bookingMode: bookingMode ?? this.bookingMode,
      capacityAutoApprove: capacityAutoApprove ?? this.capacityAutoApprove,
      minCancelHours: minCancelHours ?? this.minCancelHours,
      employeeLocked: employeeLocked ?? this.employeeLocked,
      targetDate: targetDate ?? this.targetDate,
    );
  }

  BookingState clearEmployeeSelection() {
    return BookingState(
      currentStep: currentStep,
      selectedEmployee: null,
      noPreference: false,
      selectedDate: null,
      selectedSlot: null,
      isLoading: isLoading,
      isLoadingSlots: false,
      isConfirmed: isConfirmed,
      employees: employees,
      availability: const [],
      availableSlots: const [],
      companyId: companyId,
      serviceId: serviceId,
      serviceName: serviceName,
      servicePrice: servicePrice,
      serviceDuration: serviceDuration,
      bookingMode: bookingMode,
      capacityAutoApprove: capacityAutoApprove,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class BookingNotifier extends StateNotifier<BookingState> {
  final BookingRemoteDatasource _bookingDatasource;
  final CompanyDetailRemoteDatasource _companyDatasource;

  BookingNotifier({
    required BookingRemoteDatasource bookingDatasource,
    required CompanyDetailRemoteDatasource companyDatasource,
  })  : _bookingDatasource = bookingDatasource,
        _companyDatasource = companyDatasource,
        super(const BookingState());

  Future<void> initialize({
    required String companyId,
    String? serviceId,
    String? preselectedEmployeeId,
    DateTime? preselectedDate,
  }) async {
    state = state.copyWith(isLoading: true, companyId: companyId);

    try {
      // Fetch employees from API
      final employees = await _companyDatasource.getEmployees(companyId);

      // Filter employees by service
      final filteredEmployees = serviceId != null
          ? employees
              .where((e) =>
                  e.serviceIds.isEmpty || e.serviceIds.contains(serviceId))
              .toList()
          : employees;

      // Fetch company detail to resolve service info
      final company = await _companyDatasource.getCompanyDetail(companyId);

      String? serviceName;
      double? servicePrice;
      int? serviceDuration;

      if (serviceId != null) {
        for (final cat in company.categories) {
          for (final svc in cat.services) {
            if (svc.id == serviceId) {
              serviceName = svc.name;
              servicePrice = svc.price;
              serviceDuration = svc.durationMinutes;
              break;
            }
          }
        }
      }

      final isCapacityBased = company.bookingMode == 'capacity_based';

      // Shared link with ?employee=<userId> — try to pre-select that pro.
      // Match by `userId` so the id in the URL is stable across salons and
      // doesn't collide with the unrelated company_user pivot ids.
      // Silent fall-backs keep the flow usable:
      //  - capacity_based mode: no employee picker → ignore the hint
      //  - id doesn't match any available employee (left the salon, filtered
      //    out by service): land on "no preference" like a normal open
      EmployeeModel? preselectedEmployee;
      if (!isCapacityBased &&
          preselectedEmployeeId != null &&
          preselectedEmployeeId.isNotEmpty) {
        final match = filteredEmployees
            .where((e) => e.userId == preselectedEmployeeId)
            .toList();
        if (match.isNotEmpty) {
          preselectedEmployee = match.first;
        } else {
          debugPrint(
            '[booking] preselected employee $preselectedEmployeeId '
            'not available — falling back to no preference',
          );
        }
      }

      // Availability — when an employee is preselected, fetch their
      // schedule directly so the date picker only shows their free days.
      final rawAvailability = await _bookingDatasource.getAvailability(
        companyId: companyId,
        serviceId: serviceId,
        employeeId: preselectedEmployee?.id,
      );

      // When the user came in with a date in mind ("pour le 23"), trim the
      // date picker to start on target-1 so the searched day sits in
      // position 2 (matches the home card chips: [target-1, target, +1, +2]).
      final availability = _trimAvailabilityToTarget(
        rawAvailability,
        preselectedDate,
      );

      state = state.copyWith(
        employees: filteredEmployees,
        availability: availability,
        serviceId: serviceId,
        serviceName: serviceName ?? 'Service',
        servicePrice: servicePrice ?? 0.0,
        serviceDuration: serviceDuration ?? 30,
        selectedEmployee: preselectedEmployee,
        noPreference: preselectedEmployee == null,
        employeeLocked: preselectedEmployee != null,
        bookingMode: company.bookingMode,
        capacityAutoApprove: company.capacityAutoApprove,
        minCancelHours: company.minCancelHours,
        isLoading: false,
        targetDate: preselectedDate,
      );

      // Pre-select the date the user was searching for on the home screen
      // when it's actually available. Falls back to the first open day so
      // the picker is never empty: if the searched date turns out to be
      // closed or fully booked, the next open day is the obvious next best
      // thing to offer, and the user can still navigate freely.
      DateTime? chosenDate;
      if (preselectedDate != null) {
        final target = DateTime(
          preselectedDate.year,
          preselectedDate.month,
          preselectedDate.day,
        );
        for (final d in availability) {
          if (!d.isAvailable) continue;
          final parsed = DateTime.tryParse(d.date);
          if (parsed == null) continue;
          if (parsed.year == target.year &&
              parsed.month == target.month &&
              parsed.day == target.day) {
            chosenDate = parsed;
            break;
          }
        }
      }

      chosenDate ??= (() {
        final firstAvailable =
            availability.where((d) => d.isAvailable).firstOrNull;
        return firstAvailable != null
            ? DateTime.tryParse(firstAvailable.date)
            : null;
      })();

      if (chosenDate != null) selectDate(chosenDate);
    } catch (e, stack) {
      // ignore: avoid_print
      print('Booking init error: $e\n$stack');
      state = state.copyWith(
        isLoading: false,
        serviceId: serviceId,
      );
    }
  }

  // ---- Employee step ----

  void selectEmployee(EmployeeModel employee) {
    state = state.clearEmployeeSelection().copyWith(
          selectedEmployee: employee,
          noPreference: false,
        );
    _refreshAvailability();
  }

  void selectNoPreference() {
    state = state.clearEmployeeSelection().copyWith(noPreference: true);
    _refreshAvailability();
  }

  // ---- Date/time step ----

  void selectDate(DateTime date) {
    state = state.copyWith(
      selectedDate: date,
      selectedSlot: null,
      availableSlots: const [],
    );
    _loadSlotsForDate(date);
  }

  void selectSlot(AvailableSlotModel slot) {
    state = state.copyWith(selectedSlot: slot);
    // E25 — booking_slot_selected
    if (state.companyId != null && state.serviceId != null) {
      unawaited(AnalyticsService.instance.logBookingSlotSelected(
        salonId: state.companyId!,
        serviceId: state.serviceId!,
      ));
    }
  }

  List<AvailableSlotModel> slotsForSelectedDate() {
    return state.availableSlots;
  }

  Future<void> _refreshAvailability() async {
    if (state.companyId == null) return;
    try {
      final raw = await _bookingDatasource.getAvailability(
        companyId: state.companyId!,
        employeeId:
            state.noPreference ? null : state.selectedEmployee?.id,
        serviceId: state.serviceId,
      );
      // Keep the target-1 window when the user is still searching with a
      // date in mind, so the picker doesn't silently grow back to "today +
      // 14 days" after a mid-flow employee change.
      final availability = _trimAvailabilityToTarget(raw, state.targetDate);

      state = state.copyWith(
        availability: availability,
        availableSlots: const [],
        selectedDate: null,
        selectedSlot: null,
      );

      // Prefer the user's searched date; fall back to the first open day.
      DateTime? chosenDate;
      final target = state.targetDate;
      if (target != null) {
        for (final d in availability) {
          if (!d.isAvailable) continue;
          final parsed = DateTime.tryParse(d.date);
          if (parsed == null) continue;
          if (parsed.year == target.year &&
              parsed.month == target.month &&
              parsed.day == target.day) {
            chosenDate = parsed;
            break;
          }
        }
      }
      chosenDate ??= (() {
        final firstAvailable =
            availability.where((d) => d.isAvailable).firstOrNull;
        return firstAvailable != null
            ? DateTime.tryParse(firstAvailable.date)
            : null;
      })();
      if (chosenDate != null) selectDate(chosenDate);
    } catch (_) {}
  }

  /// Drops days before `target - 1` so the date picker opens on the searched
  /// day's neighbour. `target - 1` is clamped to today — the user can never
  /// be offered a day in the past. Returns the input untouched when [target]
  /// is null.
  List<DayAvailability> _trimAvailabilityToTarget(
    List<DayAvailability> raw,
    DateTime? target,
  ) {
    if (target == null) return raw;

    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final targetOnly = DateTime(target.year, target.month, target.day);
    final candidate = targetOnly.subtract(const Duration(days: 1));
    final windowStart =
        candidate.isBefore(todayOnly) ? todayOnly : candidate;

    return raw.where((d) {
      final parsed = DateTime.tryParse(d.date);
      if (parsed == null) return true;
      final dayOnly = DateTime(parsed.year, parsed.month, parsed.day);
      return !dayOnly.isBefore(windowStart);
    }).toList();
  }

  Future<void> _loadSlotsForDate(DateTime date) async {
    if (state.companyId == null) return;
    state = state.copyWith(isLoadingSlots: true);
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final slots = await _bookingDatasource.getSlots(
        companyId: state.companyId!,
        date: dateStr,
        employeeId:
            state.noPreference ? null : state.selectedEmployee?.id,
        serviceId: state.serviceId,
      );
      state = state.copyWith(
        availableSlots: slots,
        isLoadingSlots: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingSlots: false);
    }
  }

  // ---- Navigation ----

  void nextStep() {
    if (state.currentStep < 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  // ---- Confirm ----

  Future<BookingModel?> confirmBooking({required String companyId}) async {
    if (state.selectedSlot == null) return null;

    state = state.copyWith(isLoading: true);

    try {
      final booking = await _bookingDatasource.createBooking(
        companyId: companyId,
        serviceId: state.serviceId ?? '',
        employeeId: state.noPreference ? null : state.selectedEmployee?.id,
        dateTime: _formatDateTime(state.selectedSlot!.dateTime),
      );

      state = state.copyWith(isLoading: false, isConfirmed: true);
      // E25 — booking_confirmed
      unawaited(AnalyticsService.instance.logBookingConfirmed(
        salonId: companyId,
        serviceId: state.serviceId ?? '',
        durationMinutes: state.serviceDuration ?? 0,
      ));
      return booking;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return null;
    }
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:$s';
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final bookingProvider =
    StateNotifierProvider.autoDispose<BookingNotifier, BookingState>(
  (ref) {
    final bookingDs = ref.watch(bookingDatasourceProvider);
    final companyDs = ref.watch(companyDetailDatasourceProvider);
    return BookingNotifier(
      bookingDatasource: bookingDs,
      companyDatasource: companyDs,
    );
  },
);
