import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../company/presentation/widgets/cancel_appointment_owner_dialog.dart';
import '../../data/models/schedule_models.dart';
import '../providers/schedule_provider.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';

// ---------------------------------------------------------------------------
// Grid constants
// ---------------------------------------------------------------------------

/// Height in logical pixels for each 15-minute cell.
const double _kRowHeight = 40.0;

/// Width reserved for the time label column (left gutter).
const double _kTimeColumnWidth = 52.0;

// ---------------------------------------------------------------------------
// Time helpers
// ---------------------------------------------------------------------------

/// Parses "HH:mm" into total minutes since midnight.
int _timeToMinutes(String time) {
  final parts = time.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

/// Formats total minutes since midnight back to "HH:mm".
String _minutesToTime(int totalMinutes) {
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// Returns how many 15-minute slots fit in [minutes].
int _slotsFor(int minutes) => (minutes / 15).ceil();

// ---------------------------------------------------------------------------
// Grid row descriptors — built once, rendered by the CustomPaint + Stack.
// ---------------------------------------------------------------------------

/// A single 15-minute band in the grid.
class _GridRow {
  /// Absolute offset in the grid (0 = first row of work day).
  final int index;

  /// Wall-clock time label for this row, e.g. "09:00".
  final String time;

  /// True when this row starts a full hour (0 or 30 min mark → only 0 for
  /// hour lines; 15 and 45 get the subtle tick).
  final bool isHour;

  const _GridRow({
    required this.index,
    required this.time,
    required this.isHour,
  });
}

List<_GridRow> _buildRows(WorkTimeRange work) {
  final startMin = _timeToMinutes(work.startTime);
  final endMin   = _timeToMinutes(work.endTime);
  final count    = _slotsFor(endMin - startMin);

  return List.generate(count, (i) {
    final totalMin = startMin + i * 15;
    return _GridRow(
      index:  i,
      time:   _minutesToTime(totalMin),
      isHour: totalMin % 60 == 0,
    );
  });
}

// ---------------------------------------------------------------------------
// Positioned event descriptors
// ---------------------------------------------------------------------------

class _GridEvent {
  final int startRow;   // inclusive
  final int rowSpan;    // how many 15-min rows this spans
  final _EventType type;
  final ScheduleAppointment? appointment; // null for breaks
  final String? breakLabel;

  const _GridEvent({
    required this.startRow,
    required this.rowSpan,
    required this.type,
    this.appointment,
    this.breakLabel,
  });
}

enum _EventType { appointment, walkIn, breakSlot }

List<_GridEvent> _buildEvents({
  required WorkTimeRange work,
  required List<BreakTimeRange> breaks,
  required List<ScheduleAppointment> appointments,
}) {
  final startMin = _timeToMinutes(work.startTime);
  final events   = <_GridEvent>[];

  for (final appt in appointments) {
    final apptStart = _timeToMinutes(appt.startTime);
    final apptEnd   = _timeToMinutes(appt.endTime);
    final startRow  = (apptStart - startMin) ~/ 15;
    final rowSpan   = _slotsFor(apptEnd - apptStart).clamp(1, 9999);
    events.add(_GridEvent(
      startRow:    startRow,
      rowSpan:     rowSpan,
      type:        appt.isWalkIn ? _EventType.walkIn : _EventType.appointment,
      appointment: appt,
    ));
  }

  for (final brk in breaks) {
    final brkStart = _timeToMinutes(brk.startTime);
    final brkEnd   = _timeToMinutes(brk.endTime);
    final startRow = (brkStart - startMin) ~/ 15;
    final rowSpan  = _slotsFor(brkEnd - brkStart).clamp(1, 9999);
    events.add(_GridEvent(
      startRow:   startRow,
      rowSpan:    rowSpan,
      type:       _EventType.breakSlot,
      breakLabel: brk.label,
    ));
  }

  return events;
}

// ---------------------------------------------------------------------------
// Root screen
// ---------------------------------------------------------------------------

class EmployeeScheduleScreen extends ConsumerStatefulWidget {
  const EmployeeScheduleScreen({super.key});

  @override
  ConsumerState<EmployeeScheduleScreen> createState() =>
      _EmployeeScheduleScreenState();
}

class _EmployeeScheduleScreenState
    extends ConsumerState<EmployeeScheduleScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scheduleProvider.notifier).load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when tab becomes visible (IndexedStack uses TickerMode)
    if (TickerMode.of(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(scheduleProvider.notifier).load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _DateHeader(
              selectedDate: state.selectedDate,
              onPrevious: () =>
                  ref.read(scheduleProvider.notifier).goToPreviousDay(),
              onNext: () =>
                  ref.read(scheduleProvider.notifier).goToNextDay(),
              onPickDate: () => _pickDate(context),
            ),
            Expanded(child: _buildBody(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ScheduleState state) {
    if (state.isLoading && state.schedule == null) {
      return const SkeletonPlanningDay();
    }

    if (state.error != null && state.schedule == null) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => ref.read(scheduleProvider.notifier).load(),
      );
    }

    final schedule = state.schedule;
    if (schedule == null) return const SizedBox.shrink();

    // Day off — no grid, just a centered card.
    if (schedule.isDayOff) {
      return _DayOffView(reason: schedule.dayOffReason);
    }

    final work = schedule.workHours;
    if (work == null) {
      return _DayOffView(reason: schedule.dayOffReason);
    }

    final rows   = _buildRows(work);
    final events = _buildEvents(
      work:         work,
      breaks:       schedule.breaks,
      appointments: schedule.appointments,
    );

    // Always-visible "next appointment" — loaded independently via
    // /my-schedule/upcoming so it keeps pointing at the closest future
    // booking even when the owner browses a past/future day.
    final now = DateTime.now();
    final todayIso =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final nextAppt = state.upcomingAppointment;
    // "Compact" variant when the next appt is on a day different from the
    // currently displayed one — the date badge replaces the verbose copy.
    final isOnViewedDate =
        nextAppt != null && nextAppt.date == state.selectedDate;
    final isOnToday = nextAppt != null && nextAppt.date == todayIso;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(scheduleProvider.notifier).load(),
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

          // Next appointment banner — always visible when there's one.
          // `compact: true` when the appt is on a different day than the
          // currently viewed one → smaller card with the date on display.
          if (nextAppt != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: _NextAppointmentCard(
                  appointment: nextAppt,
                  compact: !isOnViewedDate,
                  isToday: isOnToday,
                ),
              ),
            ),

          // 15-minute timeline grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: _TimelineGrid(
                rows:    rows,
                events:  events,
                workEnd: work.endTime,
                // Red "now" line — only on today. Minutes since midnight so
                // the grid can clamp it to the visible opening range.
                currentTimeMinutes: state.selectedDate == todayIso
                    ? now.hour * 60 + now.minute
                    : null,
                onTapFreeSlot: (time) => _showWalkInDialog(context, time),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final current = DateTime.tryParse(
          ref.read(scheduleProvider).selectedDate,
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
      ref.read(scheduleProvider.notifier).goToDate(picked);
    }
  }

  Future<void> _showWalkInDialog(BuildContext context, String slotTime) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _WalkInDialog(
        slotTime: slotTime,
        date: ref.read(scheduleProvider).selectedDate,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline grid widget
// ---------------------------------------------------------------------------

class _TimelineGrid extends StatefulWidget {
  final List<_GridRow> rows;
  final List<_GridEvent> events;
  final String workEnd;
  final void Function(String time) onTapFreeSlot;

  /// Current time in minutes since midnight for the viewing day. Non-null
  /// only when the grid is showing today — drives the red "now" line.
  final int? currentTimeMinutes;

  const _TimelineGrid({
    required this.rows,
    required this.events,
    required this.workEnd,
    required this.onTapFreeSlot,
    this.currentTimeMinutes,
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
      : widget.events.where((e) => e.appointment?.id == _expandedApptId).firstOrNull;

  double _shiftBelow(int row) {
    final ev = _expandedEvent;
    if (ev == null) return 0;
    return row >= ev.startRow + ev.rowSpan ? _expandedExtra : 0;
  }

  Widget _animated({required double top, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: top),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      builder: (_, t, c) => Positioned(top: t, left: 0, right: 0, child: c!),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final coveredRows = <int>{};
    for (final event in widget.events) {
      for (var i = event.startRow; i < event.startRow + event.rowSpan; i++) {
        coveredRows.add(i);
      }
    }

    final naturalHeight = widget.rows.length * _kRowHeight;
    final totalHeight = naturalHeight + _expandedExtra;

    final expandedEv = _expandedEvent;
    final expandedBottomRow = expandedEv != null
        ? expandedEv.startRow + expandedEv.rowSpan
        : -1;

    // "Now" indicator — clamped to the visible opening range so the line
    // still renders at the top/bottom edge when the current time falls
    // before opening or after closing (otherwise Karim who opens the app
    // at 16:08 while the salon closes at 16:00 would see nothing).
    double? nowTopPx;
    String? nowTimeLabel;
    if (widget.currentTimeMinutes != null && widget.rows.isNotEmpty) {
      final openParts = widget.rows.first.time.split(':');
      final openMin =
          int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
      final closeParts = widget.workEnd.split(':');
      final closeMin =
          int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
      final currentMin = widget.currentTimeMinutes!;
      final clampedMin = currentMin.clamp(openMin, closeMin);
      nowTopPx = (clampedMin - openMin) / 15 * _kRowHeight;
      final h = currentMin ~/ 60;
      final m = currentMin % 60;
      nowTimeLabel =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
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
            width: _kTimeColumnWidth,
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: widget.rows.map((row) {
                final top = row.index * _kRowHeight + _shiftBelow(row.index);
                return _animated(
                  top: top,
                  child: SizedBox(
                    height: _kRowHeight,
                    child: row.isHour
                        ? Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              row.time,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          )
                        : Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              margin: const EdgeInsets.only(top: 8),
                              width: 6,
                              height: 1,
                              color: AppColors.border,
                            ),
                          ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Stack(
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
                    .where((r) => !coveredRows.contains(r.index))
                    .map((row) {
                  final top = row.index * _kRowHeight + _shiftBelow(row.index);
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

                  if (event.type == _EventType.breakSlot) {
                    return _animated(
                      top: naturalTop + shift,
                      child: SizedBox(
                        height: height,
                        child: _BreakCard(
                          label: event.breakLabel,
                          height: height,
                        ),
                      ),
                    );
                  }

                  final appt = event.appointment!;
                  final isExpanded = _expandedApptId == appt.id;

                  return _animated(
                    top: naturalTop + shift,
                    child: _AppointmentCard(
                      expandedDetailKey: isExpanded ? _expandedKey : null,
                      appointment: appt,
                      naturalHeight: height,
                      isExpanded: isExpanded,
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
            ),
          ),
        ],
      ),
          // Red "now" line — spans the full width, positioned at nowTopPx.
          // Rendered above the Row children thanks to the outer Stack.
          if (nowTopPx != null)
            Positioned(
              left: 0,
              right: 0,
              top: nowTopPx - 8,
              child: IgnorePointer(
                child: _ScheduleNowIndicator(time: nowTimeLabel!),
              ),
            ),
        ],
      ),
    );
  }
}

/// Red pill + dot + line showing the current time on the employee's day
/// view. Positioned absolutely inside the timeline Stack so it overlays
/// the grid and appointment cards.
class _ScheduleNowIndicator extends StatelessWidget {
  final String time;
  const _ScheduleNowIndicator({required this.time});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _kTimeColumnWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
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
          ),
          const SizedBox(width: AppSpacing.sm),
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
// Free slot tap area
// ---------------------------------------------------------------------------

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
        // Ink splash stays within the row bounds.
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Break card
// ---------------------------------------------------------------------------

class _BreakCard extends StatelessWidget {
  final String? label;
  final double height;

  const _BreakCard({this.label, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F5),
        border: Border(
          left: BorderSide(
            color: AppColors.textHint.withValues(alpha: 0.5),
            width: 3,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          const Icon(Icons.coffee_rounded, size: 13, color: AppColors.textHint),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label?.isNotEmpty == true ? label! : context.l10n.breakSlot,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Appointment card — tappable, expands to show detail
// ---------------------------------------------------------------------------

class _AppointmentCard extends StatelessWidget {
  final ScheduleAppointment appointment;
  final double naturalHeight;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Key? expandedDetailKey;

  const _AppointmentCard({
    required this.appointment,
    required this.naturalHeight,
    required this.isExpanded,
    required this.onToggle,
    this.expandedDetailKey,
  });

  @override
  Widget build(BuildContext context) {
    final isWalkIn     = appointment.isWalkIn;
    final isCancelled  = appointment.isCancelled;
    // Cancelled / no-show tiles render muted (grey) with strike-through
    // copy so the employee can still see context without the card
    // competing visually with active bookings.
    final accentColor = isCancelled
        ? AppColors.textHint
        : (isWalkIn ? AppColors.warning : AppColors.primary);
    final bgColor = isCancelled
        ? AppColors.divider.withValues(alpha: 0.5)
        : accentColor.withValues(alpha: 0.08);
    final titleColor = isCancelled
        ? AppColors.textHint
        : AppColors.textPrimary;
    final strike = isCancelled ? TextDecoration.lineThrough : null;

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        constraints: BoxConstraints(minHeight: naturalHeight),
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            left: BorderSide(color: accentColor, width: 3),
          ),
          borderRadius: const BorderRadius.only(
            topRight:    Radius.circular(AppSpacing.radiusSm),
            bottomRight: Radius.circular(AppSpacing.radiusSm),
          ),
          boxShadow: isCancelled
              ? []
              : [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header row ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          appointment.clientFullName,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                            decoration: strike,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isWalkIn && !isCancelled) ...[
                        const SizedBox(width: AppSpacing.xs),
                        _WalkInBadge(),
                      ],
                      if (isCancelled) ...[
                        const SizedBox(width: AppSpacing.xs),
                        _CancelledBadge(
                          isNoShow: appointment.status == 'no_show',
                        ),
                      ],
                    ],
                  ),
                ),
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
            ),

            // ── Service + time summary ──────────────────────────────────
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.content_cut_rounded, size: 11, color: accentColor),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    appointment.serviceName,
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

            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _AppointmentDetail(
                key: expandedDetailKey,
                appointment: appointment,
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
// Expanded appointment detail
// ---------------------------------------------------------------------------

class _AppointmentDetail extends ConsumerWidget {
  final ScheduleAppointment appointment;

  const _AppointmentDetail({super.key, required this.appointment});

  Future<void> _onCancelTap(BuildContext context, WidgetRef ref) async {
    final result = await showCancelAppointmentOwnerDialog(
      context,
      clientName: appointment.clientFullName.isEmpty
          ? '—'
          : appointment.clientFullName,
      // Walk-ins have no backing user account — nobody to notify, so the
      // dialog skips the "client will be notified" warning line.
      isWalkIn: appointment.isWalkIn,
    );
    if (result == null || !result.confirmed) return;
    if (!context.mounted) return;

    final ok = await ref
        .read(scheduleProvider.notifier)
        .cancelAppointment(appointment.id, reason: result.reason);

    if (!context.mounted) return;
    if (!ok) {
      final error = ref.read(scheduleProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? context.l10n.error)),
      );
    }
  }

  Future<void> _onNoShowTap(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(scheduleProvider.notifier)
        .markNoShow(appointment.id);
    if (!context.mounted) return;
    if (!ok) {
      final error = ref.read(scheduleProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? context.l10n.error)),
      );
    }
  }

  /// Computes whether this appointment has started AND the no-show window
  /// (backend: 24h) is still open. The employee can mark no-show only
  /// within that window, so we hide the button outside of it.
  ({bool isPast, bool canMarkNoShow}) _timingFlags(WidgetRef ref) {
    final dateStr = appointment.date ??
        ref.read(scheduleProvider).selectedDate;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return (isPast: false, canMarkNoShow: false);
    final parts = appointment.startTime.split(':');
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    final now = DateTime.now();
    final isPast = start.isBefore(now);
    final canMarkNoShow =
        isPast && now.difference(start).inHours < 24;
    return (isPast: isPast, canMarkNoShow: canMarkNoShow);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timing = _timingFlags(ref);
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
              '${appointment.serviceName}  •  ${appointment.durationMinutes} min  •  ${appointment.price.toStringAsFixed(0)} €',
        ),
        // Action button — live bookings only. Aligned left with a capped
        // width so it doesn't span the whole card on desktop.
        //   * Upcoming            → "Annuler le RDV" (rouge)
        //   * Past + within 24h   → "Marquer absent" (orange)
        //   * Past outside 24h    → no action (can't cancel past anymore)
        //   * Already cancelled   → no action
        if (!appointment.isCancelled && !timing.isPast) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.50),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                onPressed: () => _onCancelTap(context, ref),
                icon: const Icon(Icons.event_busy_rounded, size: 16),
                label: Text(
                  context.l10n.cancelAppointment,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        ] else if (!appointment.isCancelled &&
            timing.isPast &&
            timing.canMarkNoShow) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: BorderSide(
                    color: AppColors.warning.withValues(alpha: 0.50),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                onPressed: () => _onNoShowTap(context, ref),
                icon: const Icon(Icons.person_off_outlined, size: 16),
                label: Text(
                  context.l10n.markNoShow,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
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

// ---------------------------------------------------------------------------
// "Sans RDV" badge
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

class _CancelledBadge extends StatelessWidget {
  final bool isNoShow;
  const _CancelledBadge({required this.isNoShow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.textHint.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.textHint.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        isNoShow
            ? context.l10n.appointmentNoShow
            : context.l10n.appointmentCancelled,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textHint,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Next appointment highlight card
// ---------------------------------------------------------------------------

class _NextAppointmentCard extends StatelessWidget {
  final ScheduleAppointment appointment;

  /// `true` when the appointment is NOT on the currently displayed day —
  /// render a smaller horizontal layout and surface the date badge so the
  /// owner knows it's coming from another day.
  final bool compact;

  /// Whether the appointment's date matches the real "today" (not just the
  /// currently viewed day). Changes the date-badge copy to "Today" / "Tomorrow".
  final bool isToday;

  const _NextAppointmentCard({
    required this.appointment,
    this.compact = false,
    this.isToday = false,
  });

  String _formatDateBadge(BuildContext context) {
    final l = context.l10n;
    final now = DateTime.now();
    final date = DateTime.tryParse(appointment.date ?? '');
    if (date == null) return '';
    if (isToday) return l.todayLabel;
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final isTomorrow = date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
    if (isTomorrow) return l.tomorrowLabel;
    final months = [
      l.monthShortJan, l.monthShortFeb, l.monthShortMar, l.monthShortApr,
      l.monthShortMay, l.monthShortJun, l.monthShortJul, l.monthShortAug,
      l.monthShortSep, l.monthShortOct, l.monthShortNov, l.monthShortDec,
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final child = compact ? _buildCompact(context) : _buildFull(context);
    // Wrap the whole card in a tappable surface so the owner can reveal
    // the client's phone (and place a call) without needing to navigate
    // to the appointment's row in the grid.
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(
        compact ? AppSpacing.radiusMd : AppSpacing.radiusLg,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetailSheet(context),
        child: child,
      ),
    );
  }

  Future<void> _showDetailSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _NextAppointmentDetailSheet(
        appointment: appointment,
        dateBadge: _formatDateBadge(context),
        compact: compact,
        isToday: isToday,
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final dateBadge = _formatDateBadge(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_available_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
                children: [
                  TextSpan(
                    text: '${context.l10n.nextAppointment} · ',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                      letterSpacing: 0.2,
                    ),
                  ),
                  TextSpan(
                    text: appointment.clientFullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Date pill — e.g. "Demain" / "23 avr.".
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              dateBadge,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            appointment.startTime,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.nextAppointment,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appointment.clientFullName,
                  style: AppTextStyles.subtitle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appointment.serviceName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              appointment.startTime,
              style: AppTextStyles.subtitle.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet opened when the owner taps the "next appointment" card.
/// Surfaces the phone number (tap to call via `tel:`) and a little bit more
/// context than the teaser card could show.
class _NextAppointmentDetailSheet extends StatelessWidget {
  final ScheduleAppointment appointment;
  final String dateBadge;
  final bool compact;
  final bool isToday;

  const _NextAppointmentDetailSheet({
    required this.appointment,
    required this.dateBadge,
    required this.compact,
    required this.isToday,
  });

  Future<void> _dial(BuildContext context, String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleaned');
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(phone)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hasPhone = appointment.clientPhone != null &&
        appointment.clientPhone!.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Header — time + date pill
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.nextAppointment,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textHint),
                      ),
                      Row(
                        children: [
                          Text(
                            appointment.startTime,
                            style: AppTextStyles.h3,
                          ),
                          const SizedBox(width: 8),
                          if (dateBadge.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                dateBadge,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppSpacing.md),

            // Client
            _DetailRow(
              icon: Icons.person_rounded,
              label: appointment.clientFullName.isEmpty
                  ? '—'
                  : appointment.clientFullName,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Service
            _DetailRow(
              icon: Icons.content_cut_rounded,
              label:
                  '${appointment.serviceName}  •  ${appointment.durationMinutes} min  •  ${appointment.price.toStringAsFixed(0)} €',
            ),

            const SizedBox(height: AppSpacing.lg),

            // Phone — tappable row / disabled placeholder when missing
            if (hasPhone)
              InkWell(
                onTap: () => _dial(context, appointment.clientPhone!),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          appointment.clientPhone!,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.phone_forwarded_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_disabled_rounded,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l.noPhoneAvailable,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day off view
// ---------------------------------------------------------------------------

class _DayOffView extends StatelessWidget {
  final String? reason;

  const _DayOffView({this.reason});

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
              reason?.isNotEmpty == true
                  ? reason!
                  : context.l10n.youDontWorkToday,
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
// Date header with previous / next navigation
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
    final date    = DateTime.tryParse(selectedDate) ?? DateTime.now();
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
// Walk-in dialog
// ---------------------------------------------------------------------------

class _WalkInDialog extends ConsumerStatefulWidget {
  final String slotTime;
  final String date;

  const _WalkInDialog({required this.slotTime, required this.date});

  @override
  ConsumerState<_WalkInDialog> createState() => _WalkInDialogState();
}

class _WalkInDialogState extends ConsumerState<_WalkInDialog> {
  final _formKey        = GlobalKey<FormState>();
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _phoneCtrl      = TextEditingController();

  String? _selectedServiceId;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  List<_ServiceOption> _availableServices() {
    return ref
        .read(scheduleProvider)
        .services
        .map((s) => _ServiceOption(id: s.id, name: s.name))
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceId == null) {
      context.showSnackBar(context.l10n.selectServiceRequired, isError: true);
      return;
    }

    final request = WalkInRequest(
      time:            widget.slotTime,
      date:            widget.date,
      clientFirstName: _firstNameCtrl.text.trim(),
      clientLastName:  _lastNameCtrl.text.trim().isEmpty
          ? null
          : _lastNameCtrl.text.trim(),
      clientPhone: _phoneCtrl.text.trim().isEmpty
          ? null
          : _phoneCtrl.text.trim(),
      serviceId: _selectedServiceId!,
    );

    final success =
        await ref.read(scheduleProvider.notifier).addWalkIn(request);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      context.showSnackBar(context.l10n.walkInSuccess);
    } else {
      final error = ref.read(scheduleProvider).error;
      context.showSnackBar(error ?? context.l10n.walkInError, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        ref.watch(scheduleProvider.select((s) => s.isSubmittingWalkIn));
    final services = _availableServices();

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
              // Header
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
              const SizedBox(height: AppSpacing.md),

              // First name — required
              AppTextField(
                controller: _firstNameCtrl,
                label: context.l10n.clientFirstName,
                hint: 'Ex: Arben',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.firstNameRequired
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Last name — optional
              AppTextField(
                controller: _lastNameCtrl,
                label: context.l10n.clientLastName,
                hint: 'Ex: Krasniqi',
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Phone — optional
              AppTextField(
                controller: _phoneCtrl,
                label: context.l10n.clientPhone,
                hint: '044 123 456',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Service chips
              Text(context.l10n.service, style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              if (services.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: services.map((s) {
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

              // Confirm button
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

class _ServiceOption {
  final String id;
  final String name;
  const _ServiceOption({required this.id, required this.name});
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
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
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
