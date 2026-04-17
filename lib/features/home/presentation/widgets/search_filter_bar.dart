import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/models/gender_filter.dart';
import '../providers/home_providers.dart';

class SearchFilterBar extends ConsumerStatefulWidget {
  const SearchFilterBar({super.key});

  @override
  ConsumerState<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends ConsumerState<SearchFilterBar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _animController;
  late final Animation<double> _expandAnimation;

  // Controllers for expanded fields
  late final TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _cityController = TextEditingController();
  }

  @override
  void dispose() {
    _animController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  void _search() {
    // Apply filters and close
    if (_isExpanded) _toggle();
  }

  String _genderLabel(BuildContext context, GenderFilter filter) {
    return switch (filter) {
      GenderFilter.men => context.l10n.filterMen,
      GenderFilter.women => context.l10n.filterWomen,
      GenderFilter.both => context.l10n.filterBoth,
    };
  }

  String _dateLabel(BuildContext context, DateTime? date) {
    if (date == null) return context.l10n.filterDateLabel;
    return '${_shortDay(context, date.weekday)} ${date.day}/${date.month}';
  }

  static String _shortDay(BuildContext context, int weekday) {
    final l = context.l10n;
    return switch (weekday) {
      DateTime.monday => l.dayShortMon,
      DateTime.tuesday => l.dayShortTue,
      DateTime.wednesday => l.dayShortWed,
      DateTime.thursday => l.dayShortThu,
      DateTime.friday => l.dayShortFri,
      DateTime.saturday => l.dayShortSat,
      _ => l.dayShortSun,
    };
  }

  static String _shortMonth(BuildContext context, int month) {
    final l = context.l10n;
    return switch (month) {
      1 => l.monthShortJan,
      2 => l.monthShortFeb,
      3 => l.monthShortMar,
      4 => l.monthShortApr,
      5 => l.monthShortMay,
      6 => l.monthShortJun,
      7 => l.monthShortJul,
      8 => l.monthShortAug,
      9 => l.monthShortSep,
      10 => l.monthShortOct,
      11 => l.monthShortNov,
      _ => l.monthShortDec,
    };
  }

  @override
  Widget build(BuildContext context) {
    final gender = ref.watch(genderFilterProvider);
    final city = ref.watch(cityFilterProvider);
    final date = ref.watch(dateFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(
            _isExpanded ? AppSpacing.radiusLg : AppSpacing.radiusXl,
          ),
          boxShadow: [
            BoxShadow(
              color: _isExpanded
                  ? AppColors.cardShadow.withValues(alpha: 0.15)
                  : AppColors.cardShadow,
              blurRadius: _isExpanded ? 20 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact bar (always visible)
            _CompactBar(
              genderLabel: _genderLabel(context, gender),
              cityLabel: city.isEmpty ? context.l10n.filterCityLabel : city,
              dateLabel: _dateLabel(context, date),
              isExpanded: _isExpanded,
              onTap: _toggle,
              onSearch: _search,
            ),

            // Expanded content
            SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1,
              child: _ExpandedContent(
                gender: gender,
                cityController: _cityController,
                selectedDate: date,
                genderLabel: context.l10n.filterGenderLabel,
                menLabel: context.l10n.filterMen,
                womenLabel: context.l10n.filterWomen,
                bothLabel: context.l10n.filterBoth,
                citySalonLabel: context.l10n.filterCitySalonLabel,
                cityHint: context.l10n.filterCityHint,
                dateWhenLabel: context.l10n.filterDateWhen,
                clearLabel: context.l10n.filterClear,
                searchLabel: context.l10n.filterSearch,
                onGenderChanged: (g) {
                  ref.read(genderFilterProvider.notifier).state = g;
                },
                onCityChanged: (c) {
                  ref.read(cityFilterProvider.notifier).state = c;
                },
                onDateChanged: (d) {
                  ref.read(dateFilterProvider.notifier).state = d;
                },
                onSearch: _search,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact bar — 3 sections + search button
// ---------------------------------------------------------------------------

class _CompactBar extends StatelessWidget {
  final String genderLabel;
  final String cityLabel;
  final String dateLabel;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onSearch;

  const _CompactBar({
    required this.genderLabel,
    required this.cityLabel,
    required this.dateLabel,
    required this.isExpanded,
    required this.onTap,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            // Genre field
            Expanded(
              child: _FieldCell(
                text: genderLabel,
                showBorder: true,
              ),
            ),
            // City field
            Expanded(
              child: _FieldCell(
                text: cityLabel,
                showBorder: true,
              ),
            ),
            // Date field
            Expanded(
              child: _FieldCell(
                text: dateLabel,
                showBorder: false,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Search button
            GestureDetector(
              onTap: onSearch,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.textPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldCell extends StatelessWidget {
  final String text;
  final bool showBorder;

  const _FieldCell({
    required this.text,
    required this.showBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: showBorder
          ? const BoxDecoration(
              border: Border(
                right: BorderSide(color: AppColors.divider, width: 1),
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: Text(
          text,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expanded content — editable fields + calendar
// ---------------------------------------------------------------------------

class _ExpandedContent extends StatelessWidget {
  final GenderFilter gender;
  final TextEditingController cityController;
  final DateTime? selectedDate;
  final String genderLabel;
  final String menLabel;
  final String womenLabel;
  final String bothLabel;
  final String citySalonLabel;
  final String cityHint;
  final String dateWhenLabel;
  final String clearLabel;
  final String searchLabel;
  final ValueChanged<GenderFilter> onGenderChanged;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<DateTime?> onDateChanged;
  final VoidCallback onSearch;

  const _ExpandedContent({
    required this.gender,
    required this.cityController,
    required this.selectedDate,
    required this.genderLabel,
    required this.menLabel,
    required this.womenLabel,
    required this.bothLabel,
    required this.citySalonLabel,
    required this.cityHint,
    required this.dateWhenLabel,
    required this.clearLabel,
    required this.searchLabel,
    required this.onGenderChanged,
    required this.onCityChanged,
    required this.onDateChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.divider),
          const SizedBox(height: AppSpacing.sm),

          // Gender selection
          _SectionLabel(label: genderLabel, icon: Icons.person_outline),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _GenderOption(
                label: menLabel,
                filter: GenderFilter.men,
                selected: gender,
                onTap: () => onGenderChanged(GenderFilter.men),
              ),
              const SizedBox(width: AppSpacing.sm),
              _GenderOption(
                label: womenLabel,
                filter: GenderFilter.women,
                selected: gender,
                onTap: () => onGenderChanged(GenderFilter.women),
              ),
              const SizedBox(width: AppSpacing.sm),
              _GenderOption(
                label: bothLabel,
                filter: GenderFilter.both,
                selected: gender,
                onTap: () => onGenderChanged(GenderFilter.both),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // City / Company name
          _SectionLabel(label: citySalonLabel, icon: Icons.location_on_outlined),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: cityController,
            onChanged: onCityChanged,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: cityHint,
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Date
          _SectionLabel(label: dateWhenLabel, icon: Icons.calendar_today_rounded),
          const SizedBox(height: AppSpacing.sm),
          _DateSelector(
            selectedDate: selectedDate,
            onDateChanged: onDateChanged,
            clearLabel: clearLabel,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Search button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_rounded, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(searchLabel, style: AppTextStyles.button),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Gender option pill
// ---------------------------------------------------------------------------

class _GenderOption extends StatelessWidget {
  final String label;
  final GenderFilter filter;
  final GenderFilter selected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = filter == selected;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.background,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.buttonSmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date selector with quick picks + calendar
// ---------------------------------------------------------------------------

class _DateSelector extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateChanged;
  final String clearLabel;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
    required this.clearLabel,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: [
        // Selected date display + clear button
        if (selectedDate != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                const Icon(
                  Icons.event_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(context, selectedDate!),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => onDateChanged(null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      clearLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Inline calendar — force English Material locale so day letters are
        // uppercase (M T W T F S S) and month names start with a capital.
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          clipBehavior: Clip.antiAlias,
          child: Localizations.override(
            context: context,
            locale: const Locale('en'),
            child: CalendarDatePicker(
              initialDate: selectedDate ?? today,
              firstDate: today,
              lastDate: today.add(const Duration(days: 90)),
              onDateChanged: onDateChanged,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(BuildContext context, DateTime dt) {
    final day = _SearchFilterBarState._shortDay(context, dt.weekday);
    final month = _SearchFilterBarState._shortMonth(context, dt.month);
    return '$day ${dt.day} $month ${dt.year}';
  }
}
