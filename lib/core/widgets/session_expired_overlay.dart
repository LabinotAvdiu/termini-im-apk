import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/extensions.dart';

/// Wraps the app and listens for [AuthState.sessionExpired]. When the API
/// interceptor detects that the refresh token was rejected (real 401 on
/// /auth/refresh — not a transient network blip), it flips the flag via
/// `authStateProvider.notifier.triggerSessionExpired()`, and this widget
/// surfaces a modal asking the user to either re-authenticate or fall back
/// to guest browsing on /home.
///
/// Mounted from `app.dart` inside `MaterialApp.router(builder:)` so the
/// overlay sees a Navigator + Directionality + Theme even on the very
/// first frame.
class SessionExpiredOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const SessionExpiredOverlay({super.key, required this.child});

  @override
  ConsumerState<SessionExpiredOverlay> createState() =>
      _SessionExpiredOverlayState();
}

class _SessionExpiredOverlayState extends ConsumerState<SessionExpiredOverlay> {
  /// Tracks whether a modal is currently visible so a flurry of stacked 401s
  /// (from queued requests that all see the same token rejection) can't
  /// stack the same dialog multiple times.
  bool _modalOpen = false;

  ProviderSubscription<bool>? _sessionExpiredSub;

  @override
  void initState() {
    super.initState();
    // Use listenManual so the subscription is set up exactly once at mount
    // time, not on every build of the wrapper widget. The wrapper rarely
    // rebuilds (it only wraps the navigator), but listenManual is the
    // explicit pattern for "fire-and-forget" listeners that survive widget
    // rebuilds and don't depend on the build cycle to register.
    debugPrint('[overlay] initState — registering listenManual subscription');
    _sessionExpiredSub = ref.listenManual<bool>(
      authStateProvider.select((s) => s.sessionExpired),
      (previous, next) {
        debugPrint('[overlay] listener fired prev=$previous next=$next '
            'modalOpen=$_modalOpen');
        if (next == true && !_modalOpen) {
          _modalOpen = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              debugPrint('[overlay] post-frame fired but widget unmounted');
              return;
            }
            debugPrint('[overlay] post-frame fired → calling _showModal');
            _showModal();
          });
        }
      },
      // Fire once with the current value too, so if `sessionExpired` was
      // already true before this widget mounted (e.g. an interceptor 401
      // that fired during app startup), the modal still appears.
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _sessionExpiredSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  /// Action chosen by the user when the modal closes — drives the post-
  /// dismiss navigation. Captured here so the navigation runs AFTER the
  /// dialog has finished its pop animation and the underlying State context
  /// is settled (calling context.go() while the dialog is mid-pop has been
  /// flaky in production).
  _PostModalAction _pendingAction = _PostModalAction.none;

  Future<void> _showModal() async {
    debugPrint('[overlay] _showModal entry — about to showDialog');
    _pendingAction = _PostModalAction.none;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.55),
      // Use the root navigator so the dialog sits above any in-flight
      // GoRouter route transitions (the auth state wipe would normally
      // race the modal mount otherwise).
      useRootNavigator: true,
      builder: (dialogCtx) => _SessionExpiredDialog(
        onLogin: () {
          _pendingAction = _PostModalAction.goLogin;
          // Wipe auth state NOW (before nav). The router will re-evaluate
          // once we're on /login and not redirect anywhere unexpected.
          ref.read(authStateProvider.notifier).resolveSessionExpiredWithLogin();
          Navigator.of(dialogCtx).pop();
        },
        onHome: () {
          _pendingAction = _PostModalAction.goHomeAsGuest;
          ref.read(authStateProvider.notifier).resolveSessionExpiredWithGuest();
          Navigator.of(dialogCtx).pop();
        },
      ),
    );

    if (!mounted) {
      _modalOpen = false;
      return;
    }

    // Run the navigation AFTER the dialog has finished tearing down and the
    // next frame has rendered, otherwise GoRouter.of(context) can race with
    // the dialog's overlay removal and silently no-op.
    final action = _pendingAction;
    _pendingAction = _PostModalAction.none;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (action) {
        case _PostModalAction.goLogin:
          context.go('/login');
        case _PostModalAction.goHomeAsGuest:
          context.go('/home');
        case _PostModalAction.none:
          break;
      }
      _modalOpen = false;
    });
  }
}

/// Action picked by the user from the modal — applied AFTER the dialog has
/// fully popped so the navigation doesn't race the overlay teardown.
enum _PostModalAction { none, goLogin, goHomeAsGuest }

class _SessionExpiredDialog extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onHome;

  const _SessionExpiredDialog({
    required this.onLogin,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon — bordeaux gradient lock matching auth_required_modal
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF511522), Color(0xFF7A2232)],
                    ),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                Text(
                  l.sessionExpiredTitle,
                  style: AppTextStyles.h3,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  l.sessionExpiredMessage,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Primary action — Se connecter
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: Text(
                      l.sessionExpiredLoginAction,
                      style: AppTextStyles.button
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Secondary — Aller à l'accueil
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: onHome,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: Text(
                      l.sessionExpiredHomeAction,
                      style: AppTextStyles.button
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

