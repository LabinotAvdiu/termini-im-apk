import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../company_detail/data/datasources/company_detail_remote_datasource.dart';
import '../../../company_detail/data/models/company_detail_model.dart';
import '../../../company_detail/presentation/providers/company_detail_provider.dart';
import '../../data/datasources/booking_remote_datasource.dart';
import '../../data/models/available_slot_model.dart';
import '../../data/models/booking_model.dart';

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
  final bool isConfirmed;
  final List<EmployeeModel> employees;
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
    this.isConfirmed = false,
    this.employees = const [],
    this.availableSlots = const [],
    this.companyId,
    this.serviceId,
    this.serviceName,
    this.servicePrice,
    this.serviceDuration,
  });

  bool get canProceedStep0 => noPreference || selectedEmployee != null;
  bool get canProceedStep1 => selectedSlot != null;

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
    bool? isConfirmed,
    List<EmployeeModel>? employees,
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
      isConfirmed: isConfirmed ?? this.isConfirmed,
      employees: employees ?? this.employees,
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
      selectedDate: selectedDate,
      selectedSlot: selectedSlot,
      isLoading: isLoading,
      isConfirmed: isConfirmed,
      employees: employees,
      availableSlots: availableSlots,
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

      // Load slots for today
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final slots = await _loadSlotsForDate(companyId, today, serviceId);

      state = state.copyWith(
        employees: employees,
        availableSlots: slots,
        serviceId: serviceId,
        serviceName: serviceName ?? 'Service',
        servicePrice: servicePrice ?? 0.0,
        serviceDuration: serviceDuration ?? 30,
        selectedDate: today,
        noPreference: true, // "Sans préférence" selected by default
        isLoading: false,
      );
    } catch (e, stack) {
      // ignore: avoid_print
      print('Booking init error: $e\n$stack');
      // Fallback: still show UI with empty data
      state = state.copyWith(
        isLoading: false,
        serviceId: serviceId,
      );
    }
  }

  Future<List<AvailableSlotModel>> _loadSlotsForDate(
    String companyId,
    DateTime date,
    String? serviceId,
  ) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _bookingDatasource.getSlots(
      companyId: companyId,
      date: dateStr,
      employeeId:
          state.noPreference ? null : state.selectedEmployee?.id,
      serviceId: serviceId,
    );
  }

  // ---- Employee step ----

  void selectEmployee(EmployeeModel employee) {
    state = state.clearEmployeeSelection().copyWith(
          selectedEmployee: employee,
          noPreference: false,
        );
    _refreshSlots();
  }

  void selectNoPreference() {
    state = state.clearEmployeeSelection().copyWith(noPreference: true);
    _refreshSlots();
  }

  // ---- Date/time step ----

  void selectDate(DateTime date) {
    state = state.copyWith(
      selectedDate: date,
      selectedSlot: null,
    );
    _refreshSlots();
  }

  void selectSlot(AvailableSlotModel slot) {
    state = state.copyWith(selectedSlot: slot);
  }

  List<AvailableSlotModel> slotsForSelectedDate() {
    if (state.selectedDate == null) return [];
    final d = state.selectedDate!;
    return state.availableSlots
        .where((s) =>
            s.dateTime.year == d.year &&
            s.dateTime.month == d.month &&
            s.dateTime.day == d.day)
        .toList();
  }

  Future<void> _refreshSlots() async {
    if (state.companyId == null || state.selectedDate == null) return;
    try {
      final slots = await _loadSlotsForDate(
        state.companyId!,
        state.selectedDate!,
        state.serviceId,
      );
      state = state.copyWith(availableSlots: slots, selectedSlot: null);
    } catch (_) {
      // Keep current slots on error
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

  /// Format DateTime as Y-m-dTH:i:s (no milliseconds) for the Laravel API.
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
