import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';

/// Row descriptor for the pending-approvals list: either a day header
/// or an appointment tile payload. Keeps the ListView.builder simple and
/// avoids nesting a ListView per group.
class PendingRow {
  final bool isHeader;
  final String? date;
  final Map<String, dynamic>? appointment;

  const PendingRow._(this.isHeader, this.date, this.appointment);
  factory PendingRow.header(String date) => PendingRow._(true, date, null);
  factory PendingRow.appointment(Map<String, dynamic> a) =>
      PendingRow._(false, null, a);
}

/// Groups raw pending appointments by their `date` field (YYYY-MM-DD).
/// Both dates and per-day items are sorted ASC so the next actionable slot
/// rises to the top.
List<MapEntry<String, List<Map<String, dynamic>>>> groupPendingByDate(
  List<Map<String, dynamic>> items,
) {
  final map = <String, List<Map<String, dynamic>>>{};
  for (final a in items) {
    final d = (a['date'] as String?) ?? '';
    if (d.isEmpty) continue;
    map.putIfAbsent(d, () => []).add(a);
  }
  for (final list in map.values) {
    list.sort((a, b) {
      final at = (a['startTime'] as String?) ?? '';
      final bt = (b['startTime'] as String?) ?? '';
      return at.compareTo(bt);
    });
  }
  final sorted = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return sorted;
}

/// Editorial section header — overline "LUN. 21 AVR" Fraunces letterSpacing
/// with a thin rule to the right. Localises via context.l10n.
class PendingDayHeader extends StatelessWidget {
  final String date;
  const PendingDayHeader({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(date);
    final l = context.l10n;
    String label;
    if (dt == null) {
      label = date;
    } else {
      final today = DateTime.now();
      final isToday = dt.year == today.year &&
          dt.month == today.month &&
          dt.day == today.day;
      final tomorrow = today.add(const Duration(days: 1));
      final isTomorrow = dt.year == tomorrow.year &&
          dt.month == tomorrow.month &&
          dt.day == tomorrow.day;

      final dayShorts = [
        l.dayShortMon,
        l.dayShortTue,
        l.dayShortWed,
        l.dayShortThu,
        l.dayShortFri,
        l.dayShortSat,
        l.dayShortSun,
      ];
      final monthShorts = [
        l.monthShortJan,
        l.monthShortFeb,
        l.monthShortMar,
        l.monthShortApr,
        l.monthShortMay,
        l.monthShortJun,
        l.monthShortJul,
        l.monthShortAug,
        l.monthShortSep,
        l.monthShortOct,
        l.monthShortNov,
        l.monthShortDec,
      ];

      final base =
          '${dayShorts[dt.weekday - 1]} ${dt.day} ${monthShorts[dt.month - 1]}';
      label = isToday
          ? '${l.today.toUpperCase()}  ·  $base'
          : isTomorrow
              ? '${l.tomorrow.toUpperCase()}  ·  $base'
              : base;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.fraunces(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.2,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(height: 1, color: AppColors.divider),
        ),
      ],
    );
  }

}
