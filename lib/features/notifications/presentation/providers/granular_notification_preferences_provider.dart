import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/notification_preferences_remote_datasource.dart';
import '../../data/models/notification_preference_model.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class GranularPreferencesState {
  final bool isLoading;
  final List<NotificationPreferenceModel> preferences;
  final Object? error;

  const GranularPreferencesState({
    this.isLoading = false,
    this.preferences = const [],
    this.error,
  });

  GranularPreferencesState copyWith({
    bool? isLoading,
    List<NotificationPreferenceModel>? preferences,
    Object? error,
  }) {
    return GranularPreferencesState(
      isLoading: isLoading ?? this.isLoading,
      preferences: preferences ?? this.preferences,
      error: error,
    );
  }

  /// Retourne l'état `enabled` pour un (channel, type) donné.
  /// Défaut `true` si la ligne n'existe pas encore.
  bool isEnabled(String channel, String type) {
    try {
      return preferences
          .firstWhere((p) => p.channel == channel && p.type == type)
          .enabled;
    } catch (_) {
      return true; // défaut optimiste
    }
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class GranularNotificationPreferencesNotifier
    extends StateNotifier<GranularPreferencesState> {
  final NotificationPreferencesRemoteDatasource _datasource;

  GranularNotificationPreferencesNotifier(this._datasource)
      : super(const GranularPreferencesState());

  // ---- Load ---------------------------------------------------------------

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await _datasource.getAll();
      state = state.copyWith(isLoading: false, preferences: prefs);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  // ---- Toggle (optimistic) -----------------------------------------------

  /// Change la valeur d'un (channel, type) avec optimistic update + rollback.
  Future<void> toggle(String channel, String type, bool value) async {
    final previousPrefs = state.preferences;

    // Optimistic update local
    final updated = previousPrefs.map((p) {
      if (p.channel == channel && p.type == type) {
        return p.copyWith(enabled: value);
      }
      return p;
    }).toList();

    // Si la ligne n'existe pas encore, on l'ajoute
    if (!updated.any((p) => p.channel == channel && p.type == type)) {
      updated.add(NotificationPreferenceModel(
        channel: channel,
        type: type,
        enabled: value,
      ));
    }

    state = state.copyWith(preferences: updated, error: null);

    try {
      final serverPrefs = await _datasource.updateAll([
        NotificationPreferenceModel(
          channel: channel,
          type: type,
          enabled: value,
        ),
      ]);
      // Remplace par la réponse serveur complète
      state = state.copyWith(preferences: serverPrefs);
    } catch (e) {
      // Rollback
      state = state.copyWith(preferences: previousPrefs, error: e);
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _notificationPrefsDatasourceProvider =
    Provider<NotificationPreferencesRemoteDatasource>((ref) {
  final client = ref.watch(dioClientProvider);
  return NotificationPreferencesRemoteDatasource(client);
});

final granularNotificationPreferencesProvider = StateNotifierProvider<
    GranularNotificationPreferencesNotifier, GranularPreferencesState>((ref) {
  final datasource = ref.watch(_notificationPrefsDatasourceProvider);
  return GranularNotificationPreferencesNotifier(datasource);
});
