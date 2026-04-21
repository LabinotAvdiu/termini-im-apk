import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/providers/ux_prefs_provider.dart';
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

  /// Ids of appointments with a cancel request in flight. The client card
  /// can show a per-item spinner; the provider also drops same-id double-taps.
  final Set<String> cancellingIds;

  const AppointmentsState({
    this.isLoading = false,
    this.error,
    this.appointments = const [],
    this.cancellingIds = const <String>{},
  });

  AppointmentsState copyWith({
    bool? isLoading,
    String? error,
    List<AppointmentModel>? appointments,
    Set<String>? cancellingIds,
  }) {
    return AppointmentsState(
      isLoading: isLoading ?? this.isLoading,
      // Explicit null clears the error (same pattern as AuthState).
      error: error,
      appointments: appointments ?? this.appointments,
      cancellingIds: cancellingIds ?? this.cancellingIds,
    );
  }

  // ---------------------------------------------------------------------------
  // Derived lists (computed, not stored)
  // ---------------------------------------------------------------------------

  /// Upcoming: non-terminal status (`confirmed` / `pending`) AND the start
  /// time is still in the future. We compare against `now` (not the start
  /// of today) so a confirmed appointment at 13:00 flips to "past" as soon
  /// as 13:00 has elapsed — otherwise clients can't leave a review on an
  /// appointment that already happened earlier the same day.
  List<AppointmentModel> get upcoming {
    final now = DateTime.now();
    return appointments
        .where((a) =>
            (a.status == 'confirmed' || a.status == 'pending') &&
            a.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Past: a terminal status (completed / cancelled / rejected / no_show),
  /// OR the start time has passed (even if the status is still confirmed/
  /// pending — same-day RDV earlier today should appear here so the review
  /// CTA is reachable).
  List<AppointmentModel> get past {
    final now = DateTime.now();
    return appointments
        .where((a) =>
            a.status == 'completed' ||
            a.status == 'cancelled' ||
            a.status == 'rejected' ||
            a.status == 'no_show' ||
            !a.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AppointmentsNotifier extends StateNotifier<AppointmentsState> {
  final AppointmentsRemoteDatasource _datasource;
  final Ref _ref;

  AppointmentsNotifier({
    required AppointmentsRemoteDatasource datasource,
    required Ref ref,
  })  : _datasource = datasource,
        _ref = ref,
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

  /// Feature 1 — Cancel an appointment (client side).
  ///
  /// Returns true on success, false on failure.
  /// The caller is responsible for showing a SnackBar with the result.
  Future<bool> cancel(String id, {String? reason}) async {
    if (!mounted) return false;
    // Drop rapid double-taps on the same card (swipe + tap cancel button can
    // otherwise fire two requests before the UI rebuilds).
    if (state.cancellingIds.contains(id)) return false;
    state = state.copyWith(cancellingIds: {...state.cancellingIds, id});
    try {
      final updated = await _datasource.cancelAppointment(id, reason: reason);
      // Replace in-place — keep list order stable.
      final newList = state.appointments.map((a) {
        return a.id == id ? updated : a;
      }).toList();
      if (!mounted) return false;
      state = state.copyWith(
        appointments: newList,
        error: null,
        cancellingIds: state.cancellingIds.difference({id}),
      );

      // Haptic feedback on success.
      if (!kIsWeb) {
        final uxPrefs = _ref.read(uxPrefsProvider);
        if (uxPrefs.hapticEnabled) {
          await HapticFeedback.mediumImpact();
        }
      }
      return true;
    } catch (e) {
      if (!mounted) return false;
      // Expose error so the UI can build a localized message.
      state = state.copyWith(
        error: e.toString(),
        cancellingIds: state.cancellingIds.difference({id}),
      );
      return false;
    }
  }

  /// Returns the last error as an [ApiException] if available.
  ApiException? get lastApiError {
    final e = state.error;
    if (e == null) return null;
    // We store e.toString() — a best-effort re-parse isn't reliable.
    // Callers should catch the exception directly via cancel().
    return null;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final appointmentsProvider =
    StateNotifierProvider<AppointmentsNotifier, AppointmentsState>((ref) {
  final datasource = ref.watch(appointmentsDatasourceProvider);
  return AppointmentsNotifier(datasource: datasource, ref: ref);
});
