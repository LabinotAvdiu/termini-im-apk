import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/in_app_notification.dart';

// ---------------------------------------------------------------------------
// Constantes
// ---------------------------------------------------------------------------

/// Nombre maximum de toasts simultanément visibles à l'écran.
const int _kMaxVisible = 3;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class InAppNotificationState {
  const InAppNotificationState({
    required this.visible,
    required this.queue,
  });

  /// Notifs actuellement affichées (max [_kMaxVisible]).
  final List<InAppNotification> visible;

  /// Notifs en attente d'affichage (FIFO).
  final Queue<InAppNotification> queue;

  InAppNotificationState copyWith({
    List<InAppNotification>? visible,
    Queue<InAppNotification>? queue,
  }) {
    return InAppNotificationState(
      visible: visible ?? this.visible,
      queue: queue ?? this.queue,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class InAppNotificationNotifier
    extends Notifier<InAppNotificationState> {
  /// Timers d'auto-dismiss, indexés par notification id.
  final Map<String, Timer> _timers = {};

  @override
  InAppNotificationState build() {
    // Nettoyage quand le provider est disposé (ex : rebuild de l'arbre).
    ref.onDispose(() {
      for (final t in _timers.values) {
        t.cancel();
      }
      _timers.clear();
    });

    return InAppNotificationState(
      visible: const [],
      queue: Queue<InAppNotification>(),
    );
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Ajoute une notification au système.
  ///
  /// Si moins de [_kMaxVisible] toasts sont affichés, la notif entre
  /// immédiatement. Sinon elle rejoint la queue interne et sera affichée
  /// dès qu'un slot se libère.
  void show(InAppNotification notification) {
    final current = state;

    if (current.visible.length < _kMaxVisible) {
      _display(notification);
    } else {
      final newQueue = Queue<InAppNotification>.from(current.queue);
      newQueue.addLast(notification);
      state = current.copyWith(queue: newQueue);
    }
  }

  /// Retire une notification (dismiss manuel ou auto-dismiss).
  ///
  /// Si des notifs attendent en queue, la première est affichée immédiatement.
  void dismiss(String id) {
    _timers[id]?.cancel();
    _timers.remove(id);

    final current = state;
    final newVisible = List<InAppNotification>.from(current.visible)
      ..removeWhere((n) => n.id == id);
    final newQueue = Queue<InAppNotification>.from(current.queue);

    state = current.copyWith(visible: newVisible, queue: newQueue);

    // Si une notif attend en queue et qu'un slot s'est libéré, on la sort.
    if (newQueue.isNotEmpty && newVisible.length < _kMaxVisible) {
      final next = newQueue.removeFirst();
      state = state.copyWith(queue: newQueue);
      _display(next);
    }
  }

  /// Pause le countdown d'une notification (desktop : hover).
  void pauseTimer(String id) {
    _timers[id]?.cancel();
    _timers.remove(id);
  }

  /// Reprend le countdown d'une notification avec le temps restant.
  ///
  /// Pour simplifier : on relance avec la durée complète.
  /// Une implémentation avancée pourrait mémoriser le temps restant.
  void resumeTimer(String id, Duration remaining) {
    _scheduleAutoDissmiss(id, remaining);
  }

  // ---------------------------------------------------------------------------
  // Privé
  // ---------------------------------------------------------------------------

  void _display(InAppNotification notification) {
    final newVisible = List<InAppNotification>.from(state.visible)
      ..add(notification);
    state = state.copyWith(visible: newVisible);
    _scheduleAutoDissmiss(notification.id, notification.duration);
  }

  void _scheduleAutoDissmiss(String id, Duration delay) {
    _timers[id] = Timer(delay, () => dismiss(id));
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final inAppNotificationProvider =
    NotifierProvider<InAppNotificationNotifier, InAppNotificationState>(
  InAppNotificationNotifier.new,
);
