import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/models/my_company_model.dart';
import '../../data/models/planning_appointment_model.dart';
import '../providers/company_dashboard_provider.dart';
import '../providers/company_planning_provider.dart';
import '../widgets/cancellation_reason_box.dart';
import 'company_planning_screen_mobile.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';

// ---------------------------------------------------------------------------
// Callback typedefs
// ---------------------------------------------------------------------------

typedef _OnShowWalkInDialog = Future<void> Function(
    String slotTime, List<MyServiceModel> services);

// ---------------------------------------------------------------------------
// Desktop presentation (D3)
// ---------------------------------------------------------------------------

/// Full-screen three-zone desktop layout.
///
/// Left column (~240 px): dark ink sidebar with brand + nav.
/// Centre (flexible ~70%): date header row, view-mode pills, timeline grid.
/// Right panel (~320 px): pending approvals list + today summary.
class CompanyPlanningScreenDesktop extends ConsumerWidget {
  final _OnShowWalkInDialog onShowWalkInDialog;
  final VoidCallback onPickDate;

  const CompanyPlanningScreenDesktop({
    super.key,
    required this.onShowWalkInDialog,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companyPlanningProvider);

    // Sidebar is now provided by the shell (MainShell) on desktop.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _DesktopMainArea(
              state: state,
              onShowWalkInDialog: onShowWalkInDialog,
              onPickDate: onPickDate,
            ),
          ),
          _DesktopApprovalsPanel(state: state),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main timeline area (centre column)
// ---------------------------------------------------------------------------

class _DesktopMainArea extends ConsumerWidget {
  final CompanyPlanningState state;
  final _OnShowWalkInDialog onShowWalkInDialog;
  final VoidCallback onPickDate;

  const _DesktopMainArea({
    required this.state,
    required this.onShowWalkInDialog,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top bar ─────────────────────────────────────────────────────
        _DesktopPlanningTopBar(
          state: state,
          onPickDate: onPickDate,
        ),

        const Divider(height: 1, color: AppColors.divider),

        // ── Timeline content ─────────────────────────────────────────────
        Expanded(
          child: _DesktopTimelineContent(
            state: state,
            onShowWalkInDialog: onShowWalkInDialog,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar: date navigation + view-mode pills
// ---------------------------------------------------------------------------

class _DesktopPlanningTopBar extends ConsumerWidget {
  final CompanyPlanningState state;
  final VoidCallback onPickDate;

  const _DesktopPlanningTopBar({
    required this.state,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateTime.tryParse(state.selectedDate) ?? DateTime.now();
    final isToday = planningIsSameDay(date, DateTime.now());
    final l = context.l10n;

    final months = [
      l.monthShortJan, l.monthShortFeb, l.monthShortMar, l.monthShortApr,
      l.monthShortMay, l.monthShortJun, l.monthShortJul, l.monthShortAug,
      l.monthShortSep, l.monthShortOct, l.monthShortNov, l.monthShortDec,
    ];
    final dayNames = [
      l.monday, l.tuesday, l.wednesday, l.thursday,
      l.friday, l.saturday, l.sunday,
    ];

    String formattedDate;
    switch (state.viewMode) {
      case CompanyPlanningViewMode.day:
        formattedDate =
            '${dayNames[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';
      case CompanyPlanningViewMode.week:
        final weekStart = planningWeekStart(date);
        final weekEnd = weekStart.add(const Duration(days: 6));
        if (weekStart.month == weekEnd.month) {
          formattedDate =
              '${weekStart.day} – ${weekEnd.day} ${months[weekStart.month - 1]} ${weekStart.year}';
        } else {
          formattedDate =
              '${weekStart.day} ${months[weekStart.month - 1]} – ${weekEnd.day} ${months[weekEnd.month - 1]} ${weekStart.year}';
        }
      case CompanyPlanningViewMode.month:
        formattedDate =
            '${months[date.month - 1].toUpperCase()} ${date.year}';
    }

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Row(
        children: [
          // Date display + navigation
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppColors.textPrimary,
                iconSize: 24,
                onPressed: () =>
                    ref.read(companyPlanningProvider.notifier).goPrevious(),
                tooltip: switch (state.viewMode) {
                  CompanyPlanningViewMode.day => l.previousDay,
                  CompanyPlanningViewMode.week => l.previousWeek,
                  CompanyPlanningViewMode.month => l.previousMonth,
                },
              ),
              GestureDetector(
                onTap: onPickDate,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(formattedDate, style: AppTextStyles.h3),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.calendar_today_rounded,
                        size: 16, color: AppColors.primary),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                color: AppColors.textPrimary,
                iconSize: 24,
                onPressed: () =>
                    ref.read(companyPlanningProvider.notifier).goNext(),
                tooltip: switch (state.viewMode) {
                  CompanyPlanningViewMode.day => l.nextDay,
                  CompanyPlanningViewMode.week => l.nextWeek,
                  CompanyPlanningViewMode.month => l.nextMonth,
                },
              ),
            ],
          ),

          if (isToday) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                l.todayLabel.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],

          const Spacer(),

          // View-mode pills
          _DesktopViewModePills(
            current: state.viewMode,
            onSelect: (mode) =>
                ref.read(companyPlanningProvider.notifier).setViewMode(mode),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// View-mode pills (desktop compact version)
// ---------------------------------------------------------------------------

class _DesktopViewModePills extends StatelessWidget {
  final CompanyPlanningViewMode current;
  final void Function(CompanyPlanningViewMode) onSelect;

  const _DesktopViewModePills({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final modes = [
      (CompanyPlanningViewMode.day, l.viewDay),
      (CompanyPlanningViewMode.week, l.viewWeek),
      (CompanyPlanningViewMode.month, l.viewMonth),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.asMap().entries.map((entry) {
          final index = entry.key;
          final (mode, label) = entry.value;
          final isActive = current == mode;
          final isLast = index == modes.length - 1;

          return GestureDetector(
            onTap: () => onSelect(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.textPrimary : Colors.transparent,
                borderRadius: BorderRadius.horizontal(
                  left: index == 0
                      ? const Radius.circular(AppSpacing.radiusMd - 1)
                      : Radius.zero,
                  right: isLast
                      ? const Radius.circular(AppSpacing.radiusMd - 1)
                      : Radius.zero,
                ),
              ),
              child: Text(
                label.toUpperCase(),
                style: GoogleFonts.instrumentSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: isActive ? AppColors.background : AppColors.textHint,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline content — ConsumerWidget to support ref access in all view modes
// ---------------------------------------------------------------------------

class _DesktopTimelineContent extends ConsumerStatefulWidget {
  final CompanyPlanningState state;
  final _OnShowWalkInDialog onShowWalkInDialog;

  const _DesktopTimelineContent({
    required this.state,
    required this.onShowWalkInDialog,
  });

  @override
  ConsumerState<_DesktopTimelineContent> createState() =>
      _DesktopTimelineContentState();
}

class _DesktopTimelineContentState
    extends ConsumerState<_DesktopTimelineContent> {
  final ScrollController _dayScrollController = ScrollController();
  String? _autoScrolledForDate;

  @override
  void dispose() {
    _dayScrollController.dispose();
    super.dispose();
  }

  void _maybeAutoScrollToNow(
      CompanyPlanningState state, OpeningHourModel hours) {
    if (state.viewMode != CompanyPlanningViewMode.day) return;
    final selected = DateTime.tryParse(state.selectedDate);
    final now = DateTime.now();
    if (selected == null) return;
    if (!planningIsSameDay(selected, now)) return;
    if (_autoScrolledForDate == state.selectedDate) return;
    if (hours.openTime == null || hours.closeTime == null) return;

    final openMin = planningTimeToMinutes(hours.openTime!);
    final closeMin = planningTimeToMinutes(hours.closeTime!);
    final currentMin = now.hour * 60 + now.minute;
    if (currentMin < openMin || currentMin > closeMin) return;

    final anchorMin = (currentMin - 15).clamp(openMin, closeMin);
    final offsetPx = (anchorMin - openMin) / 15 * kPlanningRowHeight;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_dayScrollController.hasClients) return;
      final maxExtent = _dayScrollController.position.maxScrollExtent;
      _dayScrollController.animateTo(
        offsetPx.clamp(0, maxExtent).toDouble(),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
      _autoScrolledForDate = state.selectedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    switch (state.viewMode) {
      case CompanyPlanningViewMode.week:
        return _buildWeekBody(context, state, ref);
      case CompanyPlanningViewMode.month:
        return _buildMonthBody(context, state, ref);
      case CompanyPlanningViewMode.day:
        return _buildDayBody(context, state, ref);
    }
  }

  Widget _buildDayBody(
      BuildContext context, CompanyPlanningState state, WidgetRef ref) {
    final companyState = ref.watch(companyDashboardProvider);

    if (state.isLoading && state.appointments.isEmpty) {
      return const SkeletonPlanningDay();
    }

    if (state.error != null && state.appointments.isEmpty) {
      return PlanningErrorView(
        message: state.error!,
        onRetry: () => ref.read(companyPlanningProvider.notifier).load(),
      );
    }

    final company = companyState.company;
    if (company == null) {
      return const SkeletonPlanningDay();
    }

    final selectedDate =
        DateTime.tryParse(state.selectedDate) ?? DateTime.now();
    final dayIndex = selectedDate.weekday - 1;

    final OpeningHourModel? todayHours = company.openingHours
        .where((h) => h.dayOfWeek == dayIndex)
        .cast<OpeningHourModel?>()
        .firstOrNull;

    if (todayHours == null ||
        todayHours.isClosed ||
        todayHours.openTime == null ||
        todayHours.closeTime == null) {
      return const PlanningDayOffView();
    }

    final rows = buildPlanningRows(todayHours);
    final events = buildPlanningEvents(
      hours: todayHours,
      appointments: state.appointments,
    );
    final services = company.categories.expand((c) => c.services).toList();

    final now = DateTime.now();
    final isToday = planningIsSameDay(selectedDate, now);
    final nowMinutes = isToday ? now.hour * 60 + now.minute : null;
    _maybeAutoScrollToNow(state, todayHours);

    // Per-day totals — feeds the stats header above the timeline.
    final dayConfirmed =
        state.appointments.where((a) => a.status == 'confirmed').length;
    final dayPending =
        state.appointments.where((a) => a.status == 'pending').length;
    final dayNoShow =
        state.appointments.where((a) => a.status == 'no_show').length;
    final dayCancelled =
        state.appointments.where((a) => a.status == 'cancelled').length;
    final dayRejected =
        state.appointments.where((a) => a.status == 'rejected').length;
    final dayTotal = state.appointments.length;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(companyPlanningProvider.notifier).load(),
      child: CustomScrollView(
        controller: _dayScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (state.isLoading)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.divider,
              ),
            ),
          SliverToBoxAdapter(
            child: _DayStatsHeader(
              selectedDate: selectedDate,
              total: dayTotal,
              confirmed: dayConfirmed,
              pending: dayPending,
              noShow: dayNoShow,
              cancelled: dayCancelled,
              rejected: dayRejected,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: PlanningTimelineGrid(
                rows: rows,
                events: events,
                workEnd: todayHours.closeTime!,
                services: services,
                currentTimeMinutes: nowMinutes,
                onTapFreeSlot: (time) => widget.onShowWalkInDialog(time, services),
                isTimeInPast: (time) {
                  final today = DateTime(now.year, now.month, now.day);
                  if (selectedDate.isBefore(today)) return true;
                  if (selectedDate.isAfter(today)) return false;
                  final parts = time.split(':');
                  final slotMinutes =
                      int.parse(parts[0]) * 60 + int.parse(parts[1]);
                  final nowM = now.hour * 60 + now.minute;
                  return slotMinutes <= nowM;
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  Widget _buildWeekBody(
      BuildContext context, CompanyPlanningState state, WidgetRef ref) {
    if (state.isLoading && state.rangeAppointments.isEmpty) {
      return const SkeletonPlanningDay();
    }

    final selected = DateTime.tryParse(state.selectedDate) ?? DateTime.now();
    final weekStart = planningWeekStart(selected);

    // Aggregate the 7-day window for the stats header.
    var confirmed = 0, pending = 0, noShow = 0, cancelled = 0, rejected = 0;
    for (var i = 0; i < 7; i++) {
      final iso = planningToIso(weekStart.add(Duration(days: i)));
      final list = state.rangeAppointments[iso];
      if (list == null) continue;
      for (final a in list) {
        switch (a.status) {
          case 'confirmed': confirmed++;
          case 'pending':   pending++;
          case 'no_show':   noShow++;
          case 'cancelled': cancelled++;
          case 'rejected':  rejected++;
        }
      }
    }
    final total = confirmed + pending + noShow + cancelled + rejected;

    return Column(
      children: [
        _DayStatsHeader(
          selectedDate: selected,
          total: total,
          confirmed: confirmed,
          pending: pending,
          noShow: noShow,
          cancelled: cancelled,
          rejected: rejected,
        ),
        Expanded(
          child: PlanningWeekView(
            weekStart: weekStart,
            appointmentsByDate: state.rangeAppointments,
            selectedDate: selected,
            onTapDay: (day) {
              ref
                  .read(companyPlanningProvider.notifier)
                  .setViewMode(CompanyPlanningViewMode.day);
              ref.read(companyPlanningProvider.notifier).setDate(day);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthBody(
      BuildContext context, CompanyPlanningState state, WidgetRef ref) {
    if (state.isLoading && state.rangeAppointments.isEmpty) {
      return const SkeletonPlanningDay();
    }

    final selected = DateTime.tryParse(state.selectedDate) ?? DateTime.now();

    return PlanningMonthView(
      month: DateTime(selected.year, selected.month, 1),
      appointmentsByDate: state.rangeAppointments,
      selectedDate: selected,
      // Desktop: wider aspect ratio so the 6-week grid fits without scrolling.
      childAspectRatio: 1.4,
      compact: true,
      onTapDay: (day) {
        final iso = planningToIso(day);
        // Second click on the already-selected day → drill down to day view.
        if (iso == state.selectedDate) {
          ref
              .read(companyPlanningProvider.notifier)
              .setViewMode(CompanyPlanningViewMode.day);
        } else {
          // First click → just select the day; stay in month view so the
          // right-side panel shows the day's appointments.
          ref.read(companyPlanningProvider.notifier).setDate(day);
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Right panel: pending approvals
// ---------------------------------------------------------------------------

class _DesktopApprovalsPanel extends ConsumerWidget {
  final CompanyPlanningState state;

  const _DesktopApprovalsPanel({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMonthView = state.viewMode == CompanyPlanningViewMode.month;

    // In month view, show ALL appointments for the selected day (from
    // rangeAppointments). Otherwise, show pending appointments for today.
    final List<PlanningAppointmentModel> dayList = isMonthView
        ? (state.rangeAppointments[state.selectedDate] ?? const [])
            .toList()
        // Pending-to-approve panel: hide slots that have already started —
        // the owner has nothing useful to decide on a past time.
        : state.appointments
            .where((a) => a.status == 'pending' && !a.isPast)
            .toList();

    dayList.sort((a, b) => a.startTime.compareTo(b.startTime));

    final confirmedCount =
        state.appointments.where((a) => a.status == 'confirmed').length;

    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            child: isMonthView
                ? _MonthPanelHeader(
                    selectedDate: state.selectedDate,
                    total: dayList.length,
                    confirmed: dayList
                        .where((a) => a.status == 'confirmed')
                        .length,
                    pending: dayList
                        .where((a) => a.status == 'pending')
                        .length,
                    rejected: dayList
                        .where((a) => a.status == 'rejected')
                        .length,
                    cancelled: dayList
                        .where((a) => a.status == 'cancelled')
                        .length,
                    noShow: dayList
                        .where((a) => a.status == 'no_show')
                        .length,
                    onOpenDay: () => ref
                        .read(companyPlanningProvider.notifier)
                        .setViewMode(CompanyPlanningViewMode.day),
                  )
                : _PendingPanelHeader(
                    pendingCount: dayList.length,
                    confirmedCount: confirmedCount,
                  ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // List
          Expanded(
            child: state.isLoading &&
                    state.appointments.isEmpty &&
                    state.rangeAppointments.isEmpty
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : dayList.isEmpty
                    ? (isMonthView ? _EmptyDay() : _EmptyApprovals())
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: dayList.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, i) => _DayAppointmentCard(
                          appointment: dayList[i],
                          onConfirm: () => ref
                              .read(companyPlanningProvider.notifier)
                              .confirmAppointment(dayList[i].id),
                          onReject: () => ref
                              .read(companyPlanningProvider.notifier)
                              .rejectAppointment(dayList[i].id),
                          onCancel: () => ref
                              .read(companyPlanningProvider.notifier)
                              .cancelAppointment(dayList[i].id),
                          onMarkNoShow: () => ref
                              .read(companyPlanningProvider.notifier)
                              .markNoShow(dayList[i].id),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panel headers (default "Pending" vs month-mode "Selected day")
// ---------------------------------------------------------------------------

class _PendingPanelHeader extends StatelessWidget {
  final int pendingCount;
  final int confirmedCount;

  const _PendingPanelHeader({
    required this.pendingCount,
    required this.confirmedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.approvalsTitle,
          style: AppTextStyles.overline.copyWith(
            color: AppColors.textHint,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: GoogleFonts.fraunces(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
              height: 1.1,
            ),
            children: [
              TextSpan(text: '$pendingCount'),
              TextSpan(
                text: context.l10n.approvalsPendingSuffix,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.approvalsConfirmedToday(confirmedCount),
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _MonthPanelHeader extends StatelessWidget {
  final String selectedDate;
  final int total;
  final int confirmed;
  final int pending;
  final int rejected;
  final int cancelled;
  final int noShow;
  final VoidCallback onOpenDay;

  const _MonthPanelHeader({
    required this.selectedDate,
    required this.total,
    required this.confirmed,
    required this.pending,
    required this.rejected,
    required this.cancelled,
    required this.noShow,
    required this.onOpenDay,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(selectedDate) ?? DateTime.now();
    final l = context.l10n;
    final months = [
      l.monthJan, l.monthFeb, l.monthMar, l.monthApr,
      l.monthMay, l.monthJun, l.monthJul, l.monthAug,
      l.monthSep, l.monthOct, l.monthNov, l.monthDec,
    ];
    final dayNames = [
      l.monday, l.tuesday, l.wednesday, l.thursday,
      l.friday, l.saturday, l.sunday,
    ];
    final formatted =
        '${dayNames[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatted.toUpperCase(),
          style: AppTextStyles.overline.copyWith(
            color: AppColors.textHint,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: GoogleFonts.fraunces(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
              height: 1.1,
            ),
            children: [
              TextSpan(text: '$total'),
              TextSpan(
                text: ' ${total <= 1 ? l.appointmentSingular : l.appointmentPlural}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
        // Breakdown — only non-zero chips to keep the header uncluttered
        // for clean months.
        if (total > 0) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: 6,
            children: [
              if (confirmed > 0)
                _HeaderStatChip(
                  color: AppColors.primary,
                  count: confirmed,
                  label: l.monthStatConfirmed,
                ),
              if (pending > 0)
                _HeaderStatChip(
                  color: AppColors.warning,
                  count: pending,
                  label: l.monthStatPending,
                ),
              if (noShow > 0)
                _HeaderStatChip(
                  // No-show & cancelled share the same neutral grey tone
                  // in the counter — they're both "didn't happen" buckets
                  // seen as informational, not alerts.
                  color: AppColors.textHint,
                  count: noShow,
                  label: l.monthStatNoShow,
                ),
              if (cancelled > 0)
                _HeaderStatChip(
                  color: AppColors.textHint,
                  count: cancelled,
                  label: l.monthStatCancelled,
                ),
              if (rejected > 0)
                _HeaderStatChip(
                  color: AppColors.textHint,
                  count: rejected,
                  label: l.monthStatRejected,
                ),
            ],
          ),
        ],
        // Clickable hint → opens the day view directly
        const SizedBox(height: AppSpacing.sm),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onOpenDay,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 13,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l.clickToOpenDay,
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.secondary,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderStatChip extends StatelessWidget {
  final Color color;
  final int count;
  final String label;

  const _HeaderStatChip({
    required this.color,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$count',
          style: GoogleFonts.fraunces(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.instrumentSans(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// Empty state for the selected-day list (month mode).
class _EmptyDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_available_outlined,
                size: 28,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.emptyDayTitle,
              style: AppTextStyles.subtitle
                  .copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.emptyDaySubtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state for approvals panel
// ---------------------------------------------------------------------------

class _EmptyApprovals extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.allApprovedTitle,
              style: AppTextStyles.subtitle
                  .copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.allApprovedSubtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending appointment card in approvals panel
// ---------------------------------------------------------------------------

class _DayAppointmentCard extends StatelessWidget {
  final PlanningAppointmentModel appointment;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onCancel;
  final VoidCallback onMarkNoShow;

  const _DayAppointmentCard({
    required this.appointment,
    required this.onConfirm,
    required this.onReject,
    required this.onCancel,
    required this.onMarkNoShow,
  });

  @override
  Widget build(BuildContext context) {
    final isWalkIn = appointment.isWalkIn;
    final status = appointment.status;
    final isCancelled =
        status == 'rejected' || status == 'cancelled' || status == 'no_show';
    // Past appointments shouldn't offer confirm/reject/cancel actions —
    // the owner can no longer act on them as a booking decision.
    final isPast = appointment.isPast;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header: time + status/walk-in badge
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
            child: Row(
              children: [
                Text(
                  appointment.startTime,
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '→ ${appointment.endTime}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint),
                ),
                const Spacer(),
                if (isWalkIn)
                  Container(
                    margin: const EdgeInsets.only(right: AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      context.l10n.walkInBadge,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                _StatusPill(status: status),
              ],
            ),
          ),

          // Client name + service
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.clientFullName,
                  style: AppTextStyles.subtitle
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (appointment.service.name.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    appointment.service.name,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (appointment.employeeName != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        appointment.employeeName!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textHint),
                      ),
                    ],
                  ),
                ],
                if (appointment.clientPhone != null &&
                    appointment.clientPhone!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  InkWell(
                    onTap: () async {
                      final uri = Uri(
                        scheme: 'tel',
                        path: appointment.clientPhone!,
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_rounded,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              appointment.clientPhone!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary
                                    .withValues(alpha: 0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.divider),

          // Client-initiated cancellation motif — shown on cancelled cards.
          if (status == 'cancelled' &&
              (appointment.cancellationReason?.trim().isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: CancellationReasonBox(
                  reason: appointment.cancellationReason!),
            ),

          // Action buttons:
          //   pending + future    → [Reject] [Confirm]
          //   confirmed + future  → [Cancel]
          //   confirmed + past, within 24h → [Mark no-show]
          //   confirmed + past, >24h → no buttons (too old)
          //   anything else       → no buttons
          if (!isCancelled &&
              (status == 'pending'
                  ? !isPast
                  : (!isPast || appointment.canMarkNoShow)))
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: status == 'pending'
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(
                                  color: AppColors.error
                                      .withValues(alpha: 0.5)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              minimumSize: const Size(0, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                            ),
                            onPressed: onReject,
                            child: Text(
                              context.l10n.reject,
                              style: GoogleFonts.instrumentSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              minimumSize: const Size(0, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                            ),
                            onPressed: onConfirm,
                            child: Text(
                              context.l10n.confirm,
                              style: GoogleFonts.instrumentSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.background,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: isPast
                          ? OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error
                                    .withValues(alpha: 0.7),
                                side: BorderSide(
                                    color: AppColors.error
                                        .withValues(alpha: 0.4)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm),
                                ),
                              ),
                              onPressed: onMarkNoShow,
                              icon: const Icon(Icons.person_off_outlined,
                                  size: 16),
                              label: Text(
                                context.l10n.markNoShow,
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(
                                    color: AppColors.error
                                        .withValues(alpha: 0.5)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm),
                                ),
                              ),
                              onPressed: onCancel,
                              child: Text(
                                context.l10n.cancelAppointment,
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
            ),
        ],
      ),
    );
  }
}

// Compact status pill used in day-appointment cards.
class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (Color color, String label) = switch (status) {
      'confirmed' => (AppColors.primary, l.appointmentConfirmed),
      'pending' => (AppColors.warning, l.appointmentPending),
      _ => (AppColors.textHint, l.appointmentCancelled),
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 1, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.instrumentSans(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day view stats header — compact totals with dot-prefixed chips.
// Mirrors the month-panel breakdown so the owner gets the same situational
// awareness whether they're on the month or the day. Only non-zero buckets
// are shown to keep the header uncluttered for quiet days.
// ---------------------------------------------------------------------------

class _DayStatsHeader extends StatelessWidget {
  final DateTime selectedDate;
  final int total;
  final int confirmed;
  final int pending;
  final int noShow;
  final int cancelled;
  final int rejected;

  const _DayStatsHeader({
    required this.selectedDate,
    required this.total,
    required this.confirmed,
    required this.pending,
    required this.noShow,
    required this.cancelled,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final months = [
      l.monthJan, l.monthFeb, l.monthMar, l.monthApr,
      l.monthMay, l.monthJun, l.monthJul, l.monthAug,
      l.monthSep, l.monthOct, l.monthNov, l.monthDec,
    ];
    final dayNames = [
      l.monday, l.tuesday, l.wednesday, l.thursday,
      l.friday, l.saturday, l.sunday,
    ];
    final formatted =
        '${dayNames[selectedDate.weekday - 1]} ${selectedDate.day} ${months[selectedDate.month - 1]}';

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border:
            Border.all(color: AppColors.border.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left — day label + big total
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatted.toUpperCase(),
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.textHint,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.fraunces(
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                  children: [
                    TextSpan(text: '$total'),
                    TextSpan(
                      text:
                          ' ${total <= 1 ? l.appointmentSingular : l.appointmentPlural}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Right — non-zero chips wrap
          if (total > 0)
            Flexible(
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                children: [
                  if (confirmed > 0)
                    _HeaderStatChip(
                      color: AppColors.primary,
                      count: confirmed,
                      label: l.monthStatConfirmed,
                    ),
                  if (pending > 0)
                    _HeaderStatChip(
                      color: AppColors.warning,
                      count: pending,
                      label: l.monthStatPending,
                    ),
                  if (noShow > 0)
                    _HeaderStatChip(
                      color: AppColors.textHint,
                      count: noShow,
                      label: l.monthStatNoShow,
                    ),
                  if (cancelled > 0)
                    _HeaderStatChip(
                      color: AppColors.textHint,
                      count: cancelled,
                      label: l.monthStatCancelled,
                    ),
                  if (rejected > 0)
                    _HeaderStatChip(
                      color: AppColors.textHint,
                      count: rejected,
                      label: l.monthStatRejected,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
