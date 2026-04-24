import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/notifications_log_remote_datasource.dart';
import '../../data/models/notification_log_entry_model.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class NotificationsLogState {
  const NotificationsLogState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  final List<NotificationLogEntry> entries;
  final bool isLoading;
  final String? error;

  int get unreadCount => entries.where((e) => !e.isRead).length;

  NotificationsLogState copyWith({
    List<NotificationLogEntry>? entries,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsLogState(
      entries:   entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error:     clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class NotificationsLogNotifier extends StateNotifier<NotificationsLogState> {
  NotificationsLogNotifier(this._datasource)
      : super(const NotificationsLogState());

  final NotificationsLogRemoteDatasource _datasource;

  /// Chargement initial (ou refresh).
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final entries = await _datasource.fetchLog();
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Marque une entrée comme lue — mise à jour optimiste immédiate,
  /// puis appel réseau en arrière-plan.
  Future<void> markAsRead(int id) async {
    final now = DateTime.now();
    // Mise à jour optimiste
    state = state.copyWith(
      entries: state.entries.map((e) {
        if (e.id == id && !e.isRead) return e.copyWith(readAt: now);
        return e;
      }).toList(),
    );
    try {
      await _datasource.markAsRead(id);
    } catch (_) {
      // Rollback silencieux — l'UI reste en l'état,
      // un refresh ultérieur corrigera.
    }
  }

  /// Marque toutes les notifications non lues comme lues — optimiste.
  Future<void> markAllAsRead() async {
    final now = DateTime.now();
    state = state.copyWith(
      entries: state.entries.map((e) {
        if (!e.isRead) return e.copyWith(readAt: now);
        return e;
      }).toList(),
    );
    try {
      await _datasource.markAllAsRead();
    } catch (_) {
      // Même stratégie : rollback silencieux sur erreur réseau.
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _notificationsLogDatasourceProvider =
    Provider<NotificationsLogRemoteDatasource>((ref) {
  return NotificationsLogRemoteDatasource(ref.watch(dioClientProvider));
});

final notificationsLogProvider = StateNotifierProvider<
    NotificationsLogNotifier, NotificationsLogState>((ref) {
  return NotificationsLogNotifier(
    ref.watch(_notificationsLogDatasourceProvider),
  );
});
