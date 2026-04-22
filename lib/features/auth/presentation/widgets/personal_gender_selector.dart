import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';

/// Optional 2-way picker for the user's personal gender. Tapping the
/// active choice clears the selection (maps to null → "prefer not to say").
/// Values emitted: 'men' | 'women' | null.
class PersonalGenderSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const PersonalGenderSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.genderSelectorLabel,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _Choice(
                selected: value == 'men',
                label: context.l10n.personalGenderMen,
                icon: Icons.male_rounded,
                onTap: () => onChanged(value == 'men' ? null : 'men'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _Choice(
                selected: value == 'women',
                label: context.l10n.personalGenderWomen,
                icon: Icons.female_rounded,
                onTap: () => onChanged(value == 'women' ? null : 'women'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(Icons.info_outline, size: 12, color: AppColors.textHint),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                context.l10n.genderSelectorHint,
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _Choice({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary : AppColors.background;
    final fg = selected ? AppColors.surface : AppColors.textPrimary;
    final borderColor = selected ? AppColors.primary : AppColors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.instrumentSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
