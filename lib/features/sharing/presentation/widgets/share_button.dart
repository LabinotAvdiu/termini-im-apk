import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'share_salon_sheet.dart';

/// Mobile-sized share entry point. Circular ivory pill matching the
/// `_HeartButton` pattern used on the salon detail hero. Tap opens the
/// [showShareSalonSheet] bottom sheet.
///
/// [employeeIds] is the set of user ids that are employees of this salon —
/// used to decide whether the "Me recommander" toggle appears.
class ShareIconButton extends ConsumerWidget {
  final String companyId;
  final String salonName;
  final String bookingMode;
  final Set<String> employeeIds;

  /// Show a subtle gold dot on the icon — one-time "new feature" marker.
  /// Defaults to true until we add per-user dismiss state.
  final bool showFreshBadge;

  const ShareIconButton({
    super.key,
    required this.companyId,
    required this.salonName,
    required this.bookingMode,
    required this.employeeIds,
    this.showFreshBadge = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
    final isEmployee = userId != null && employeeIds.contains(userId);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: AppColors.background.withValues(alpha: 0.90),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => showShareSalonSheet(
                context,
                companyId: companyId,
                salonName: salonName,
                bookingMode: bookingMode,
                isCurrentUserEmployee: isEmployee,
              ),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.ios_share_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ),
          ),
          if (showFreshBadge)
            Positioned(
              top: 4,
              right: 5,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.background.withValues(alpha: 0.90),
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Desktop-sized share entry point. OutlinedButton matching the desktop
/// favorite button shell. Tap opens [showShareSalonSheet] which picks the
/// dialog presentation automatically at >= 840px width.
class ShareOutlinedButton extends ConsumerWidget {
  final String companyId;
  final String salonName;
  final String bookingMode;
  final Set<String> employeeIds;
  final bool showFreshBadge;

  const ShareOutlinedButton({
    super.key,
    required this.companyId,
    required this.salonName,
    required this.bookingMode,
    required this.employeeIds,
    this.showFreshBadge = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
    final isEmployee = userId != null && employeeIds.contains(userId);

    final button = OutlinedButton.icon(
      onPressed: () => showShareSalonSheet(
        context,
        companyId: companyId,
        salonName: salonName,
        bookingMode: bookingMode,
        isCurrentUserEmployee: isEmployee,
      ),
      icon: const Icon(
        Icons.ios_share_rounded,
        size: 18,
        color: AppColors.primary,
      ),
      label: const SizedBox.shrink(),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.50),
          width: 1.2,
        ),
        backgroundColor: AppColors.primary.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        minimumSize: const Size(44, 44),
      ),
    );

    if (!showFreshBadge) return button;

    // Gold dot overlay — "fresh feature" signal, one-time-ish (persist dismiss
    // later). Positioned so it doesn't crop on the rounded-rect corner.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tiny convenience — used only for the tooltip on hover-capable devices.
/// Kept separate so the Row on mobile doesn't need the tooltip wrapper.
extension ShareButtonTooltip on BuildContext {
  String get shareButtonTooltip => l10n.shareSalon;
}
