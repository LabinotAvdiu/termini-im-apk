import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  const StepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    this.labels = const ['Employé', 'Horaire', 'Confirmation'],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          // Even indices are step circles, odd indices are connector lines
          if (index.isOdd) {
            final stepIndex = index ~/ 2;
            final isPast = stepIndex < currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                decoration: BoxDecoration(
                  color: isPast ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final isCurrent = stepIndex == currentStep;

          return _StepCircle(
            stepNumber: stepIndex + 1,
            label: labels[stepIndex],
            isCompleted: isCompleted,
            isCurrent: isCurrent,
          );
        }),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int stepNumber;
  final String label;
  final bool isCompleted;
  final bool isCurrent;

  const _StepCircle({
    required this.stepNumber,
    required this.label,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    final Widget inner;

    if (isCompleted) {
      bgColor = AppColors.primary;
      borderColor = AppColors.primary;
      inner = const Icon(Icons.check_rounded, color: Colors.white, size: 16);
    } else if (isCurrent) {
      bgColor = AppColors.primary;
      borderColor = AppColors.primary;
      inner = Text(
        '$stepNumber',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
    } else {
      bgColor = AppColors.surface;
      borderColor = AppColors.border;
      inner = Text(
        '$stepNumber',
        style: TextStyle(
          color: AppColors.textHint,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isCurrent || isCompleted
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(child: inner),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isCurrent || isCompleted
                ? AppColors.primary
                : AppColors.textHint,
            fontWeight:
                isCurrent ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
