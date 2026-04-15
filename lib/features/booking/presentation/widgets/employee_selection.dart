import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/booking_provider.dart';

class EmployeeSelection extends ConsumerWidget {
  const EmployeeSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingProvider);
    final notifier = ref.read(bookingProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Coiffeur(se)',
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Horizontal scrollable list of compact employee chips
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: state.employees.length + 1, // +1 for "Sans préférence"
            itemBuilder: (context, index) {
              if (index == 0) {
                return _CompactEmployeeChip(
                  label: 'Sans préf.',
                  isSelected: state.noPreference,
                  icon: Icons.shuffle_rounded,
                  onTap: notifier.selectNoPreference,
                );
              }
              final emp = state.employees[index - 1];
              final isSelected = state.selectedEmployee?.id == emp.id;
              return _CompactEmployeeChip(
                label: emp.name.split(' ').first,
                isSelected: isSelected,
                photoUrl: emp.photoUrl,
                employeeName: emp.name,
                onTap: () => notifier.selectEmployee(emp),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CompactEmployeeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData? icon;
  final String? photoUrl;
  final String? employeeName;
  final VoidCallback onTap;

  const _CompactEmployeeChip({
    required this.label,
    required this.isSelected,
    this.icon,
    this.photoUrl,
    this.employeeName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: 16,
                ),
              )
            else
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl!) : null,
                child: photoUrl == null
                    ? Text(
                        employeeName?.isNotEmpty == true
                            ? employeeName![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.buttonSmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
