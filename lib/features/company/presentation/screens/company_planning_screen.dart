import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/my_company_model.dart';
import '../../data/models/planning_appointment_model.dart';
import '../providers/company_dashboard_provider.dart';
import '../providers/company_planning_provider.dart';

// ---------------------------------------------------------------------------
// Grid constants (copied from employee_schedule_screen.dart)
// ---------------------------------------------------------------------------

const double _kRowHeight = 40.0;
const double _kTimeColumnWidth = 52.0;

// ---------------------------------------------------------------------------
// Time helpers
// ---------------------------------------------------------------------------

int _timeToMinutes(String time) {
  final parts = time.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

String _minutesToTime(int totalMinutes) {
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

int _slotsFor(int minutes) => (minutes / 15).ceil();

// ---------------------------------------------------------------------------
// Grid row descriptors
// ---------------------------------------------------------------------------

class _GridRow {
  final int index;
  final String time;
  final bool isHour;

  const _GridRow({
    required this.index,
    required this.time,
    required this.isHour,
  });
}

List<_GridRow> _buildRows(OpeningHourModel hours) {
  final startMin = _timeToMinutes(hours.openTime!);
  final endMin = _timeToMinutes(hours.closeTime!);
  final count = _slotsFor(endMin - startMin);

  return List.generate(count, (i) {
    final totalMin = startMin + i * 15;
    return _GridRow(
      index: i,
      time: _minutesToTime(totalMin),
      isHour: totalMin % 60 == 0,
    );
  });
}

// ---------------------------------------------------------------------------
// Positioned event descriptors
// ---------------------------------------------------------------------------

class _GridEvent {
  final int startRow;
  final int rowSpan;
  final PlanningAppointmentModel appointment;
  final int laneIndex;
  final int laneCount;

  const _GridEvent({
    required this.startRow,
    required this.rowSpan,
    required this.appointment,
    this.laneIndex = 0,
    this.laneCount = 1,
  });
}

/// Assigns lane indices to events so overlapping events render side-by-side.
/// Sort: startRow asc, rowSpan desc.  Then greedy lane assignment O(n²).
List<_GridEvent> _assignLanes(List<_GridEvent> raw) {
  if (raw.isEmpty) return raw;

  final sorted = [...raw]
    ..sort((a, b) {
      final s = a.startRow.compareTo(b.startRow);
      return s != 0 ? s : b.rowSpan.compareTo(a.rowSpan);
    });

  final laneIndices = List<int>.filled(sorted.length, 0);
  // laneEndRow[lane] = exclusive end row of the last event occupying that lane
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

  // Compute laneCount for each event: how many events share any row with it.
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
    return _GridEvent(
      startRow: ev.startRow,
      rowSpan: ev.rowSpan,
      appointment: ev.appointment,
      laneIndex: laneIndices[i],
      laneCount: counts[i],
    );
  });
}

List<_GridEvent> _buildEvents({
  required OpeningHourModel hours,
  required List<PlanningAppointmentModel> appointments,
}) {
  final startMin = _timeToMinutes(hours.openTime!);
  final events = <_GridEvent>[];

  for (final appt in appointments) {
    final apptStart = _timeToMinutes(appt.startTime);
    final apptEnd = _timeToMinutes(appt.endTime);
    final startRow = (apptStart - startMin) ~/ 15;
    final rowSpan = _slotsFor(apptEnd - apptStart).clamp(1, 9999);
    events.add(_GridEvent(
      startRow: startRow,
      rowSpan: rowSpan,
      appointment: appt,
    ));
  }

  return _assignLanes(events);
}

// ---------------------------------------------------------------------------
// Root screen
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
      ref.read(companyPlanningProvider.notifier).load();
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyPlanningProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _DateHeader(
              selectedDate: state.selectedDate,
              onPrevious: () =>
                  ref.read(companyPlanningProvider.notifier).goToPreviousDay(),
              onNext: () =>
                  ref.read(companyPlanningProvider.notifier).goToNextDay(),
              onPickDate: () => _pickDate(context),
            ),
            Expanded(child: _buildBody(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CompanyPlanningState state) {
    final companyState = ref.watch(companyDashboardProvider);

    if (state.isLoading && state.appointments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null && state.appointments.isEmpty) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => ref.read(companyPlanningProvider.notifier).load(),
      );
    }

    final company = companyState.company;
    if (company == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
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
      return _DayOffView();
    }

    final rows = _buildRows(todayHours);
    final events = _buildEvents(
      hours: todayHours,
      appointments: state.appointments,
    );

    final services = company.categories
        .expand((c) => c.services)
        .toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(companyPlanningProvider.notifier).load(),
      child: CustomScrollView(
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: _TimelineGrid(
                rows: rows,
                events: events,
                workEnd: todayHours.closeTime!,
                services: services,
                onTapFreeSlot: (time) => _showWalkInDialog(context, time, services),
                isTimeInPast: (time) {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  if (selectedDate.isBefore(today)) return true;
                  if (selectedDate.isAfter(today)) return false;
                  final parts = time.split(':');
                  final slotMinutes =
                      int.parse(parts[0]) * 60 + int.parse(parts[1]);
                  final nowMinutes = now.hour * 60 + now.minute;
                  return slotMinutes <= nowMinutes;
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  Future<void> _showWalkInDialog(
    BuildContext context,
    String slotTime,
    List<MyServiceModel> services,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _CompanyWalkInDialog(
        slotTime: slotTime,
        date: ref.read(companyPlanningProvider).selectedDate,
        services: services,
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final current = DateTime.tryParse(
          ref.read(companyPlanningProvider).selectedDate,
        ) ??
        DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      ref.read(companyPlanningProvider.notifier).setDate(picked);
    }
  }
}

// ---------------------------------------------------------------------------
// Timeline grid widget
// ---------------------------------------------------------------------------

class _TimelineGrid extends StatefulWidget {
  final List<_GridRow> rows;
  final List<_GridEvent> events;
  final String workEnd;
  final List<MyServiceModel> services;
  final void Function(String time) onTapFreeSlot;
  final bool Function(String time) isTimeInPast;

  const _TimelineGrid({
    required this.rows,
    required this.events,
    required this.workEnd,
    required this.services,
    required this.onTapFreeSlot,
    required this.isTimeInPast,
  });

  @override
  State<_TimelineGrid> createState() => _TimelineGridState();
}

class _TimelineGridState extends State<_TimelineGrid> {
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
      if (detailH != _expandedExtra) {
        setState(() => _expandedExtra = detailH);
      }
    });
  }

  _GridEvent? get _expandedEvent => _expandedApptId == null
      ? null
      : widget.events
          .where((e) => e.appointment.id == _expandedApptId)
          .cast<_GridEvent?>()
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
            top: t,
            left: left,
            width: width,
            height: height,
            child: c!,
          );
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

    final naturalHeight = widget.rows.length * _kRowHeight;
    final totalHeight = naturalHeight + _expandedExtra;

    final expandedEv = _expandedEvent;
    final expandedBottomRow =
        expandedEv != null ? expandedEv.startRow + expandedEv.rowSpan : -1;

    return SizedBox(
      height: totalHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _kTimeColumnWidth,
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: widget.rows.map((row) {
                final top =
                    row.index * _kRowHeight + _shiftBelow(row.index);
                final hasEvent = coveredRows.contains(row.index);
                return _animated(
                  top: top,
                  child: SizedBox(
                    height: _kRowHeight,
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
                          _AddAtRowButton(
                            onTap: () =>
                                widget.onTapFreeSlot(row.time),
                          ),
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
                      painter: _GridLinePainter(
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
                      final top =
                          row.index * _kRowHeight + _shiftBelow(row.index);
                      return _animated(
                        top: top,
                        child: SizedBox(
                          height: _kRowHeight,
                          child: _FreeSlotTapTarget(
                            time: row.time,
                            onTap: () => widget.onTapFreeSlot(row.time),
                          ),
                        ),
                      );
                    }),

                    ...widget.events.map((event) {
                      final naturalTop = event.startRow * _kRowHeight;
                      final height = event.rowSpan * _kRowHeight;
                      final shift = _shiftBelow(event.startRow);
                      final appt = event.appointment;
                      final isExpanded = _expandedApptId == appt.id;

                      const gutter = 2.0;
                      const vInset = 3.0;
                      final laneWidth =
                          (totalWidth - gutter * (event.laneCount - 1)) /
                              event.laneCount;
                      final laneLeft =
                          event.laneIndex * (laneWidth + gutter);

                      return _animated(
                        top: naturalTop + shift + vInset,
                        left: laneLeft,
                        width: laneWidth,
                        height: isExpanded ? null : height - vInset * 2,
                        child: _PlanningAppointmentCard(
                          expandedDetailKey: isExpanded ? _expandedKey : null,
                          appointment: appt,
                          naturalHeight: height - vInset * 2,
                          isExpanded: isExpanded,
                          laneCount: event.laneCount,
                          onToggle: () {
                            setState(() {
                              _expandedApptId = isExpanded ? null : appt.id;
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
    );
  }
}

// ---------------------------------------------------------------------------
// Grid line painter
// ---------------------------------------------------------------------------

class _GridLinePainter extends CustomPainter {
  final int rowCount;
  final int expandedBottomRow;
  final double expandedExtra;

  const _GridLinePainter({
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
      final shift = (expandedExtra > 0 && i >= expandedBottomRow)
          ? expandedExtra
          : 0.0;
      final y = i * _kRowHeight + shift;
      final paint = (i % 4 == 0) ? hourPaint : quarterPaint;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final finalShift = expandedExtra > 0 ? expandedExtra : 0.0;
    canvas.drawLine(
      Offset(0, rowCount * _kRowHeight + finalShift),
      Offset(size.width, rowCount * _kRowHeight + finalShift),
      hourPaint,
    );
  }

  @override
  bool shouldRepaint(_GridLinePainter old) =>
      old.rowCount != rowCount ||
      old.expandedBottomRow != expandedBottomRow ||
      old.expandedExtra != expandedExtra;
}

// ---------------------------------------------------------------------------
// Appointment card — color-coded by status, expands on tap
// ---------------------------------------------------------------------------

class _PlanningAppointmentCard extends StatelessWidget {
  final PlanningAppointmentModel appointment;
  final double naturalHeight;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Key? expandedDetailKey;
  final int laneCount;

  const _PlanningAppointmentCard({
    required this.appointment,
    required this.naturalHeight,
    required this.isExpanded,
    required this.onToggle,
    this.expandedDetailKey,
    this.laneCount = 1,
  });

  Color get _accentColor {
    switch (appointment.status) {
      case 'confirmed':
        return AppColors.primary;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textHint;
    }
  }

  void _showMobileDetail(BuildContext context, PlanningAppointmentModel appt) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => _AppointmentDetailSheet(appointment: appt),
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
      onTap: isMobile
          ? () => _showMobileDetail(context, appointment)
          : onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        constraints: BoxConstraints(minHeight: naturalHeight),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            left: BorderSide(color: accentColor, width: 3),
          ),
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
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
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
                    _WalkInBadge(),
                  ],
                  if (laneCount == 1) ...[
                    const SizedBox(width: AppSpacing.xs),
                    _StatusBadge(status: appointment.status),
                  ],
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
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
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
              secondChild: _AppointmentDetail(
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
// Mobile bottom sheet detail
// ---------------------------------------------------------------------------

class _AppointmentDetailSheet extends ConsumerStatefulWidget {
  final PlanningAppointmentModel appointment;

  const _AppointmentDetailSheet({required this.appointment});

  @override
  ConsumerState<_AppointmentDetailSheet> createState() =>
      _AppointmentDetailSheetState();
}

class _AppointmentDetailSheetState
    extends ConsumerState<_AppointmentDetailSheet> {
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
        SnackBar(content: Text(context.l10n.actionFailed)),
      );
    }
  }

  Future<void> _reject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.confirmRejectTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.l10n.rejectAppointment,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    setState(() => _loading = true);
    final ok = await ref
        .read(companyPlanningProvider.notifier)
        .rejectAppointment(appt.id);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.actionFailed)),
      );
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.confirmCancelTitle),
        content: Text(context.l10n.cancelAppointmentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.l10n.cancelAppointment,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    setState(() => _loading = true);
    final ok = await ref
        .read(companyPlanningProvider.notifier)
        .cancelAppointment(appt.id);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.actionFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
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
                      child: Text(
                        appt.clientFullName,
                        style: AppTextStyles.h3.copyWith(fontSize: 18),
                      ),
                    ),
                    if (appt.isWalkIn) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _WalkInBadge(),
                    ],
                    const SizedBox(width: AppSpacing.xs),
                    _StatusBadge(status: appt.status),
                  ],
                ),
                const Divider(height: AppSpacing.lg, color: AppColors.divider),
                _DetailRow(
                  icon: Icons.content_cut_rounded,
                  label:
                      '${appt.service.name}  •  ${appt.service.durationMinutes} min  •  ${appt.service.price.toStringAsFixed(0)} €',
                ),
                const SizedBox(height: AppSpacing.xs),
                _DetailRow(
                  icon: Icons.event_rounded,
                  label: '${appt.startTime} – ${appt.endTime}',
                ),
                if (appt.clientPhone != null &&
                    appt.clientPhone!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _SheetPhoneRow(phone: appt.clientPhone!),
                ],
                const SizedBox(height: AppSpacing.md),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                else if (appt.status == 'pending') ...[
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
// Expanded detail
// ---------------------------------------------------------------------------

class _AppointmentDetail extends ConsumerWidget {
  final PlanningAppointmentModel appointment;
  final Color accentColor;

  const _AppointmentDetail({
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
        SnackBar(content: Text(context.l10n.actionFailed)),
      );
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.confirmRejectTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.l10n.rejectAppointment,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final ok = await ref
        .read(companyPlanningProvider.notifier)
        .rejectAppointment(appointment.id);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.actionFailed)),
      );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.confirmCancelTitle),
        content: Text(context.l10n.cancelAppointmentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.l10n.cancelAppointment,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final ok = await ref
        .read(companyPlanningProvider.notifier)
        .cancelAppointment(appointment.id);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.actionFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: AppSpacing.md, color: AppColors.divider),
        _DetailRow(
          icon: Icons.person_rounded,
          label: appointment.clientFullName,
        ),
        if (appointment.clientPhone != null &&
            appointment.clientPhone!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          _PhoneRow(phone: appointment.clientPhone!),
        ],
        const SizedBox(height: AppSpacing.xs),
        _DetailRow(
          icon: Icons.content_cut_rounded,
          label:
              '${appointment.service.name}  •  ${appointment.service.durationMinutes} min  •  ${appointment.service.price.toStringAsFixed(0)} €',
        ),
        if (appointment.status == 'pending') ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reject(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  ),
                  child: Text(context.l10n.confirmAppointment),
                ),
              ),
            ],
          ),
        ] else if (appointment.status == 'confirmed') ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _cancel(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              ),
              child: Text(context.l10n.cancel),
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(label, style: AppTextStyles.bodySmall),
        ),
      ],
    );
  }
}

class _SheetPhoneRow extends StatelessWidget {
  final String phone;

  const _SheetPhoneRow({required this.phone});

  Future<void> _dialPhone(BuildContext context) async {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleaned');
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(phone)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _dialPhone(context),
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
            child: const Icon(
              Icons.phone_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  final String phone;

  const _PhoneRow({required this.phone});

  Future<void> _dialPhone(BuildContext context) async {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleaned');
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(phone)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _dialPhone(context),
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
          const Icon(Icons.phone_forwarded_rounded, size: 11, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

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
      default:
        color = AppColors.textHint;
        label = context.l10n.appointmentCancelled;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Walk-in badge
// ---------------------------------------------------------------------------

class _WalkInBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        context.l10n.walkIn,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Free slot tap area
// ---------------------------------------------------------------------------

class _AddAtRowButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddAtRowButton({required this.onTap});

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
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.add_rounded,
            size: 12,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _FreeSlotTapTarget extends StatelessWidget {
  final String time;
  final VoidCallback onTap;

  const _FreeSlotTapTarget({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${context.l10n.addWalkIn} $time',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Walk-in dialog (company owner, no employee picker)
// ---------------------------------------------------------------------------

class _CompanyWalkInDialog extends ConsumerStatefulWidget {
  final String slotTime;
  final String date;
  final List<MyServiceModel> services;

  const _CompanyWalkInDialog({
    required this.slotTime,
    required this.date,
    required this.services,
  });

  @override
  ConsumerState<_CompanyWalkInDialog> createState() =>
      _CompanyWalkInDialogState();
}

class _CompanyWalkInDialogState extends ConsumerState<_CompanyWalkInDialog> {
  final _formKey       = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _phoneCtrl     = TextEditingController();

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
    final phone    = _phoneCtrl.text.trim();

    final success = await ref.read(companyPlanningProvider.notifier).addWalkIn(
      date:      widget.date,
      startTime: widget.slotTime,
      serviceId: _selectedServiceId!,
      firstName: _firstNameCtrl.text.trim(),
      lastName:  lastName.isEmpty ? null : lastName,
      phone:     phone.isEmpty    ? null : phone,
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
      companyPlanningProvider.select((s) => s.isSubmittingWalkIn),
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
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
                  const Icon(Icons.person_add_rounded, color: AppColors.primary),
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
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
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
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
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
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      checkmarkColor: Colors.white,
                      backgroundColor: AppColors.background,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
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
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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
// Day off view
// ---------------------------------------------------------------------------

class _DayOffView extends StatelessWidget {
  const _DayOffView();

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
              child: const Icon(
                Icons.beach_access_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.dayOff,
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.closed,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date header (identical to employee_schedule_screen.dart _DateHeader)
// ---------------------------------------------------------------------------

class _DateHeader extends StatelessWidget {
  final String selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickDate;

  const _DateHeader({
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(selectedDate) ?? DateTime.now();
    final isToday = _isSameDay(date, DateTime.now());

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
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
                      Text(_formatDate(context, date), style: AppTextStyles.h3),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
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

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ---------------------------------------------------------------------------
// Error view
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

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
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
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
