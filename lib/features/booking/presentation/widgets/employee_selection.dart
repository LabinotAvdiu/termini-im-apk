import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/ux_prefs_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../profile/presentation/widgets/avatar_editor.dart';
import '../providers/booking_provider.dart';

class EmployeeSelection extends ConsumerWidget {
  const EmployeeSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingProvider);
    final notifier = ref.read(bookingProvider.notifier);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    // 64dp mobile / 80dp desktop as specified.
    final avatarSize = isDesktop ? 80.0 : 64.0;

    // Capacity-based salon with a single (owner-only) team — no real employee
    // choice, skip the whole selector. The booking_provider already forces
    // `noPreference=true` in this case so the booking still resolves cleanly.
    if (state.hideEmployeePicker) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.hairdresser,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Horizontal scrollable list with photo cards
        SizedBox(
          // Card height: avatar + name label + padding
          height: avatarSize + 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: state.employees.length + 1, // +1 for "Sans préférence"
            itemBuilder: (context, index) {
              if (index == 0) {
                return _EmployeePhotoCard(
                  label: context.l10n.noPreferenceShort,
                  isSelected: state.noPreference,
                  icon: Icons.shuffle_rounded,
                  avatarSize: avatarSize,
                  onTap: () {
                    ref.read(uxPrefsProvider.notifier).selectionClick();
                    notifier.selectNoPreference();
                  },
                );
              }
              final emp = state.employees[index - 1];
              final isSelected = state.selectedEmployee?.id == emp.id;
              final initials = emp.name
                  .split(' ')
                  .where((w) => w.isNotEmpty)
                  .take(2)
                  .map((w) => w[0].toUpperCase())
                  .join();
              return _EmployeePhotoCard(
                label: emp.name.split(' ').first,
                isSelected: isSelected,
                photoUrl: emp.photoUrl,
                initials: initials,
                avatarSize: avatarSize,
                onTap: () {
                  ref.read(uxPrefsProvider.notifier).selectionClick();
                  notifier.selectEmployee(emp);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Photo card for the employee selector.
///
/// Displays a circular avatar (real photo or initials) with the first name
/// below. A gold ring appears when [isSelected]. This transforms the selector
/// from a plain chip list into a human-facing face gallery.
class _EmployeePhotoCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData? icon;
  final String? photoUrl;
  final String initials;
  final double avatarSize;
  final VoidCallback onTap;

  const _EmployeePhotoCard({
    required this.label,
    required this.isSelected,
    this.icon,
    this.photoUrl,
    this.initials = '',
    required this.avatarSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Avatar circle ──────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isSelected ? 2.5 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.secondary : Colors.transparent,
                  width: isSelected ? 2 : 0,
                ),
              ),
              child: icon != null
                  // "No preference" tile: icon on coloured background
                  ? Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.10),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : AppColors.primary,
                        size: avatarSize * 0.38,
                      ),
                    )
                  // Real employee: photo or initials
                  : AvatarDisplay(
                      photoUrl: photoUrl,
                      initials: initials,
                      size: avatarSize,
                      selected: isSelected,
                    ),
            ),
            const SizedBox(height: 6),
            // ── Name label ─────────────────────────────────────────────
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
