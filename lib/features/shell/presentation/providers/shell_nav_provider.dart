import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Logical identifier for a shell tab. The concrete index depends on the
/// authenticated role (owner vs. client vs. employee) and the salon mode,
/// so we don't hard-code integers outside of [MainShell].
enum ShellTab { home, salon, planning, schedule, pending, appointments }

/// A pending navigation inside the main shell, usually posted from a
/// non-tab screen (e.g. the "À confirmer" empty state asking to jump to
/// Mon Salon with an auto-scroll target).
class ShellNavRequest {
  final ShellTab tab;
  /// Optional scroll anchor key consumed by the destination screen. See
  /// [autoApproveCardKeyProvider] for the matching GlobalKey instance.
  final String? scrollTo;

  const ShellNavRequest({required this.tab, this.scrollTo});
}

class ShellNavNotifier extends StateNotifier<ShellNavRequest?> {
  ShellNavNotifier() : super(null);

  void request(ShellTab tab, {String? scrollTo}) {
    state = ShellNavRequest(tab: tab, scrollTo: scrollTo);
  }

  /// Clears the whole request. Called by the destination screen once it has
  /// consumed both the tab switch and any scroll anchor. When no `scrollTo`
  /// was set, [MainShell] itself clears right after switching tabs.
  void clear() => state = null;
}

final shellNavProvider =
    StateNotifierProvider<ShellNavNotifier, ShellNavRequest?>(
        (ref) => ShellNavNotifier());

/// Shared anchor for the auto-approve toggle card on the Mon Salon dashboard.
/// Read from both the card widget (attached) and the scroll handler (used to
/// resolve the current render context at scroll time).
final autoApproveCardKeyProvider =
    Provider<GlobalKey>((ref) => GlobalKey(debugLabel: 'autoApproveCard'));
