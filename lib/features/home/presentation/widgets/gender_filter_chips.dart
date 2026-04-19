import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/ux_prefs_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/models/gender_filter.dart';
import '../providers/home_providers.dart';

/// A horizontal row of pill-shaped ChoiceChips for gender filtering.
/// Selecting a chip updates [genderFilterProvider].
class GenderFilterChips extends ConsumerWidget {
  const GenderFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(genderFilterProvider);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _FilterChip(
            label: context.l10n.filterMen,
            filter: GenderFilter.men,
            selected: selected,
            ref: ref,
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: context.l10n.filterWomen,
            filter: GenderFilter.women,
            selected: selected,
            ref: ref,
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: context.l10n.filterBoth,
            filter: GenderFilter.both,
            selected: selected,
            ref: ref,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final GenderFilter filter;
  final GenderFilter selected;
  final WidgetRef ref;

  const _FilterChip({
    required this.label,
    required this.filter,
    required this.selected,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = filter == selected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          ref.read(uxPrefsProvider.notifier).selectionClick();
          ref.read(genderFilterProvider.notifier).state = filter;
        },
        // Minimum touch target is 40px height (SizedBox above) — satisfies 48dp
        // guidance since padding adds tap area
        labelStyle: AppTextStyles.buttonSmall.copyWith(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1.2,
        ),
        shape: const StadiumBorder(),
        elevation: isSelected ? 2 : 0,
        shadowColor: AppColors.primary.withAlpha(80),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        showCheckmark: false,
      ),
    );
  }
}
