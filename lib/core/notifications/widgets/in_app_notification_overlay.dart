import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/in_app_notification.dart';
import '../providers/in_app_notification_provider.dart';
import 'in_app_notification_card.dart';

// ---------------------------------------------------------------------------
// InAppNotificationOverlay
// ---------------------------------------------------------------------------

/// Widget racine qui encapsule le contenu de l'app dans un [Stack].
///
/// Place les toasts :
/// - **Mobile** (< 600px) : top-center, sous la status bar + app bar.
///   Marges latérales de 16px. Ne couvre pas la bottom nav (les toasts
///   apparaissent dans la zone de contenu).
/// - **Desktop** (>= 600px) : top-right, width fixe 360px, padding 16px.
///
/// Usage : envelopper le widget enfant de `MaterialApp.router` dans `app.dart`
/// (ou l'insérer comme layer dans le [Stack] racine).
class InAppNotificationOverlay extends ConsumerWidget {
  const InAppNotificationOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(
      inAppNotificationProvider.select((s) => s.visible),
    );
    final notifier = ref.read(inAppNotificationProvider.notifier);

    final isDesktop = MediaQuery.sizeOf(context).width >= 600;

    return Stack(
      children: [
        child,
        if (notifications.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              // Ne bloque le toucher que dans la zone des toasts.
              ignoring: false,
              child: SafeArea(
                bottom: false, // On ne safe-area le bas — la bottom nav gère ça.
                child: Align(
                  alignment: isDesktop
                      ? Alignment.topRight
                      : Alignment.topCenter,
                  child: Padding(
                    padding: isDesktop
                        ? const EdgeInsets.only(top: 16, right: 16)
                        : const EdgeInsets.symmetric(horizontal: 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 360 : double.infinity,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < notifications.length; i++)
                            _NotifSlot(
                              key: ValueKey(notifications[i].id),
                              notification: notifications[i],
                              index: i,
                              slideFromTop: !isDesktop,
                              onDismiss: () =>
                                  notifier.dismiss(notifications[i].id),
                              onPause: () =>
                                  notifier.pauseTimer(notifications[i].id),
                              onResume: () => notifier.resumeTimer(
                                notifications[i].id,
                                notifications[i].duration,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _NotifSlot — wrapper qui applique opacité + scale pour l'effet de pile
// ---------------------------------------------------------------------------

class _NotifSlot extends StatelessWidget {
  const _NotifSlot({
    super.key,
    required this.notification,
    required this.index,
    required this.slideFromTop,
    required this.onDismiss,
    required this.onPause,
    required this.onResume,
  });

  final InAppNotification notification;

  /// 0 = toast le plus récent (visible plein), 1 et 2 = derrière.
  final int index;
  final bool slideFromTop;
  final VoidCallback onDismiss;
  final VoidCallback onPause;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    // Les toasts derrière sont légèrement plus petits et transparents.
    final scale = switch (index) {
      0 => 1.0,
      1 => 0.97,
      _ => 0.94,
    };
    final opacity = switch (index) {
      0 => 1.0,
      1 => 0.85,
      _ => 0.65,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: index == 0 ? 6.0 : 4.0),
      child: Transform.scale(
        scale: scale,
        alignment:
            slideFromTop ? Alignment.topCenter : Alignment.topRight,
        child: Opacity(
          opacity: opacity,
          child: InAppNotificationCard(
            notification: notification,
            onDismiss: onDismiss,
            onPause: onPause,
            onResume: onResume,
            slideFromTop: slideFromTop,
          ),
        ),
      ),
    );
  }
}
