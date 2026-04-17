import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
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
  });

  bool get canProceedStep0 =>
      (noPreference || selectedEmployee != null) && selectedSlot != null;
  bool get canProceedStep1 => true;

  String get employeeDisplayName {
    if (noPreference) return 'Sans préférence';
    return selectedEmployee?.name ?? 'Sans préférence';
  }

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

      // Load availability (14 days) — no employee selected yet (sans préférence)
      final availability = await _bookingDatasource.getAvailability(
        companyId: companyId,
        serviceId: serviceId,
      );

      state = state.copyWith(
        employees: filteredEmployees,
        availability: availability,
        serviceId: serviceId,
        serviceName: serviceName ?? 'Service',
        servicePrice: servicePrice ?? 0.0,
        serviceDuration: serviceDuration ?? 30,
        noPreference: true,
        isLoading: false,
      );

      // Auto-select first available date
      final firstAvailable = availability
          .where((d) => d.isAvailable)
          .firstOrNull;
      if (firstAvailable != null) {
        final dateObj = DateTime.tryParse(firstAvailable.date);
        if (dateObj != null) selectDate(dateObj);
      }
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
  }

  List<AvailableSlotModel> slotsForSelectedDate() {
    return state.availableSlots;
  }

  Future<void> _refreshAvailability() async {
    if (state.companyId == null) return;
    try {
      final availability = await _bookingDatasource.getAvailability(
        companyId: state.companyId!,
        employeeId:
            state.noPreference ? null : state.selectedEmployee?.id,
        serviceId: state.serviceId,
      );
      state = state.copyWith(
        availability: availability,
        availableSlots: const [],
        selectedDate: null,
        selectedSlot: null,
      );

      // Auto-select first available date
      final firstAvailable = availability
          .where((d) => d.isAvailable)
          .firstOrNull;
      if (firstAvailable != null) {
        final dateObj = DateTime.tryParse(firstAvailable.date);
        if (dateObj != null) selectDate(dateObj);
      }
    } catch (_) {}
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
