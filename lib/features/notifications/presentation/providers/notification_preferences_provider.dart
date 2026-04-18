import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notification_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class NotificationPreferencesState {
  final bool isLoading;
  final NotificationPreferences? preferences;
  final Object? error;

  const NotificationPreferencesState({
    this.isLoading = false,
    this.preferences,
    this.error,
  });

  NotificationPreferencesState copyWith({
    bool? isLoading,
    NotificationPreferences? preferences,
    Object? error,
  }) {
    return NotificationPreferencesState(
      isLoading: isLoading ?? this.isLoading,
      preferences: preferences ?? this.preferences,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferencesState> {
  final NotificationRepository _repository;

  NotificationPreferencesNotifier(this._repository)
      : super(const NotificationPreferencesState());

  // ---- Load ----------------------------------------------------------------

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await _repository.getPreferences();
      state = state.copyWith(isLoading: false, preferences: prefs);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  // ---- Toggle notifyNewBooking (optimistic) --------------------------------

  Future<void> setNewBooking(bool value) async {
    final previous = state.preferences;
    if (previous == null) return;

    // Optimistic update
    state = state.copyWith(
      preferences: previous.copyWith(notifyNewBooking: value),
      error: null,
    );

    try {
      await _repository.updatePreferences(
        previous.copyWith(notifyNewBooking: value),
      );
    } catch (e) {
      // Rollback
      state = state.copyWith(preferences: previous, error: e);
    }
  }

  // ---- Toggle notifyQuietDayReminder (optimistic) --------------------------

  Future<void> setQuietDayReminder(bool value) async {
    final previous = state.preferences;
    if (previous == null) return;

    // Optimistic update
    state = state.copyWith(
      preferences: previous.copyWith(notifyQuietDayReminder: value),
      error: null,
    );

    try {
      await _repository.updatePreferences(
        previous.copyWith(notifyQuietDayReminder: value),
      );
    } catch (e) {
      // Rollback
      state = state.copyWith(preferences: previous, error: e);
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final notificationPreferencesProvider = StateNotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferencesState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationPreferencesNotifier(repository);
});
