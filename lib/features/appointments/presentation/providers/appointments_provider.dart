import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/appointments_remote_datasource.dart';
import '../../data/models/appointment_model.dart';

// ---------------------------------------------------------------------------
// Datasource provider
// ---------------------------------------------------------------------------

final appointmentsDatasourceProvider =
    Provider<AppointmentsRemoteDatasource>((ref) {
  final client = ref.watch(dioClientProvider);
  return AppointmentsRemoteDatasource(client: client);
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AppointmentsState {
  final bool isLoading;
  final String? error;
  final List<AppointmentModel> appointments;

  const AppointmentsState({
    this.isLoading = false,
    this.error,
    this.appointments = const [],
  });

  AppointmentsState copyWith({
    bool? isLoading,
    String? error,
    List<AppointmentModel>? appointments,
  }) {
    return AppointmentsState(
      isLoading: isLoading ?? this.isLoading,
      // Explicit null clears the error (same pattern as AuthState).
      error: error,
      appointments: appointments ?? this.appointments,
    );
  }

  // ---------------------------------------------------------------------------
  // Derived lists (computed, not stored)
  // ---------------------------------------------------------------------------

  /// Upcoming: status is 'confirmed' or 'pending', AND date >= today.
  /// Sorted by date ASC so the nearest appointment appears first.
  List<AppointmentModel> get upcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return appointments
        .where((a) =>
            (a.status == 'confirmed' || a.status == 'pending') &&
            !a.dateTime.isBefore(today))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Past: status is 'completed' or 'cancelled', OR date < today.
  /// Sorted by date DESC so the most recent past appointment appears first.
  List<AppointmentModel> get past {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return appointments
        .where((a) =>
            a.status == 'completed' ||
            a.status == 'cancelled' ||
            a.dateTime.isBefore(today))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AppointmentsNotifier extends StateNotifier<AppointmentsState> {
  final AppointmentsRemoteDatasource _datasource;

  AppointmentsNotifier({required AppointmentsRemoteDatasource datasource})
      : _datasource = datasource,
        super(const AppointmentsState()) {
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _datasource.getMyAppointments();
      state = state.copyWith(isLoading: false, appointments: list, error: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        appointments: state.appointments,
      );
    }
  }

  Future<void> refresh() => fetchAppointments();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final appointmentsProvider =
    StateNotifierProvider<AppointmentsNotifier, AppointmentsState>((ref) {
  final datasource = ref.watch(appointmentsDatasourceProvider);
  return AppointmentsNotifier(datasource: datasource);
});
