import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/ux_prefs_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/my_company_model.dart';
import '../widgets/cancel_appointment_owner_dialog.dart';
import '../widgets/cancellation_reason_box.dart';
import '../widgets/reject_appointment_dialog.dart';
import '../widgets/rejection_reason_box.dart';
import '../../data/models/planning_appointment_model.dart';
import '../providers/company_dashboard_provider.dart';
import '../providers/company_planning_provider.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';

// ---------------------------------------------------------------------------
// Grid constants — shared with desktop presentation
// ---------------------------------------------------------------------------

const double kPlanningRowHeight = 40.0;
const double kPlanningTimeColumnWidth = 52.0;

// ---------------------------------------------------------------------------
// Time helpers — exported so desktop can reuse them
// ---------------------------------------------------------------------------

int planningTimeToMinutes(String time) {
  final parts = time.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

String planningMinutesToTime(int totalMinutes) {
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

int planningSlotsFor(int minutes) => (minutes / 15).ceil();

bool planningIsSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String planningToIso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime planningWeekStart(DateTime date) =>
    date.subtract(Duration(days: date.weekday - 1));

// ---------------------------------------------------------------------------
// Grid row descriptor
// ---------------------------------------------------------------------------

class PlanningGridRow {
  final int index;
  final String time;
  final bool isHour;

  const PlanningGridRow({
    required this.index,
    required this.time,
    required this.isHour,
  });
}

List<PlanningGridRow> buildPlanningRows(OpeningHourModel hours) {
  final startMin = planningTimeToMinutes(hours.openTime!);
  final endMin = planningTimeToMinutes(hours.closeTime!);
  final count = planningSlotsFor(endMin - startMin);

  return List.generate(count, (i) {
    final totalMin = startMin + i * 15;
    return PlanningGridRow(
      index: i,
      time: planningMinutesToTime(totalMin),
      isHour: totalMin % 60 == 0,
    );
  });
}

// ---------------------------------------------------------------------------
// Positioned event descriptor
// ---------------------------------------------------------------------------

class PlanningGridEvent {
  final int startRow;
  final int rowSpan;
  final PlanningAppointmentModel appointment;
  final int laneIndex;
  final int laneCount;

  const PlanningGridEvent({
    required this.startRow,
    required this.rowSpan,
    required this.appointment,
    this.laneIndex = 0,
    this.laneCount = 1,
  });
}

List<PlanningGridEvent> assignPlanningLanes(List<PlanningGridEvent> raw) {
  if (raw.isEmpty) return raw;

  final sorted = [...raw]
    ..sort((a, b) {
      final s = a.startRow.compareTo(b.startRow);
      return s != 0 ? s : b.rowSpan.compareTo(a.rowSpan);
    });

  final laneIndices = List<int>.filled(sorted.length, 0);
  final laneEndRow = <int>[];

  for (var i = 0; i < sorted.length; i++) {
    final ev = sorted[i];
    int assignedLane = -1;
    for (var l = 0; l < laneEndRow.length; l++) {
      if (laneEndRow[l] <= ev.startRow) {
        assignedLane = l;
        break;
      }
    }
    if (assignedLane == -1) {
      assignedLane = laneEndRow.length;
      laneEndRow.add(0);
    }
    laneEndRow[assignedLane] = ev.startRow + ev.rowSpan;
    laneIndices[i] = assignedLane;
  }

  final counts = List<int>.filled(sorted.length, 1);
  for (var i = 0; i < sorted.length; i++) {
    final a = sorted[i];
    var maxLane = laneIndices[i];
    for (var j = 0; j < sorted.length; j++) {
      if (i == j) continue;
      final b = sorted[j];
      final overlaps =
          a.startRow < b.startRow + b.rowSpan && b.startRow < a.startRow + a.rowSpan;
      if (overlaps && laneIndices[j] > maxLane) maxLane = laneIndices[j];
    }
    counts[i] = maxLane + 1;
  }

  return List.generate(sorted.length, (i) {
    final ev = sorted[i];
    return PlanningGridEvent(
      startRow: ev.startRow,
      rowSpan: ev.rowSpan,
      appointment: ev.appointment,
      laneIndex: laneIndices[i],
      laneCount: counts[i],
    );
  });
}

List<PlanningGridEvent> buildPlanningEvents({
  required OpeningHourModel hours,
  required List<PlanningAppointmentModel> appointments,
}) {
  final startMin = planningTimeToMinutes(hours.openTime!);
  final events = <PlanningGridEvent>[];

  for (final appt in appointments) {
    final apptStart = planningTimeToMinutes(appt.startTime);
    final apptEnd = planningTimeToMinutes(appt.endTime);
    final startRow = (apptStart - startMin) ~/ 15;
    final rowSpan = planningSlotsFor(apptEnd - apptStart).clamp(1, 9999);
    events.add(PlanningGridEvent(
      startRow: startRow,
      rowSpan: rowSpan,
      appointment: appt,
    ));
  }

  return assignPlanningLanes(events);
}

// ---------------------------------------------------------------------------
// Callback typedefs
// ---------------------------------------------------------------------------

typedef OnShowWalkInDialog = Future<void> Function(
    String slotTime, List<MyServiceModel> services);

// ---------------------------------------------------------------------------
// Mobile presentation
// ---------------------------------------------------------------------------

class CompanyPlanningScreenMobile extends ConsumerStatefulWidget {
  final OnShowWalkInDialog onShowWalkInDialog;
  final VoidCallback onPickDate;

  const CompanyPlanningScreenMobile({
    super.key,
    required this.onShowWalkInDialog,
    required this.onPickDate,
  });

  @override
  ConsumerState<CompanyPlanningScreenMobile> createState() =>
      _CompanyPlanningScreenMobileState();
}

class _CompanyPlanningScreenMobileState
    extends ConsumerState<CompanyPlanningScreenMobile> {
  final ScrollController _dayScrollController = ScrollController();
  String? _autoScrolledForDate;

  @override
  void dispose() {
    _dayScrollController.dispose();
    super.dispose();
  }

  /// Scrolls the day view so the current-time line sits near the top
  /// of the viewport. Called once per date.
  void _maybeAutoScrollToNow(CompanyPlanningState state, OpeningHourModel hours) {
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

    // Target: 15 min before "now" → shows context above the line.
    final anchorMin = (currentMin - 15).clamp(openMin, closeMin);
    final offsetPx = (anchorMin - openMin) / 15 * kPlanningRowHeight;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_dayScrollController.hasClients) return;
      final maxExtent =
          _dayScrollController.position.maxScrollExtent;
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
    final state = ref.watch(companyPlanningProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PlanningDateHeader(
              selectedDate: state.selectedDate,
              viewMode: state.viewMode,
              onPrevious: () =>
                  ref.read(companyPlanningProvider.notifier).goPrevious(),
              onNext: () =>
                  ref.read(companyPlanningProvider.notifier).goNext(),
              onPickDate: widget.onPickDate,
            ),
            PlanningViewModeToggle(
              current: state.viewMode,
              onSelect: (mode) =>
                  ref.read(companyPlanningProvider.notifier).setViewMode(mode),
            ),
            // Each view now embeds its own stats header:
            //   • Day   → _MobileDayStatsHeader (in _buildDayBody)
            //   • Week  → _MobileDayStatsHeader (wrapped around PlanningWeekView)
            //   • Month → _MonthTotalsStrip (inside PlanningMonthView)
            // No global bar here to avoid duplication.
            Expanded(child: _buildBody(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CompanyPlanningState state) {
    switch (state.viewMode) {
      case CompanyPlanningViewMode.week:
        return _buildWeekBody(state);
      case CompanyPlanningViewMode.month:
        return _buildMonthBody(state);
      case CompanyPlanningViewMode.day:
        return _buildDayBody(context, state);
    }
  }

  Widget _buildDayBody(BuildContext context, CompanyPlanningState state) {
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

    // Trigger one-time auto-scroll to "now - 15 min" when on today's day view.
    _maybeAutoScrollToNow(state, todayHours);

    // Per-day totals for the stats header (non-zero chips only).
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
            child: _MobileDayStatsHeader(
              total: state.appointments.length,
              confirmed: dayConfirmed,
              pending: dayPending,
              noShow: dayNoShow,
              cancelled: dayCancelled,
              rejected: dayRejected,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: PlanningTimelineGrid(
                rows: rows,
                events: events,
                workEnd: todayHours.closeTime!,
                services: services,
                currentTimeMinutes: nowMinutes,
                onTapFreeSlot: (time) =>
                    widget.onShowWalkInDialog(time, services),
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

  Widget _buildWeekBody(CompanyPlanningState state) {
    if (state.isLoading && state.rangeAppointments.isEmpty) {
      return const SkeletonPlanningDay();
    }

    final selected = DateTime.tryParse(state.selectedDate) ?? DateTime.now();
    final weekStart = planningWeekStart(selected);
    final totals = _weekTotals(state.rangeAppointments, weekStart);

    return Column(
      children: [
        _MobileDayStatsHeader(
          total: totals.total,
          confirmed: totals.confirmed,
          pending: totals.pending,
          noShow: totals.noShow,
          cancelled: totals.cancelled,
          rejected: totals.rejected,
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

  /// Aggregates the week totals from the range map (keyed by ISO date).
  _StatusCounts _weekTotals(
      Map<String, List<PlanningAppointmentModel>> byDate,
      DateTime weekStart) {
    var confirmed = 0, pending = 0, noShow = 0, cancelled = 0, rejected = 0;
    for (var i = 0; i < 7; i++) {
      final iso = planningToIso(weekStart.add(Duration(days: i)));
      final list = byDate[iso];
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
    return _StatusCounts(
      total: confirmed + pending + noShow + cancelled + rejected,
      confirmed: confirmed,
      pending: pending,
      noShow: noShow,
      cancelled: cancelled,
      rejected: rejected,
    );
  }

  Widget _buildMonthBody(CompanyPlanningState state) {
    if (state.isLoading && state.rangeAppointments.isEmpty) {
      return const SkeletonPlanningDay();
    }

    final selected = DateTime.tryParse(state.selectedDate) ?? DateTime.now();

    return PlanningMonthView(
      month: DateTime(selected.year, selected.month, 1),
      appointmentsByDate: state.rangeAppointments,
      selectedDate: selected,
      onTapDay: (day) {
        ref
            .read(companyPlanningProvider.notifier)
            .setViewMode(CompanyPlanningViewMode.day);
        ref.read(companyPlanningProvider.notifier).setDate(day);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Date header — exported
// ---------------------------------------------------------------------------

class PlanningDateHeader extends StatelessWidget {
  final String selectedDate;
  final CompanyPlanningViewMode viewMode;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickDate;

  const PlanningDateHeader({
    super.key,
    required this.selectedDate,
    required this.viewMode,
    required this.onPrevious,
    required this.onNext,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(selectedDate) ?? DateTime.now();
    final isToday = planningIsSameDay(date, DateTime.now());

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.textPrimary,
            iconSize: 28,
            onPressed: onPrevious,
            tooltip: context.l10n.previousDay,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onPickDate,
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_formatDate(context, date),
                          style: AppTextStyles.h3),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(Icons.calendar_today_rounded,
                          size: 16, color: AppColors.primary),
                    ],
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        context.l10n.todayLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.textPrimary,
            iconSize: 28,
            onPressed: onNext,
            tooltip: context.l10n.nextDay,
          ),
        ],
      ),
    );
  }

  static String _formatDate(BuildContext context, DateTime date) {
    final l = context.l10n;
    final months = [
      l.monthShortJan, l.monthShortFeb, l.monthShortMar, l.monthShortApr,
      l.monthShortMay, l.monthShortJun, l.monthShortJul, l.monthShortAug,
      l.monthShortSep, l.monthShortOct, l.monthShortNov, l.monthShortDec,
    ];
    final days = [
      l.monday, l.tuesday, l.wednesday, l.thursday,
      l.friday, l.saturday, l.sunday,
    ];
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }
}

// ---------------------------------------------------------------------------
// View mode toggle — exported
// ---------------------------------------------------------------------------

class PlanningViewModeToggle extends StatelessWidget {
  final CompanyPlanningViewMode current;
  final void Function(CompanyPlanningViewMode) onSelect;

  const PlanningViewModeToggle({
    super.key,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final modes = [
      (CompanyPlanningViewMode.day, l.viewDay),
      (CompanyPlanningViewMode.week, l.viewWeek),
      (CompanyPlanningViewMode.month, l.viewMonth),
    ];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: modes.map((entry) {
          final (mode, label) = entry;
          final isActive = current == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                margin: EdgeInsets.only(
                    right: mode != CompanyPlanningViewMode.month ? 4 : 0),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.textPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: isActive
                      ? null
                      : Border.all(color: AppColors.border, width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  label.toUpperCase(),
                  style: GoogleFonts.instrumentSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.08 * 10,
                    color: isActive
                        ? AppColors.background
                        : AppColors.textHint,
                    height: 1.2,
                  ),
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
// Appointments count bar — exported
// ---------------------------------------------------------------------------

class PlanningAppointmentsCountBar extends StatelessWidget {
  final CompanyPlanningState state;
  const PlanningAppointmentsCountBar({super.key, required this.state});

  List<PlanningAppointmentModel> _collect() {
    if (state.viewMode == CompanyPlanningViewMode.day) {
      return state.appointments;
    }
    return state.rangeAppointments.values.expand((l) => l).toList();
  }

  String _contextLabel(BuildContext context) {
    switch (state.viewMode) {
      case CompanyPlanningViewMode.day:
        final d = DateTime.tryParse(state.selectedDate);
        final today = DateTime.now();
        final isToday = d != null &&
            d.year == today.year &&
            d.month == today.month &&
            d.day == today.day;
        return isToday
            ? context.l10n.todayLabel.toUpperCase()
            : context.l10n.viewDay.toUpperCase();
      case CompanyPlanningViewMode.week:
        return context.l10n.viewWeek.toUpperCase();
      case CompanyPlanningViewMode.month:
        return context.l10n.viewMonth.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _collect();
    final confirmed = all.where((a) => a.status == 'confirmed').length;
    final pending = all.where((a) => a.status == 'pending').length;
    final total = confirmed + pending;

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$total',
            style: AppTextStyles.h1.copyWith(
                fontSize: 32, height: 1, letterSpacing: -0.5),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _contextLabel(context),
                  style: AppTextStyles.overline.copyWith(
                      color: AppColors.textHint, letterSpacing: 1.3),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: '$confirmed',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          ' ${context.l10n.appointmentConfirmed.toLowerCase()}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    TextSpan(
                      text: '  ·  ',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textHint),
                    ),
                    TextSpan(
                      text: '$pending',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          ' ${context.l10n.appointmentPending.toLowerCase()}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Week view — exported
// ---------------------------------------------------------------------------

class PlanningWeekView extends StatelessWidget {
  final DateTime weekStart;
  final Map<String, List<PlanningAppointmentModel>> appointmentsByDate;
  final DateTime selectedDate;
  final void Function(DateTime) onTapDay;

  const PlanningWeekView({
    super.key,
    required this.weekStart,
    required this.appointmentsByDate,
    required this.selectedDate,
    required this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(7, (i) {
        final day = weekStart.add(Duration(days: i));
        final iso = planningToIso(day);
        final appts = appointmentsByDate[iso] ?? const [];
        final isSelected = planningIsSameDay(day, selectedDate);

        return Expanded(
          child: _PlanningWeekDayColumn(
            day: day,
            appointments: appts,
            isSelected: isSelected,
            onTapHeader: () => onTapDay(day),
            onTapEmpty: () => onTapDay(day),
          ),
        );
      }),
    );
  }
}

class _PlanningWeekDayColumn extends StatelessWidget {
  final DateTime day;
  final List<PlanningAppointmentModel> appointments;
  final bool isSelected;
  final VoidCallback onTapHeader;
  final VoidCallback onTapEmpty;

  const _PlanningWeekDayColumn({
    required this.day,
    required this.appointments,
    required this.isSelected,
    required this.onTapHeader,
    required this.onTapEmpty,
  });

  String _shortDayName(BuildContext context, int weekday) {
    final l = context.l10n;
    switch (weekday) {
      case 1: return l.dayShortMon;
      case 2: return l.dayShortTue;
      case 3: return l.dayShortWed;
      case 4: return l.dayShortThu;
      case 5: return l.dayShortFri;
      case 6: return l.dayShortSat;
      default: return l.dayShortSun;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = planningIsSameDay(day, DateTime.now());
    final sorted = [...appointments]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final visible = sorted.take(10).toList();
    final overflow = sorted.length - visible.length;

    return Column(
      children: [
        GestureDetector(
          onTap: onTapHeader,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.textPrimary : Colors.transparent,
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1),
                right: BorderSide(color: AppColors.divider, width: 0.5),
              ),
            ),
            child: Column(
              children: [
                Text(
                  _shortDayName(context, day.weekday).toUpperCase(),
                  style: GoogleFonts.instrumentSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: isSelected ? AppColors.background : AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: GoogleFonts.fraunces(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? AppColors.primary
                              : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: appointments.isEmpty ? onTapEmpty : null,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                children: [
                  ...visible.map((appt) =>
                      PlanningWeekEventPill(appointment: appt)),
                  if (overflow > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '+$overflow',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.instrumentSans(
                            fontSize: 9, color: AppColors.textHint),
                      ),
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

// ---------------------------------------------------------------------------
// Week event pill — exported so desktop can reuse
// ---------------------------------------------------------------------------

class PlanningWeekEventPill extends StatelessWidget {
  final PlanningAppointmentModel appointment;
  const PlanningWeekEventPill({super.key, required this.appointment});

  Color get _accentColor {
    switch (appointment.status) {
      case 'confirmed': return AppColors.primary;
      case 'pending': return AppColors.warning;
      default: return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;
    final firstName = appointment.clientFullName.split(' ').first;

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.fromLTRB(5, 3, 3, 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appointment.startTime,
            style: GoogleFonts.fraunces(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: accent,
              height: 1.2,
            ),
          ),
          Text(
            firstName,
            style: GoogleFonts.instrumentSans(
              fontSize: 11,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Month view — exported
// ---------------------------------------------------------------------------

class PlanningMonthView extends StatelessWidget {
  final DateTime month;
  final Map<String, List<PlanningAppointmentModel>> appointmentsByDate;
  final DateTime selectedDate;
  final void Function(DateTime) onTapDay;
  final double childAspectRatio;
  final bool compact;

  const PlanningMonthView({
    super.key,
    required this.month,
    required this.appointmentsByDate,
    required this.selectedDate,
    required this.onTapDay,
    this.childAspectRatio = 0.8,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final firstWeekday = month.weekday;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final cells = <DateTime?>[];
    for (var i = 1; i < firstWeekday; i++) {
      cells.add(
          DateTime(month.year, month.month, 1 - (firstWeekday - 1) + i - 1));
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(month.year, month.month, d));
    }
    while (cells.length < 42) {
      final last = cells.last!;
      cells.add(last.add(const Duration(days: 1)));
    }

    final dayHeaders = [
      context.l10n.dayShortMon,
      context.l10n.dayShortTue,
      context.l10n.dayShortWed,
      context.l10n.dayShortThu,
      context.l10n.dayShortFri,
      context.l10n.dayShortSat,
      context.l10n.dayShortSun,
    ];

    // Compute monthly totals (only for days inside `month`). Each terminal
    // status is counted separately — refus / annulation / absence ne sont
    // pas la même chose du point de vue d'un owner qui veut comprendre son
    // taux de remplissage et son taux d'absentéisme.
    var totalCount = 0;
    var confirmedCount = 0;
    var pendingCount = 0;
    var rejectedCount = 0;
    var cancelledCount = 0;
    var noShowCount = 0;
    appointmentsByDate.forEach((iso, appts) {
      if (iso.length < 7) return;
      if (iso.substring(0, 7) != planningToIso(DateTime(month.year, month.month, 1)).substring(0, 7)) {
        return;
      }
      for (final a in appts) {
        totalCount++;
        switch (a.status) {
          case 'confirmed': confirmedCount++;
          case 'pending': pendingCount++;
          case 'rejected': rejectedCount++;
          case 'cancelled': cancelledCount++;
          case 'no_show': noShowCount++;
        }
      }
    });

    return Column(
      children: [
        // Monthly totals — editorial summary strip
        _MonthTotalsStrip(
          total: totalCount,
          confirmed: confirmedCount,
          pending: pendingCount,
          rejected: rejectedCount,
          cancelled: cancelledCount,
          noShow: noShowCount,
        ),
        // Day-of-week header row
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          child: Row(
            children: dayHeaders
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d.toUpperCase(),
                        style: AppTextStyles.overline.copyWith(
                          color: AppColors.textHint,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: cells.length,
            itemBuilder: (_, i) {
              final day = cells[i];
              if (day == null) return const SizedBox.shrink();
              final iso = planningToIso(day);
              final appts = appointmentsByDate[iso] ?? const [];
              final isSelected = planningIsSameDay(day, selectedDate);
              final isCurrentMonth = day.month == month.month;
              final isToday = planningIsSameDay(day, DateTime.now());

              return _MonthDayCell(
                day: day,
                appointments: appts,
                isSelected: isSelected,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                compact: compact,
                onTap: () => onTapDay(day),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Month totals strip — editorial summary shown above the day grid
// ---------------------------------------------------------------------------

class _MonthTotalsStrip extends StatelessWidget {
  final int total;
  final int confirmed;
  final int pending;
  final int rejected;
  final int cancelled;
  final int noShow;

  const _MonthTotalsStrip({
    required this.total,
    required this.confirmed,
    required this.pending,
    required this.rejected,
    required this.cancelled,
    required this.noShow,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isNarrow = MediaQuery.sizeOf(context).width < 500;

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.md),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: isNarrow ? AppSpacing.sm : AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Big Fraunces number + overline label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.monthTotalOverline.toUpperCase(),
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.textHint,
                  letterSpacing: 1.2,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.fraunces(
                    fontSize: isNarrow ? 32 : 40,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    letterSpacing: -1.2,
                    height: 1.0,
                  ),
                  children: [
                    TextSpan(text: '$total'),
                    TextSpan(
                      text: '.',
                      style: GoogleFonts.fraunces(
                        fontSize: isNarrow ? 32 : 40,
                        fontWeight: FontWeight.w400,
                        color: AppColors.primary,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Thin gold separator
          Container(
            width: 1,
            height: isNarrow ? 36 : 48,
            color: AppColors.secondary.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          ),
          // Status breakdown — only surface rows whose count > 0 so an owner
          // with a clean month isn't confronted with a wall of zeros. The
          // leading dot colour differentiates each status at a glance.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _buildStatRows(l),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatRows(dynamic l) {
    // No-show and cancelled share the grey tone in the counter — they're
    // informational, not alerts. Dots on the month cells keep their colours.
    final rows = <(Color, int, String)>[
      (AppColors.primary,   confirmed, l.monthStatConfirmed),
      (AppColors.warning,   pending,   l.monthStatPending),
      (AppColors.textHint,  noShow,    l.monthStatNoShow),
      (AppColors.textHint,  cancelled, l.monthStatCancelled),
      (AppColors.textHint,  rejected,  l.monthStatRejected),
    ];
    final widgets = <Widget>[];
    for (final (color, count, label) in rows) {
      if (count <= 0) continue;
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 4));
      widgets.add(_StatRow(color: color, count: count, label: label));
    }
    // Fallback: if every bucket is 0, show a single muted "confirmed: 0" so
    // the strip doesn't collapse to just the big total.
    if (widgets.isEmpty) {
      widgets.add(_StatRow(
          color: AppColors.textHint, count: 0, label: l.monthStatConfirmed));
    }
    return widgets;
  }
}

class _StatRow extends StatelessWidget {
  final Color color;
  final int count;
  final String label;

  const _StatRow({
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
        const SizedBox(width: 6),
        Text(
          '$count',
          style: GoogleFonts.fraunces(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.instrumentSerif(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _MonthDayCell extends StatelessWidget {
  final DateTime day;
  final List<PlanningAppointmentModel> appointments;
  final bool isSelected;
  final bool isCurrentMonth;
  final bool isToday;
  final bool compact;
  final VoidCallback onTap;

  const _MonthDayCell({
    required this.day,
    required this.appointments,
    required this.isSelected,
    required this.isCurrentMonth,
    required this.isToday,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final count = appointments.length;
    final hasAppointments = count > 0;
    final confirmedCount =
        appointments.where((a) => a.status == 'confirmed').length;
    final pendingCount =
        appointments.where((a) => a.status == 'pending').length;
    final noShowCount =
        appointments.where((a) => a.status == 'no_show').length;
    final cancelledCount =
        appointments.where((a) => a.status == 'cancelled').length;

    final dayFontSize = compact ? 11.0 : 13.0;
    final padding =
        compact ? const EdgeInsets.all(6) : const EdgeInsets.all(6);

    // ── Visual hierarchy ───────────────────────────────────────────────
    // Selected → ink background, gold border, shadow
    // Today    → primary border on ivory
    // Has appt → surface (soft ivory) + subtle border
    // Empty    → transparent + faint border

    final Color bgColor;
    final Border border;
    final List<BoxShadow> shadows;

    if (isSelected) {
      bgColor = AppColors.primary;
      border = Border.all(color: AppColors.secondary, width: 2);
      shadows = [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.32),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];
    } else if (isToday) {
      bgColor = AppColors.background;
      border = Border.all(color: AppColors.primary, width: 1.5);
      shadows = const [];
    } else if (hasAppointments) {
      bgColor = AppColors.surface;
      border = Border.all(
          color: AppColors.border.withValues(alpha: 0.7), width: 1);
      shadows = const [];
    } else {
      bgColor = Colors.transparent;
      border =
          Border.all(color: AppColors.border.withValues(alpha: 0.3), width: 1);
      shadows = const [];
    }

    final dayNumberColor = isSelected
        ? AppColors.background
        : isCurrentMonth
            ? isToday
                ? AppColors.primary
                : AppColors.textPrimary
            : AppColors.textHint.withValues(alpha: 0.35);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(1),
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: border,
            boxShadow: shadows,
          ),
          child: Stack(
            children: [
              // Day number pinned top-left
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  '${day.day}',
                  style: GoogleFonts.instrumentSans(
                    fontSize: dayFontSize,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    letterSpacing: 0.1,
                    color: dayNumberColor,
                  ),
                ),
              ),
              // Dots + (total) dead-centered in the cell
              if (hasAppointments)
                Center(
                  child: _AppointmentDotsRow(
                    confirmed: confirmedCount,
                    pending: pendingCount,
                    noShow: noShowCount,
                    cancelled: cancelledCount,
                    total: count,
                    isSelected: isSelected,
                    compact: compact,
                  ),
                ),
              // "Tap again" pill pinned bottom-center when selected — desktop only.
              // Mobile opens the day view immediately on first tap, so no hint
              // is needed there.
              if (isSelected && compact)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _TapAgainBadge(compact: compact),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Row of colored dots (confirmed = burgundy, pending = warning) + (total)
// ---------------------------------------------------------------------------

class _AppointmentDotsRow extends StatelessWidget {
  final int confirmed;
  final int pending;
  final int noShow;
  final int cancelled;
  final int total;
  final bool isSelected;
  final bool compact;

  const _AppointmentDotsRow({
    required this.confirmed,
    required this.pending,
    required this.noShow,
    required this.cancelled,
    required this.total,
    required this.isSelected,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    // Mobile (non-compact): cap at 6 dots (2 rows of 3), total below.
    // Desktop (compact):     cap at 20 dots, multi-row Wrap, total below.
    // Over the cap → hide dots entirely, show just the (N) — it stays clean.
    final maxDots = compact ? 20 : 6;
    final showDots = total <= maxDots;
    final confirmedShown = showDots ? confirmed : 0;
    final pendingShown = showDots ? pending : 0;
    final noShowShown = showDots ? noShow : 0;
    final cancelledShown = showDots ? cancelled : 0;

    final dotSize = compact ? 5.5 : 8.0;
    final gap = compact ? 2.0 : 4.0;
    // Force 3 dots per row on mobile so 6 dots split as 3+3.
    final dotsRowWidth = compact ? double.infinity : (dotSize * 3 + gap * 2);

    final confirmedColor =
        isSelected ? AppColors.secondary : AppColors.primary;
    final pendingColor = AppColors.warning;
    final noShowColor = AppColors.error;
    final cancelledColor = AppColors.textHint;
    final textColor = isSelected
        ? AppColors.background.withValues(alpha: 0.9)
        : AppColors.textPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showDots)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: SizedBox(
              width: dotsRowWidth,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (int i = 0; i < confirmedShown; i++)
                    Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: confirmedColor,
                      ),
                    ),
                  for (int i = 0; i < pendingShown; i++)
                    Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pendingColor,
                      ),
                    ),
                  for (int i = 0; i < noShowShown; i++)
                    Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: noShowColor,
                      ),
                    ),
                  for (int i = 0; i < cancelledShown; i++)
                    Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cancelledColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        Text(
          '($total)',
          style: GoogleFonts.fraunces(
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Visible "tap again" pill shown on the selected cell
// ---------------------------------------------------------------------------

class _TapAgainBadge extends StatelessWidget {
  final bool compact;

  const _TapAgainBadge({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 7,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: compact ? 10 : 11,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              context.l10n.tapAgain,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.instrumentSans(
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline grid — exported for reuse in desktop
// ---------------------------------------------------------------------------

class PlanningTimelineGrid extends StatefulWidget {
  final List<PlanningGridRow> rows;
  final List<PlanningGridEvent> events;
  final String workEnd;
  final List<MyServiceModel> services;
  final Future<void> Function(String time) onTapFreeSlot;
  final bool Function(String time) isTimeInPast;
  // Current time in minutes of the viewing day (e.g. 870 = 14:30).
  // Non-null only when the grid shows the current day — enables the
  // "now" indicator line.
  final int? currentTimeMinutes;

  const PlanningTimelineGrid({
    super.key,
    required this.rows,
    required this.events,
    required this.workEnd,
    required this.services,
    required this.onTapFreeSlot,
    required this.isTimeInPast,
    this.currentTimeMinutes,
  });

  @override
  State<PlanningTimelineGrid> createState() => _PlanningTimelineGridState();
}

class _PlanningTimelineGridState extends State<PlanningTimelineGrid> {
  String? _expandedApptId;
  final GlobalKey _expandedKey = GlobalKey();
  double _expandedExtra = 0;

  void _scheduleHeightMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _expandedKey.currentContext;
      if (ctx == null) {
        if (_expandedExtra != 0) setState(() => _expandedExtra = 0);
        return;
      }
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final detailH = box.size.height;
      if (detailH != _expandedExtra) setState(() => _expandedExtra = detailH);
    });
  }

  PlanningGridEvent? get _expandedEvent => _expandedApptId == null
      ? null
      : widget.events
          .where((e) => e.appointment.id == _expandedApptId)
          .cast<PlanningGridEvent?>()
          .firstOrNull;

  double _shiftBelow(int row) {
    final ev = _expandedEvent;
    if (ev == null) return 0;
    return row >= ev.startRow + ev.rowSpan ? _expandedExtra : 0;
  }

  Widget _animated({
    required double top,
    required Widget child,
    double? left,
    double? width,
    double? height,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: top),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      builder: (_, t, c) {
        if (left != null && width != null) {
          return Positioned(
              top: t, left: left, width: width, height: height, child: c!);
        }
        return Positioned(top: t, left: 0, right: 0, child: c!);
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) return const SizedBox.shrink();

    final coveredRows = <int>{};
    for (final event in widget.events) {
      for (var i = event.startRow; i < event.startRow + event.rowSpan; i++) {
        coveredRows.add(i);
      }
    }

    final naturalHeight = widget.rows.length * kPlanningRowHeight;
    final totalHeight = naturalHeight + _expandedExtra;

    final expandedEv = _expandedEvent;
    final expandedBottomRow =
        expandedEv != null ? expandedEv.startRow + expandedEv.rowSpan : -1;

    // "Now" indicator offset: compute only if currentTimeMinutes falls
    // inside the opening range. Null → don't render.
    double? nowTopPx;
    String? nowTimeLabel;
    if (widget.currentTimeMinutes != null && widget.rows.isNotEmpty) {
      final openMin = planningTimeToMinutes(widget.rows.first.time);
      final closeMin = planningTimeToMinutes(widget.workEnd);
      final currentMin = widget.currentTimeMinutes!;
      if (currentMin >= openMin && currentMin <= closeMin) {
        nowTopPx = (currentMin - openMin) / 15 * kPlanningRowHeight;
        nowTimeLabel = planningMinutesToTime(currentMin);
      }
    }

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: kPlanningTimeColumnWidth,
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: widget.rows.map((row) {
                final top =
                    row.index * kPlanningRowHeight + _shiftBelow(row.index);
                final hasEvent = coveredRows.contains(row.index);
                return _animated(
                  top: top,
                  child: SizedBox(
                    height: kPlanningRowHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        row.isHour
                            ? Text(
                                row.time,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              )
                            : Container(
                                margin: const EdgeInsets.only(top: 8),
                                width: 6,
                                height: 1,
                                color: AppColors.border,
                              ),
                        if (hasEvent && !widget.isTimeInPast(row.time))
                          _PlanningAddAtRowButton(
                              onTap: () => widget.onTapFreeSlot(row.time)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                final totalWidth = constraints.maxWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: Size(double.infinity, totalHeight),
                      painter: PlanningGridLinePainter(
                        rowCount: widget.rows.length,
                        expandedBottomRow: expandedBottomRow,
                        expandedExtra: _expandedExtra,
                      ),
                    ),
                    ...widget.rows
                        .where((r) =>
                            !coveredRows.contains(r.index) &&
                            !widget.isTimeInPast(r.time))
                        .map((row) {
                      final top = row.index * kPlanningRowHeight +
                          _shiftBelow(row.index);
                      return _animated(
                        top: top,
                        child: SizedBox(
                          height: kPlanningRowHeight,
                          child: _PlanningFreeSlotTarget(
                            time: row.time,
                            onTap: () => widget.onTapFreeSlot(row.time),
                          ),
                        ),
                      );
                    }),
                    ...widget.events.map((event) {
                      final naturalTop = event.startRow * kPlanningRowHeight;
                      final height = event.rowSpan * kPlanningRowHeight;
                      final shift = _shiftBelow(event.startRow);
                      final appt = event.appointment;
                      final isExpanded = _expandedApptId == appt.id;

                      const gutter = 2.0;
                      const vInset = 3.0;
                      final laneWidth =
                          (totalWidth - gutter * (event.laneCount - 1)) /
                              event.laneCount;
                      final laneLeft = event.laneIndex * (laneWidth + gutter);

                      return _animated(
                        top: naturalTop + shift + vInset,
                        left: laneLeft,
                        width: laneWidth,
                        height: isExpanded ? null : height - vInset * 2,
                        child: PlanningAppointmentCard(
                          expandedDetailKey:
                              isExpanded ? _expandedKey : null,
                          appointment: appt,
                          naturalHeight: height - vInset * 2,
                          isExpanded: isExpanded,
                          laneCount: event.laneCount,
                          onToggle: () {
                            setState(() {
                              _expandedApptId =
                                  isExpanded ? null : appt.id;
                              _expandedExtra = 0;
                            });
                            _scheduleHeightMeasure();
                          },
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
          // "Now" indicator — red line with time label spanning full width.
          if (nowTopPx != null)
            Positioned(
              left: 0,
              right: 0,
              top: nowTopPx - 8,
              child: IgnorePointer(
                child: _PlanningNowIndicator(time: nowTimeLabel!),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Now" indicator — pill label + dot + line (Google Calendar style)
// ---------------------------------------------------------------------------

class _PlanningNowIndicator extends StatelessWidget {
  final String time;
  const _PlanningNowIndicator({required this.time});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time label pill in the time column
          Container(
            width: kPlanningTimeColumnWidth,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                time,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Leading dot + horizontal line spanning the events column
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1.5,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid line painter — exported
// ---------------------------------------------------------------------------

class PlanningGridLinePainter extends CustomPainter {
  final int rowCount;
  final int expandedBottomRow;
  final double expandedExtra;

  const PlanningGridLinePainter({
    required this.rowCount,
    this.expandedBottomRow = -1,
    this.expandedExtra = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hourPaint = Paint()
      ..color = const Color(0xFFD0D0DE)
      ..strokeWidth = 0.8;
    final quarterPaint = Paint()
      ..color = const Color(0xFFE8E8F0)
      ..strokeWidth = 0.5;

    for (var i = 0; i < rowCount; i++) {
      final shift =
          (expandedExtra > 0 && i >= expandedBottomRow) ? expandedExtra : 0.0;
      final y = i * kPlanningRowHeight + shift;
      final paint = (i % 4 == 0) ? hourPaint : quarterPaint;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final finalShift = expandedExtra > 0 ? expandedExtra : 0.0;
    canvas.drawLine(
      Offset(0, rowCount * kPlanningRowHeight + finalShift),
      Offset(size.width, rowCount * kPlanningRowHeight + finalShift),
      hourPaint,
    );
  }

  @override
  bool shouldRepaint(PlanningGridLinePainter old) =>
      old.rowCount != rowCount ||
      old.expandedBottomRow != expandedBottomRow ||
      old.expandedExtra != expandedExtra;
}

// ---------------------------------------------------------------------------
// Appointment card — exported
// ---------------------------------------------------------------------------

class PlanningAppointmentCard extends StatelessWidget {
  final PlanningAppointmentModel appointment;
  final double naturalHeight;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Key? expandedDetailKey;
  final int laneCount;

  const PlanningAppointmentCard({
    super.key,
    required this.appointment,
    required this.naturalHeight,
    required this.isExpanded,
    required this.onToggle,
    this.expandedDetailKey,
    this.laneCount = 1,
  });

  Color get _accentColor {
    switch (appointment.status) {
      case 'confirmed': return AppColors.primary;
      case 'pending': return AppColors.warning;
      default: return AppColors.textHint;
    }
  }

  void _showMobileDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) =>
          PlanningAppointmentDetailSheet(appointment: appointment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final accentColor = _accentColor;
    final bgColor = accentColor.withValues(alpha: 0.08);
    final isRejected = appointment.status == 'rejected' ||
        appointment.status == 'cancelled' ||
        appointment.status == 'no_show';

    return GestureDetector(
      onTap: isMobile ? () => _showMobileDetail(context) : onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        constraints: BoxConstraints(minHeight: naturalHeight),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(left: BorderSide(color: accentColor, width: 3)),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(AppSpacing.radiusSm),
            bottomRight: Radius.circular(AppSpacing.radiusSm),
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: isMobile
            ? const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2)
            : const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    appointment.clientFullName,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 12 : 14,
                      color: AppColors.textPrimary,
                      decoration: isRejected
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isMobile) ...[
                  if (appointment.isWalkIn && laneCount == 1) ...[
                    const SizedBox(width: AppSpacing.xs),
                    PlanningWalkInBadge(),
                  ],
                  if (laneCount == 1) ...[
                    const SizedBox(width: AppSpacing.xs),
                    PlanningStatusBadge(status: appointment.status),
                  ],
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
            if (!isMobile) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.content_cut_rounded, size: 11, color: accentColor),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      appointment.service.name,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${appointment.startTime} – ${appointment.endTime}',
                    style: AppTextStyles.caption.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: PlanningAppointmentDetail(
                key: expandedDetailKey,
                appointment: appointment,
                accentColor: accentColor,
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile bottom-sheet detail — exported
// ---------------------------------------------------------------------------

class PlanningAppointmentDetailSheet extends ConsumerStatefulWidget {
  final PlanningAppointmentModel appointment;
  const PlanningAppointmentDetailSheet({super.key, required this.appointment});

  @override
  ConsumerState<PlanningAppointmentDetailSheet> createState() =>
      _PlanningAppointmentDetailSheetState();
}

class _PlanningAppointmentDetailSheetState
    extends ConsumerState<PlanningAppointmentDetailSheet> {
  bool _loading = false;
  PlanningAppointmentModel get appt => widget.appointment;

  Future<void> _confirm() async {
    setState(() => _loading = true);
    final ok = await ref
        .read(companyPlanningProvider.notifier)
        .confirmAppointment(appt.id);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.actionFailed)));
    }
  }

  Future<void> _reject() async {
    final result = await showRejectAppointmentDialog(
      context,
      clientName: appt.clientFullName,
    );
    if (result == null || !result.confirmed || !mounted) return;
    setState(() => _loading = true);
    final ok = await ref
        .read(companyPlanningProvider.notifier)
        .rejectAppointment(appt.id, reason: result.reason);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.actionFailed)));
    }
  }

  Future<void> _freeSlot() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(
          context.l10n.freeSlotConfirmTitle,
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        content: Text(
          context.l10n.freeSlotConfirmBody,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.6)),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.lock_open_rounded, size: 16),
            label: Text(context.l10n.freeSlotButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ref.read(uxPrefsProvider.notifier).lightImpact();
    setState(() => _loading = true);
    final ok = await ref
        .read(companyPlanningProvider.notifier)
        .freeRejectedSlot(appt.id);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.freeSlotDone)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.actionFailed)));
    }
  }

  Future<void> _cancel() async {
    final result = await showCancelAppointmentOwnerDialog(
      context,
      clientName: appt.clientFullName,
    );
    if (result == null || !result.confirmed || !mounted) return;
    setState(() => _loading = true);
    final ok = await ref
        .read(companyPlanningProvider.notifier)
        .cancelAppointment(appt.id, reason: result.reason);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.actionFailed)));
    }
  }

  bool _isPast() => appt.isPast;

  /// No-show is only offered within 24h of the start time — keeps the
  /// planning UI focused on recent events.
  bool _canMarkNoShow() => appt.canMarkNoShow;

  Future<void> _markNoShow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(context.l10n.noShowConfirmTitle),
        content: Text(
          context.l10n.noShowConfirmBody(appt.clientFullName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.8),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.l10n.markNoShow,
              style: const TextStyle(color: AppColors.surface),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    final ok = await ref
        .read(companyPlanningProvider.notifier)
        .markNoShow(appt.id);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noShowRegistered)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.actionFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // useSafeArea: true is set on showModalBottomSheet, so the host handles
    // safe-area insets. We only need the scroll view + bottom buffer here to
    // avoid sub-pixel overflow during the dismiss animation.
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(appt.clientFullName,
                          style: AppTextStyles.h3.copyWith(fontSize: 18)),
                    ),
                    if (appt.isWalkIn) ...[
                      const SizedBox(width: AppSpacing.xs),
                      PlanningWalkInBadge(),
                    ],
                    const SizedBox(width: AppSpacing.xs),
                    PlanningStatusBadge(status: appt.status),
                  ],
                ),
                const Divider(height: AppSpacing.lg, color: AppColors.divider),
                PlanningDetailRow(
                  icon: Icons.content_cut_rounded,
                  label:
                      '${appt.service.name}  •  ${appt.service.durationMinutes} min  •  ${appt.service.price.toStringAsFixed(0)} €',
                ),
                const SizedBox(height: AppSpacing.xs),
                PlanningDetailRow(
                  icon: Icons.event_rounded,
                  label: '${appt.startTime} – ${appt.endTime}',
                ),
                if (appt.clientPhone != null &&
                    appt.clientPhone!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  PlanningSheetPhoneRow(phone: appt.clientPhone!),
                ],
                const SizedBox(height: AppSpacing.md),
                // No-show badge — visible if client has prior no-shows
                if (appt.clientNoShowCount > 0) ...[
                  _NoShowBadge(count: appt.clientNoShowCount),
                  const SizedBox(height: AppSpacing.sm),
                ],
                // Rejection reason — visible when owner rejected (or when
                // the slot was subsequently freed: rejected → cancelled).
                if ((appt.status == 'rejected' || appt.status == 'cancelled') &&
                    (appt.rejectionReason?.trim().isNotEmpty ?? false)) ...[
                  RejectionReasonBox(
                    reason: appt.rejectionReason!,
                    showSlotFreedBadge: appt.status == 'cancelled',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                // Client-initiated cancellation reason — visible whenever
                // the client filled the optional motif. Owners use it to
                // understand patterns (last-minute cancellations, recurring
                // reasons, etc.).
                if (appt.status == 'cancelled' &&
                    (appt.cancellationReason?.trim().isNotEmpty ?? false)) ...[
                  CancellationReasonBox(reason: appt.cancellationReason!),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (_loading)
                  const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                else if (appt.status == 'pending' && !appt.isPast) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _reject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs),
                          ),
                          child: Text(context.l10n.rejectAppointment),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          onPressed: _confirm,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs),
                          ),
                          child: Text(context.l10n.confirmAppointment),
                        ),
                      ),
                    ],
                  ),
                ] else if (appt.status == 'confirmed') ...[
                  // Not yet started → Cancel.
                  // Past start, within 24h → Mark no-show.
                  // Past start, >24h → no action (too old to act on).
                  if (!_isPast())
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _cancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs),
                        ),
                        child: Text(context.l10n.cancel),
                      ),
                    )
                  else if (_canMarkNoShow())
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _markNoShow,
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              AppColors.error.withValues(alpha: 0.7),
                          side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs),
                        ),
                        icon: const Icon(Icons.person_off_outlined, size: 18),
                        label: Text(context.l10n.markNoShow),
                      ),
                    ),
                ] else if (appt.status == 'rejected') ...[
                  // Slot is still blocked — offer to free it.
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _freeSlot,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: BorderSide(
                            color: AppColors.secondary.withValues(alpha: 0.6)),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs),
                      ),
                      icon: const Icon(Icons.lock_open_rounded, size: 18),
                      label: Text(context.l10n.freeSlotButton),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// Expanded inline detail (desktop) — exported
// ---------------------------------------------------------------------------

class PlanningAppointmentDetail extends ConsumerWidget {
  final PlanningAppointmentModel appointment;
  final Color accentColor;

  const PlanningAppointmentDetail({
    super.key,
    required this.appointment,
    required this.accentColor,
  });

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(companyPlanningProvider.notifier)
        .confirmAppointment(appointment.id);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.actionFailed)));
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final result = await showRejectAppointmentDialog(
      context,
      clientName: appointment.clientFullName,
    );
    if (result == null || !result.confirmed || !context.mounted) return;
    final ok = await ref
        .read(companyPlanningProvider.notifier)
        .rejectAppointment(appointment.id, reason: result.reason);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.actionFailed)));
    }
  }

  Future<void> _freeSlot(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(
          context.l10n.freeSlotConfirmTitle,
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        content: Text(
          context.l10n.freeSlotConfirmBody,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: BorderSide(
                  color: AppColors.secondary.withValues(alpha: 0.6)),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.lock_open_rounded, size: 16),
            label: Text(context.l10n.freeSlotButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    ref.read(uxPrefsProvider.notifier).lightImpact();
    final ok = await ref
        .read(companyPlanningProvider.notifier)
        .freeRejectedSlot(appointment.id);
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.freeSlotDone)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.actionFailed)));
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final result = await showCancelAppointmentOwnerDialog(
      context,
      clientName: appointment.clientFullName,
    );
    if (result == null || !result.confirmed || !context.mounted) return;
    final ok = await ref
        .read(companyPlanningProvider.notifier)
        .cancelAppointment(appointment.id, reason: result.reason);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.actionFailed)));
    }
  }

  Future<void> _markNoShow(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.noShowConfirmTitle),
        content: Text(
          context.l10n.noShowConfirmBody(appointment.clientFullName),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.markNoShow,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await ref
        .read(companyPlanningProvider.notifier)
        .markNoShow(appointment.id);
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.noShowRegistered)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.actionFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: AppSpacing.md, color: AppColors.divider),
        PlanningDetailRow(
            icon: Icons.person_rounded, label: appointment.clientFullName),
        if (appointment.clientPhone != null &&
            appointment.clientPhone!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          PlanningPhoneRow(phone: appointment.clientPhone!),
        ],
        const SizedBox(height: AppSpacing.xs),
        PlanningDetailRow(
          icon: Icons.content_cut_rounded,
          label:
              '${appointment.service.name}  •  ${appointment.service.durationMinutes} min  •  ${appointment.service.price.toStringAsFixed(0)} €',
        ),
        if ((appointment.status == 'rejected' ||
                appointment.status == 'cancelled') &&
            (appointment.rejectionReason?.trim().isNotEmpty ?? false)) ...[
          const SizedBox(height: AppSpacing.sm),
          RejectionReasonBox(
            reason: appointment.rejectionReason!,
            showSlotFreedBadge: appointment.status == 'cancelled',
          ),
        ],
        if (appointment.status == 'cancelled' &&
            (appointment.cancellationReason?.trim().isNotEmpty ?? false)) ...[
          const SizedBox(height: AppSpacing.sm),
          CancellationReasonBox(reason: appointment.cancellationReason!),
        ],
        if (appointment.status == 'rejected') ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _freeSlot(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: BorderSide(
                    color: AppColors.secondary.withValues(alpha: 0.6)),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              ),
              icon: const Icon(Icons.lock_open_rounded, size: 16),
              label: Text(context.l10n.freeSlotButton),
            ),
          ),
        ],
        if (appointment.status == 'pending' && !appointment.isPast) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reject(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  ),
                  child: Text(context.l10n.rejectAppointment),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: () => _confirm(context, ref),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  ),
                  child: Text(context.l10n.confirmAppointment),
                ),
              ),
            ],
          ),
        ] else if (appointment.status == 'confirmed' &&
            (!appointment.isPast || appointment.canMarkNoShow)) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: appointment.isPast
                ? OutlinedButton.icon(
                    onPressed: () => _markNoShow(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          AppColors.error.withValues(alpha: 0.7),
                      side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs),
                    ),
                    icon: const Icon(Icons.person_off_outlined, size: 18),
                    label: Text(context.l10n.markNoShow),
                  )
                : OutlinedButton(
                    onPressed: () => _cancel(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs),
                    ),
                    child: Text(context.l10n.cancel),
                  ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared badge / row widgets — exported
// ---------------------------------------------------------------------------

class PlanningDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const PlanningDetailRow({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
      ],
    );
  }
}

class PlanningSheetPhoneRow extends StatelessWidget {
  final String phone;
  const PlanningSheetPhoneRow({super.key, required this.phone});

  Future<void> _dial(BuildContext context) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'\s+'), '')}');
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(phone)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _dial(context),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          const Icon(Icons.phone_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              phone,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.phone_rounded,
                size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class PlanningPhoneRow extends StatelessWidget {
  final String phone;
  const PlanningPhoneRow({super.key, required this.phone});

  Future<void> _dial(BuildContext context) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'\s+'), '')}');
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(phone)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _dial(context),
      child: Row(
        children: [
          const Icon(Icons.phone_rounded, size: 13, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            phone,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.phone_forwarded_rounded,
              size: 11, color: AppColors.primary),
        ],
      ),
    );
  }
}

class PlanningStatusBadge extends StatelessWidget {
  final String status;
  const PlanningStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (status) {
      case 'confirmed':
        color = AppColors.primary;
        label = context.l10n.appointmentConfirmed;
      case 'pending':
        color = AppColors.warning;
        label = context.l10n.appointmentPending;
      case 'rejected':
        color = AppColors.error;
        label = context.l10n.appointmentRejected;
      case 'no_show':
        color = AppColors.textHint;
        label = context.l10n.appointmentNoShow;
      default:
        color = AppColors.textHint;
        label = context.l10n.appointmentCancelled;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs + 2, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class PlanningWalkInBadge extends StatelessWidget {
  const PlanningWalkInBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs + 2, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border:
            Border.all(color: AppColors.warning.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        context.l10n.walkIn,
        style: AppTextStyles.caption.copyWith(
            color: AppColors.warning, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Walk-in dialog — exported (used by wrapper for both presentations)
// ---------------------------------------------------------------------------

class PlanningWalkInDialog extends ConsumerStatefulWidget {
  final String slotTime;
  final String date;
  final List<MyServiceModel> services;

  const PlanningWalkInDialog({
    super.key,
    required this.slotTime,
    required this.date,
    required this.services,
  });

  @override
  ConsumerState<PlanningWalkInDialog> createState() =>
      _PlanningWalkInDialogState();
}

class _PlanningWalkInDialogState extends ConsumerState<PlanningWalkInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _selectedServiceId;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceId == null) {
      context.showSnackBar(context.l10n.selectServiceRequired, isError: true);
      return;
    }
    final lastName = _lastNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final success = await ref.read(companyPlanningProvider.notifier).addWalkIn(
          date: widget.date,
          startTime: widget.slotTime,
          serviceId: _selectedServiceId!,
          firstName: _firstNameCtrl.text.trim(),
          lastName: lastName.isEmpty ? null : lastName,
          phone: phone.isEmpty ? null : phone,
        );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      context.showSnackBar(context.l10n.walkInSuccess);
    } else {
      final error = ref.read(companyPlanningProvider).error;
      context.showSnackBar(error ?? context.l10n.walkInError, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(
        companyPlanningProvider.select((s) => s.isSubmittingWalkIn));

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_add_rounded,
                      color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${context.l10n.addWalkIn} — ${widget.slotTime}',
                      style: AppTextStyles.h3,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${widget.date}  •  ${widget.slotTime}',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _firstNameCtrl,
                label: context.l10n.clientFirstName,
                hint: 'Arben',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.firstNameRequired
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _lastNameCtrl,
                label: context.l10n.clientLastName,
                hint: 'Krasniqi',
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _phoneCtrl,
                label: context.l10n.clientPhone,
                hint: '044 123 456',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(context.l10n.service, style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              if (widget.services.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: widget.services.map((s) {
                    final isSelected = _selectedServiceId == s.id;
                    return FilterChip(
                      label: Text(s.name),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedServiceId = s.id),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      checkmarkColor: Colors.white,
                      backgroundColor: AppColors.background,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    );
                  }).toList(),
                )
              else
                Text(
                  context.l10n.noServicesConfigured,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint),
                ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(context.l10n.confirm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day off view — exported
// ---------------------------------------------------------------------------

class PlanningDayOffView extends StatelessWidget {
  const PlanningDayOffView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.beach_access_rounded,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.dayOff,
                style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.closed,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error view — exported
// ---------------------------------------------------------------------------

class PlanningErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const PlanningErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(message,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.retry),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private add-at-row button and free-slot tap target
// ---------------------------------------------------------------------------

class _PlanningAddAtRowButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlanningAddAtRowButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.only(top: 6, right: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4), width: 1),
          ),
          child: const Icon(Icons.add_rounded, size: 12, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _PlanningFreeSlotTarget extends StatelessWidget {
  final String time;
  final VoidCallback onTap;
  const _PlanningFreeSlotTarget({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${context.l10n.addWalkIn} $time',
      button: true,
      child: InkWell(onTap: onTap, child: const SizedBox.expand()),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature 4 — No-show client badge
// ---------------------------------------------------------------------------

class _NoShowBadge extends StatelessWidget {
  final int count;

  const _NoShowBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.noShowTooltip(count),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 14,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              context.l10n.noShowBadge(count),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile day stats header — compact pill band above the timeline.
// Shows total + non-zero status chips. Colours match the month dots:
//   • bordeaux — confirmed
//   • amber    — pending
//   • red      — no-show (flags risk)
//   • grey     — cancelled / rejected (neutral)
// ---------------------------------------------------------------------------
class _MobileDayStatsHeader extends StatelessWidget {
  final int total;
  final int confirmed;
  final int pending;
  final int noShow;
  final int cancelled;
  final int rejected;

  const _MobileDayStatsHeader({
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
    if (total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
                height: 1.1,
              ),
              children: [
                TextSpan(text: '$total'),
                TextSpan(
                  text:
                      ' ${total <= 1 ? l.appointmentSingular : l.appointmentPlural}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          const Spacer(),
          Flexible(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: [
                if (confirmed > 0)
                  _MobileDayChip(
                      color: AppColors.primary,
                      count: confirmed,
                      label: l.monthStatConfirmed),
                if (pending > 0)
                  _MobileDayChip(
                      color: AppColors.warning,
                      count: pending,
                      label: l.monthStatPending),
                if (noShow > 0)
                  _MobileDayChip(
                      color: AppColors.textHint,
                      count: noShow,
                      label: l.monthStatNoShow),
                if (cancelled > 0)
                  _MobileDayChip(
                      color: AppColors.textHint,
                      count: cancelled,
                      label: l.monthStatCancelled),
                if (rejected > 0)
                  _MobileDayChip(
                      color: AppColors.textHint,
                      count: rejected,
                      label: l.monthStatRejected),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileDayChip extends StatelessWidget {
  final Color color;
  final int count;
  final String label;

  const _MobileDayChip({
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
          width: 5,
          height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: GoogleFonts.fraunces(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: GoogleFonts.instrumentSans(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Tiny holder for per-range status counts used by the week stats header.
class _StatusCounts {
  final int total;
  final int confirmed;
  final int pending;
  final int noShow;
  final int cancelled;
  final int rejected;
  const _StatusCounts({
    required this.total,
    required this.confirmed,
    required this.pending,
    required this.noShow,
    required this.cancelled,
    required this.rejected,
  });
}
