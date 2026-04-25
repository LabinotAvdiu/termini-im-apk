import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/notifications/models/in_app_notification.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/models/notification_log_entry_model.dart';
import '../providers/notifications_log_provider.dart';

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

/// Section « Historique / Inbox » à insérer dans la page notifications.
/// Charge les 50 dernières notifs des 30 derniers jours, groupées par jour.
class NotificationsInboxSection extends ConsumerStatefulWidget {
  const NotificationsInboxSection({super.key});

  @override
  ConsumerState<NotificationsInboxSection> createState() =>
      _NotificationsInboxSectionState();
}

class _NotificationsInboxSectionState
    extends ConsumerState<NotificationsInboxSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsLogProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsLogProvider);

    // Affiche les erreurs réseau sans bloquer l'UI
    ref.listen<NotificationsLogState>(notificationsLogProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error && mounted) {
        context.showErrorSnackBar(next.error);
      }
    });

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient stripe éditorial
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // En-tête
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inbox_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _InboxTitle(
                    title: context.l10n.notificationsInboxTitle,
                    unreadCount: state.unreadCount,
                  ),
                ),
              ],
            ),
          ),

          // Lien "Tout marquer comme lu"
          if (state.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs,
              ),
              child: GestureDetector(
                onTap: () =>
                    ref.read(notificationsLogProvider.notifier).markAllAsRead(),
                child: Text(
                  context.l10n.notificationsInboxMarkAllRead,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 12,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ),

          const Divider(height: 1, color: AppColors.divider),

          // Corps
          if (state.isLoading && state.entries.isEmpty)
            const _InboxSkeleton()
          else if (state.entries.isEmpty)
            const _EmptyState()
          else
            _InboxList(entries: state.entries),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Titre avec compteur non-lu en Instrument Serif italic
// ---------------------------------------------------------------------------

class _InboxTitle extends StatelessWidget {
  final String title;
  final int unreadCount;

  const _InboxTitle({required this.title, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: GoogleFonts.fraunces(
            fontSize: 19,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            height: 1.15,
            letterSpacing: -0.2,
          ),
        ),
        if (unreadCount > 0) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            context.l10n.notificationsInboxUnreadCount(unreadCount),
            style: GoogleFonts.instrumentSerif(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Liste groupée par jour
// ---------------------------------------------------------------------------

class _InboxList extends ConsumerWidget {
  final List<NotificationLogEntry> entries;

  const _InboxList({required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Grouper par date locale (yyyy-MM-dd)
    final groups = <String, List<NotificationLogEntry>>{};
    for (final e in entries) {
      final key = _dateKey(e.sentAt);
      groups.putIfAbsent(key, () => []).add(e);
    }

    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final maxWidth = isDesktop ? 640.0 : double.infinity;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final key in groups.keys) ...[
              _DayHeader(label: _dayLabel(context, key)),
              for (int i = 0; i < groups[key]!.length; i++) ...[
                _EntryTile(
                  entry: groups[key]![i],
                  onTap: () => _handleTap(context, ref, groups[key]![i]),
                ),
                if (i < groups[key]!.length - 1)
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Divider(height: 1, color: AppColors.divider),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  String _dayLabel(BuildContext context, String key) {
    final now = DateTime.now();
    final today = _dateKey(now);
    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    if (key == today) return context.l10n.notificationsInboxToday;
    if (key == yesterday) return context.l10n.notificationsInboxYesterday;
    // Format "23 avril"
    final dt = DateTime.parse(key);
    const months = [
      '', 'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc',
    ];
    return '${dt.day} ${months[dt.month]}';
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref,
    NotificationLogEntry entry,
  ) {
    // Mark as read
    if (!entry.isRead) {
      ref.read(notificationsLogProvider.notifier).markAsRead(entry.id);
    }

    // Deep-link selon ref_type (même logique que main.dart notification callback)
    if (entry.refType == 'appointment') {
      final isOwnerType = const {
        'appointment.created',
        'appointment.cancelled_by_client',
        'walk_in_created',
        'capacity_full',
        'new_review',
      }.contains(entry.type);
      if (isOwnerType) {
        context.push('/pending-approvals');
      } else {
        context.push('/my-appointments');
      }
    } else if (entry.refType == 'review') {
      context.push('/my-company/reviews');
    }
    // Pas de deep link pour email/marketing : tap sans navigation
  }
}

// ---------------------------------------------------------------------------
// En-tête de jour
// ---------------------------------------------------------------------------

class _DayHeader extends StatelessWidget {
  final String label;
  const _DayHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + 4,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.instrumentSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tuile d'une entrée
// ---------------------------------------------------------------------------

class _EntryTile extends StatelessWidget {
  final NotificationLogEntry entry;
  final VoidCallback onTap;

  const _EntryTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final v = variantForType(entry.type);
    final isRead = entry.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFFEFE6D5), // ivoryAlt
        splashColor: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dot non-lu
              SizedBox(
                width: 12,
                child: isRead
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
              ),

              const SizedBox(width: 4),

              // Icône variante
              _VariantIcon(variant: v.variant, icon: v.icon),

              const SizedBox(width: AppSpacing.sm + 2),

              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre + temps relatif sur la même ligne
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            entry.title.isNotEmpty
                                ? entry.title
                                : entry.type,
                            style: GoogleFonts.fraunces(
                              fontSize: 14,
                              fontWeight: isRead
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                              color: isRead
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _relativeTime(entry.sentAt),
                          style: GoogleFonts.instrumentSans(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    if (entry.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 12,
                          color: AppColors.textHint,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Channel badge
                    _ChannelBadge(channel: entry.channel, context: context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Icône circulaire 32px avec tint selon variant
// ---------------------------------------------------------------------------

class _VariantIcon extends StatelessWidget {
  final InAppNotificationVariant variant;
  final IconData icon;

  const _VariantIcon({required this.variant, required this.icon});

  Color get _tint => switch (variant) {
        InAppNotificationVariant.positive => AppColors.secondary,
        InAppNotificationVariant.info     => AppColors.primary,
        InAppNotificationVariant.attention => AppColors.primaryDark,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _tint.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: _tint),
    );
  }
}

// ---------------------------------------------------------------------------
// Channel badge — PUSH / EMAIL / IN-APP
// ---------------------------------------------------------------------------

class _ChannelBadge extends StatelessWidget {
  final String channel;
  final BuildContext context;

  const _ChannelBadge({required this.channel, required this.context});

  String _label(BuildContext ctx) => switch (channel) {
        'email'  => ctx.l10n.notificationsChannelEmail,
        'in-app' => ctx.l10n.notificationsChannelInApp,
        _        => ctx.l10n.notificationsChannelPush,
      };

  @override
  Widget build(BuildContext ctx) {
    return Text(
      _label(context),
      style: GoogleFonts.instrumentSans(
        fontSize: 9,
        letterSpacing: 1.2,
        color: AppColors.textHint,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 40,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.notificationsInboxEmptyTitle,
            style: GoogleFonts.fraunces(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.notificationsInboxEmptySubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSans(
              fontSize: 13,
              color: AppColors.textHint,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loading
// ---------------------------------------------------------------------------

class _InboxSkeleton extends StatelessWidget {
  const _InboxSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _skeletonBox(w: 12, h: 6, radius: 3),
              const SizedBox(width: 4),
              _skeletonBox(w: 32, h: 32, radius: 16),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonBox(w: 160, h: 12, radius: 4),
                    const SizedBox(height: 6),
                    _skeletonBox(w: double.infinity, h: 10, radius: 4),
                    const SizedBox(height: 4),
                    _skeletonBox(w: 40, h: 8, radius: 4),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _skeletonBox({
    required double w,
    required double h,
    required double radius,
  }) {
    return Container(
      width: w == double.infinity ? null : w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.ivoryAlt,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper temps relatif — pur Dart, pas de dépendance intl
// ---------------------------------------------------------------------------

String _relativeTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1)  return 'maintenant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24)   return 'il y a ${diff.inHours} h';
  if (diff.inDays == 1)    return 'hier ${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
  if (diff.inDays < 7)     return 'il y a ${diff.inDays} j';

  const months = [
    '', 'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
    'juil', 'août', 'sep', 'oct', 'nov', 'déc',
  ];
  return '${dt.day} ${months[dt.month]}';
}
