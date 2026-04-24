import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/models/notification_preference_model.dart';
import '../providers/granular_notification_preferences_provider.dart';

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

/// Section notifications granulaire (channel × type) pour l'écran Settings.
/// Affiche les toggles organisés par catégorie : RDV, Communauté, Marketing.
class GranularNotificationPreferencesSection extends ConsumerStatefulWidget {
  const GranularNotificationPreferencesSection({super.key});

  @override
  ConsumerState<GranularNotificationPreferencesSection> createState() =>
      _GranularNotificationPreferencesSectionState();
}

class _GranularNotificationPreferencesSectionState
    extends ConsumerState<GranularNotificationPreferencesSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(granularNotificationPreferencesProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(granularNotificationPreferencesProvider);

    ref.listen<GranularPreferencesState>(
      granularNotificationPreferencesProvider,
      (previous, next) {
        if (next.error != null &&
            previous?.error != next.error &&
            mounted) {
          context.showErrorSnackBar(next.error);
        }
      },
    );

    if (state.isLoading && state.preferences.isEmpty) {
      return const _LoadingPlaceholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Catégorie RDV
        _NotifCategory(
          label: context.l10n.notifCategoryAppointments,
          icon: Icons.event_available_rounded,
          items: _buildItems(context, state, NotificationTypes.appointmentTypes),
        ),

        const SizedBox(height: AppSpacing.md),

        // Catégorie Communauté
        _NotifCategory(
          label: context.l10n.notifCategoryCommunity,
          icon: Icons.people_outline_rounded,
          items: _buildItems(context, state, NotificationTypes.communityTypes),
        ),

        const SizedBox(height: AppSpacing.md),

        // Catégorie Marketing
        _NotifCategory(
          label: context.l10n.notifCategoryMarketing,
          icon: Icons.campaign_outlined,
          items: _buildItems(context, state, NotificationTypes.marketingTypes),
        ),
      ],
    );
  }

  List<_ToggleItem> _buildItems(
    BuildContext context,
    GranularPreferencesState state,
    List<String> types,
  ) {
    return types.map((type) {
      final label = _labelFor(context, type);
      final desc  = _descFor(context, type);
      final enabled = state.isEnabled('push', type);

      return _ToggleItem(
        label: label,
        description: desc,
        enabled: enabled,
        onChanged: (v) => ref
            .read(granularNotificationPreferencesProvider.notifier)
            .toggle('push', type, v),
      );
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// Catégorie
// ---------------------------------------------------------------------------

class _NotifCategory extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<_ToggleItem> items;

  const _NotifCategory({
    required this.label,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
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
          // En-tête catégorie
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: GoogleFonts.fraunces(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Toggles
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Divider(height: 1, color: AppColors.divider),
              ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toggle item avec label + description + switch bordeaux
// ---------------------------------------------------------------------------

class _ToggleItem extends StatelessWidget {
  final String label;
  final String description;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.label,
    required this.description,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!enabled),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.fraunces(
                        fontSize: 15,
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
              const SizedBox(width: AppSpacing.md),
              _EditorialSwitch(value: enabled, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Switch bordeaux animé (identique au widget existant)
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
          color: value ? AppColors.primary : AppColors.border,
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
// Skeleton loading
// ---------------------------------------------------------------------------

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < 3; i++) ...[
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.ivoryAlt,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
          ),
          if (i < 2) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers i18n (label + description par type)
// ---------------------------------------------------------------------------

String _labelFor(BuildContext context, String type) {
  final l10n = context.l10n;
  return switch (type) {
    NotificationTypes.reminderEvening   => l10n.notifTypeReminderEveningLabel,
    NotificationTypes.reminder2h        => l10n.notifTypeReminder2hLabel,
    NotificationTypes.reviewRequest     => l10n.notifTypeReviewRequestLabel,
    NotificationTypes.newReview         => l10n.notifTypeNewReviewLabel,
    NotificationTypes.capacityFull      => l10n.notifTypeCapacityFullLabel,
    NotificationTypes.weeklyDigest      => l10n.notifTypeWeeklyDigestLabel,
    NotificationTypes.monthlyReport     => l10n.notifTypeMonthlyReportLabel,
    NotificationTypes.favoriteNewPhotos => l10n.notifTypeFavoriteNewPhotosLabel,
    NotificationTypes.favoriteNewSlots  => l10n.notifTypeFavoriteNewSlotsLabel,
    NotificationTypes.marketing         => l10n.notifTypeMarketingLabel,
    _                                   => type,
  };
}

String _descFor(BuildContext context, String type) {
  final l10n = context.l10n;
  return switch (type) {
    NotificationTypes.reminderEvening   => l10n.notifTypeReminderEveningDesc,
    NotificationTypes.reminder2h        => l10n.notifTypeReminder2hDesc,
    NotificationTypes.reviewRequest     => l10n.notifTypeReviewRequestDesc,
    NotificationTypes.newReview         => l10n.notifTypeNewReviewDesc,
    NotificationTypes.capacityFull      => l10n.notifTypeCapacityFullDesc,
    NotificationTypes.weeklyDigest      => l10n.notifTypeWeeklyDigestDesc,
    NotificationTypes.monthlyReport     => l10n.notifTypeMonthlyReportDesc,
    NotificationTypes.favoriteNewPhotos => l10n.notifTypeFavoriteNewPhotosDesc,
    NotificationTypes.favoriteNewSlots  => l10n.notifTypeFavoriteNewSlotsDesc,
    NotificationTypes.marketing         => l10n.notifTypeMarketingDesc,
    _                                   => '',
  };
}
