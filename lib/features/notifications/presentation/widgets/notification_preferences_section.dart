import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/notification_preferences_provider.dart';

// ---------------------------------------------------------------------------
// Section principale (entry point)
// ---------------------------------------------------------------------------

/// Section « Notifications » à injecter dans le settings screen.
/// Visible uniquement pour owner / employee — vérification faite par l'appelant.
class NotificationPreferencesSection extends ConsumerStatefulWidget {
  const NotificationPreferencesSection({super.key});

  @override
  ConsumerState<NotificationPreferencesSection> createState() =>
      _NotificationPreferencesSectionState();
}

class _NotificationPreferencesSectionState
    extends ConsumerState<NotificationPreferencesSection> {
  bool _permissionGranted = true; // optimiste par défaut

  @override
  void initState() {
    super.initState();
    // Charge les préférences et vérifie la permission en parallèle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationPreferencesProvider.notifier).load();
      _checkPermission();
    });
  }

  Future<void> _checkPermission() async {
    // Web: permission_handler doesn't apply — browsers have their own
    // Notification API flow and showing a "notifications disabled" banner
    // here would be a false positive on every desktop session. Treat as
    // granted so the banner is hidden and skip the plugin call entirely.
    if (kIsWeb) return;

    final status = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _permissionGranted =
            status.isGranted || status.isProvisional;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationPreferencesProvider);

    // Réagit aux erreurs de toggle (après le build initial).
    ref.listen<NotificationPreferencesState>(
      notificationPreferencesProvider,
      (previous, next) {
        if (next.error != null &&
            previous?.error != next.error &&
            mounted) {
          context.showErrorSnackBar(next.error);
        }
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bannière permission refusée
        if (!_permissionGranted)
          _PermissionBanner(onOpenSettings: () async {
            await openAppSettings();
            if (mounted) _checkPermission();
          }),

        if (!_permissionGranted) const SizedBox(height: AppSpacing.sm),

        // Carte éditoriale principale
        _NotificationCard(
          isLoading: state.isLoading && state.preferences == null,
          preferences: state.preferences,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Carte éditoriale
// ---------------------------------------------------------------------------

class _NotificationCard extends ConsumerWidget {
  final bool isLoading;
  final dynamic preferences; // NotificationPreferences?

  const _NotificationCard({
    required this.isLoading,
    required this.preferences,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          // En-tête éditorial — titre Fraunces seul, pas de kicker
          // (l'overline "NOTIFICATIONS" dupliquait le titre juste en dessous).
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md + 2,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.l10n.notifications,
                    style: GoogleFonts.fraunces(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm,
            ),
            child: Text(
              context.l10n.notificationsSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                    fontSize: 12,
                  ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Items
          if (isLoading)
            _NotificationItemSkeleton()
          else if (preferences != null) ...[
            _NotificationToggleItem(
              icon: Icons.event_available_rounded,
              label: context.l10n.notifNewBookingLabel,
              description: context.l10n.notifNewBookingDesc,
              value: preferences!.notifyNewBooking as bool,
              onChanged: (v) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .setNewBooking(v),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Divider(height: 1, color: AppColors.divider),
            ),
            _NotificationToggleItem(
              icon: Icons.access_time_rounded,
              label: context.l10n.notifQuietDayLabel,
              description: context.l10n.notifQuietDayDesc,
              value: preferences!.notifyQuietDayReminder as bool,
              onChanged: (v) => ref
                  .read(notificationPreferencesProvider.notifier)
                  .setQuietDayReminder(v),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toggle item éditorial
// ---------------------------------------------------------------------------

class _NotificationToggleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggleItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icône container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (value ? AppColors.primary : AppColors.textHint)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    icon,
                    key: ValueKey(value),
                    size: 18,
                    color: value ? AppColors.primary : AppColors.textHint,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.fraunces(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                            fontSize: 12,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Switch custom bordeaux
              _EditorialSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Switch custom — bordeaux animé
// ---------------------------------------------------------------------------

class _EditorialSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _EditorialSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value
              ? AppColors.primary
              : AppColors.border,
          // Ombre subtile quand activé
          boxShadow: value
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loading — shimmer pendant le premier fetch
// ---------------------------------------------------------------------------

class _NotificationItemSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.ivoryAlt,
      highlightColor: AppColors.background,
      child: Column(
        children: [
          _SkeletonRow(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Divider(height: 1),
          ),
          _SkeletonRow(),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 11,
                  width: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 44,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bannière permission refusée
// ---------------------------------------------------------------------------

class _PermissionBanner extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const _PermissionBanner({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        // Bordeaux très atténué — cohérent avec la charte éditoriale
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.notifPermissionBannerTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.notifPermissionBannerBody,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: onOpenSettings,
                  child: Text(
                    context.l10n.openSettings,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
