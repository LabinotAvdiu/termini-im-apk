import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../providers/notifications_log_provider.dart';
import '../widgets/notifications_inbox_section.dart';

/// Écran dédié "Mes notifications" — atterri depuis Settings > Mes pages.
///
/// Header unifié [AppTopBar.standard] avec action "Tout marquer lu" en trailing
/// quand il y a des non-lues (préserve la fonctionnalité, simplifie le chrome).
class NotificationsInboxScreen extends ConsumerWidget {
  const NotificationsInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(
      notificationsLogProvider.select((s) => s.unreadCount),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar.standard(
        title: context.l10n.myNotifications,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed('settings');
          }
        },
        actions: unread > 0
            ? [
                _MarkAllReadButton(
                  label: context.l10n.notificationsInboxMarkAllRead,
                  onTap: () => ref
                      .read(notificationsLogProvider.notifier)
                      .markAllAsRead(),
                ),
                const SizedBox(width: AppSpacing.xs),
              ]
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const NotificationsInboxSection(),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action "Tout marquer comme lu"
// ---------------------------------------------------------------------------

class _MarkAllReadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MarkAllReadButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.instrumentSerif(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.check_rounded,
                size: 14,
                color: AppColors.primary.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
