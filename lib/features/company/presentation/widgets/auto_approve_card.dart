import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../providers/company_dashboard_provider.dart';

/// Auto-approve indicator for the salon dashboard.
///
/// • capacity_based : a real toggle the owner can flip — auto-confirm or
///   send every booking to the pending queue first.
/// • employee_based : informational only — appointments are always
///   auto-confirmed when an employee + slot are picked, the owner has no
///   pending queue to validate. The card renders in a read-only style with
///   a fixed "active" state and a helper line explaining why it can't be
///   changed.
///
/// Renders nothing when the company isn't loaded so callers can plant it
/// unconditionally in both mobile and desktop dashboards.
class AutoApproveCard extends ConsumerWidget {
  const AutoApproveCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companyDashboardProvider);
    final company = state.company;
    if (company == null) {
      return const SizedBox.shrink();
    }

    final isCapacity = company.bookingMode == 'capacity_based';

    // Employee-based : read-only "always on" surface — pas de toggle
    // pour rester cohérent avec la logique backend (création toujours en
    // status=confirmed). On affiche quand même la carte pour que le owner
    // sache que ses RDV passent en automatique.
    if (!isCapacity) {
      return AppCard.toggle(
        icon: Icons.check_circle_outline_rounded,
        title: context.l10n.autoApprovalToggleLabel,
        subtitle: context.l10n.autoApprovalEmployeeReadOnly,
        value: true,
        onChanged: null, // disabled — read-only in employee mode
      );
    }

    return AppCard.toggle(
      icon: Icons.check_circle_outline_rounded,
      title: context.l10n.autoApprovalToggleLabel,
      subtitle: context.l10n.autoApprovalToggleHelper,
      value: company.capacityAutoApprove,
      onChanged: state.isLoading
          ? null
          : (value) => _confirmAndToggle(context, ref, value),
    );
  }

  /// Two-step confirm — a toggle as impactful as "auto-approve every booking"
  /// shouldn't be a one-tap flip. Confirming in both directions keeps the
  /// owner aware of what they're switching to.
  Future<void> _confirmAndToggle(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        backgroundColor: AppColors.surface,
        title: Text(
          value
              ? l.autoApprovalConfirmEnableTitle
              : l.autoApprovalConfirmDisableTitle,
          style: AppTextStyles.h3,
        ),
        content: Text(
          value
              ? l.autoApprovalConfirmEnableMessage
              : l.autoApprovalConfirmDisableMessage,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l.cancel,
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Text(l.autoApprovalConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(companyDashboardProvider.notifier)
        .toggleAutoApprove(enabled: value);
  }
}
