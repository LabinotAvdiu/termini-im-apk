import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/models/my_company_model.dart';
import '../providers/company_dashboard_provider.dart';
import '../providers/company_planning_provider.dart';
import 'company_planning_screen_desktop.dart';
import 'company_planning_screen_mobile.dart';

// ---------------------------------------------------------------------------
// Wrapper — owns initState, _pickDate, _showWalkInDialog, date navigation
// ---------------------------------------------------------------------------

class CompanyPlanningScreen extends ConsumerStatefulWidget {
  const CompanyPlanningScreen({super.key});

  @override
  ConsumerState<CompanyPlanningScreen> createState() =>
      _CompanyPlanningScreenState();
}

class _CompanyPlanningScreenState
    extends ConsumerState<CompanyPlanningScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(companyPlanningProvider.notifier).load();
      // Pull in the company (opening hours + bookingMode) — employees
      // don't visit the owner dashboard so the dashboard provider would
      // stay empty otherwise. loadCompanyOnly is idempotent for owners.
      ref.read(companyDashboardProvider.notifier).loadCompanyOnly();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(companyPlanningProvider.notifier).load();
      });
    }
  }

  Future<void> showWalkInDialog(
    BuildContext context,
    String slotTime,
    List<MyServiceModel> services,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => PlanningWalkInDialog(
        slotTime: slotTime,
        date: ref.read(companyPlanningProvider).selectedDate,
        services: services,
      ),
    );
  }

  Future<void> pickDate(BuildContext context) async {
    final state = ref.read(companyPlanningProvider);
    final current = DateTime.tryParse(state.selectedDate) ?? DateTime.now();

    // Month view → month-only picker (no days).
    if (state.viewMode == CompanyPlanningViewMode.month) {
      final picked = await showDialog<DateTime>(
        context: context,
        builder: (_) => _MonthYearPickerDialog(initial: current),
      );
      if (picked != null) {
        ref.read(companyPlanningProvider.notifier).setDate(picked);
      }
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: const Color(0xFF7A2232),
              ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      ref.read(companyPlanningProvider.notifier).setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: CompanyPlanningScreenMobile(
        onShowWalkInDialog: (slotTime, services) =>
            showWalkInDialog(context, slotTime, services),
        onPickDate: () => pickDate(context),
      ),
      desktop: CompanyPlanningScreenDesktop(
        onShowWalkInDialog: (slotTime, services) =>
            showWalkInDialog(context, slotTime, services),
        onPickDate: () => pickDate(context),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Month + year picker dialog (used in month view)
// ---------------------------------------------------------------------------

class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initial;
  const _MonthYearPickerDialog({required this.initial});

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final months = [
      l.monthJan, l.monthFeb, l.monthMar, l.monthApr,
      l.monthMay, l.monthJun, l.monthJul, l.monthAug,
      l.monthSep, l.monthOct, l.monthNov, l.monthDec,
    ];
    final now = DateTime.now();

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.selectMonth.toUpperCase(),
              style: AppTextStyles.overline.copyWith(
                color: AppColors.textHint,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            // Year nav
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: AppColors.textPrimary,
                  iconSize: 22,
                  onPressed: () => setState(() => _year--),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$_year',
                      style: GoogleFonts.fraunces(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: AppColors.textPrimary,
                  iconSize: 22,
                  onPressed: () => setState(() => _year++),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // 3×4 month grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (_, i) {
                final isSelected =
                    widget.initial.year == _year && widget.initial.month == i + 1;
                final isCurrent = now.year == _year && now.month == i + 1;

                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context)
                        .pop(DateTime(_year, i + 1, 1)),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.textPrimary
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.secondary
                              : isCurrent
                                  ? AppColors.primary
                                  : AppColors.border.withValues(alpha: 0.5),
                          width: isSelected
                              ? 2
                              : isCurrent
                                  ? 1.5
                                  : 1,
                        ),
                      ),
                      child: Text(
                        months[i],
                        style: GoogleFonts.instrumentSans(
                          fontSize: 13,
                          fontWeight: isSelected || isCurrent
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.background
                              : isCurrent
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l.cancel,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
