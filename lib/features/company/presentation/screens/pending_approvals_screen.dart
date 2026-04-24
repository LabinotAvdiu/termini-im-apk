import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../shell/presentation/providers/shell_nav_provider.dart';
import '../../data/datasources/my_company_remote_datasource.dart';
import '../providers/company_dashboard_provider.dart';
import '../providers/pending_count_provider.dart';
import '../widgets/pending_day_helpers.dart';
import '../widgets/reject_appointment_dialog.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _PendingState {
  final List<Map<String, dynamic>> appointments;
  final bool isLoading;
  final String? error;

  const _PendingState({
    this.appointments = const [],
    this.isLoading = false,
    this.error,
  });

  _PendingState copyWith({
    List<Map<String, dynamic>>? appointments,
    bool? isLoading,
    String? error,
  }) =>
      _PendingState(
        appointments: appointments ?? this.appointments,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class _PendingNotifier extends StateNotifier<_PendingState> {
  final MyCompanyRemoteDatasource _datasource;

  _PendingNotifier(this._datasource) : super(const _PendingState());

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      final list = await _datasource.getPendingAppointments();
      if (!mounted) return;
      state = state.copyWith(appointments: list, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateStatus(String id, String status, {String? reason}) async {
    if (!mounted) return;
    final previous = state.appointments
        .map((a) => a['id'].toString() == id
            ? {...a, 'status': status}
            : a)
        .toList();
    state = state.copyWith(appointments: previous);

    try {
      await _datasource.updateAppointmentStatus(id, status, reason: reason);
      if (!mounted) return;
      if (status == 'confirmed' || status == 'rejected') {
        state = state.copyWith(
          appointments: state.appointments
              .where((a) => a['id'].toString() != id)
              .toList(),
        );
      }
    } catch (_) {
      if (!mounted) return;
      await load();
    }
  }
}

final _pendingProvider =
    StateNotifierProvider.autoDispose<_PendingNotifier, _PendingState>(
  (ref) => _PendingNotifier(ref.watch(myCompanyDatasourceProvider)),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class PendingApprovalsScreen extends ConsumerStatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  ConsumerState<PendingApprovalsScreen> createState() =>
      _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState
    extends ConsumerState<PendingApprovalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_pendingProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_pendingProvider);
    final dashboardState = ref.watch(companyDashboardProvider);
    final company = dashboardState.company;

    // When auto-approve is on for a capacity_based salon, appointments go
    // straight to confirmed — the pending list is always empty by design.
    // Show the editorial empty state instead of a real empty list so the
    // owner understands why there's nothing here. We do NOT hide the menu
    // item — navigation stays consistent.
    final isAutoApproveActive = company != null &&
        company.bookingMode == 'capacity_based' &&
        company.capacityAutoApprove;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar.standard(title: context.l10n.pendingApprovals),
      body: isAutoApproveActive
          ? _AutoApproveEmptyView(
              onEditSetting: () => ref
                  .read(shellNavProvider.notifier)
                  .request(ShellTab.salon, scrollTo: 'autoApprove'),
            )
          : state.isLoading
          ? const SkeletonPendingApprovals()
          : Builder(
              builder: (context) {
                // Drop appointments whose start time has already passed — the
                // owner can't usefully approve/reject a slot that's over.
                final visible = state.appointments
                    .where((a) => !_isAppointmentPast(a))
                    .toList();

                // Group by calendar day. Each bucket's items are sorted by
                // startTime ASC; buckets themselves are sorted by date ASC
                // so the next slot to decide on rises to the top.
                final groups = groupPendingByDate(visible);

                // Flatten into a (header, ...items) render list so a single
                // ListView.builder handles layout + separators.
                final rows = <PendingRow>[];
                for (final entry in groups) {
                  rows.add(PendingRow.header(entry.key));
                  for (final appt in entry.value) {
                    rows.add(PendingRow.appointment(appt));
                  }
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: () => ref.read(_pendingProvider.notifier).load(),
                  child: rows.isEmpty
                      ? _EmptyView()
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: rows.length,
                              itemBuilder: (context, index) {
                                final row = rows[index];
                                if (row.isHeader) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      top: index == 0 ? 0 : AppSpacing.lg,
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: PendingDayHeader(date: row.date!),
                                  );
                                }
                                final appt = row.appointment!;
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm),
                                  child: _AppointmentTile(
                                    appointment: appt,
                                    onApprove: () {
                                      ref
                                          .read(_pendingProvider.notifier)
                                          .updateStatus(
                                              appt['id'].toString(),
                                              'confirmed')
                                          .then((_) => ref
                                              .read(pendingCountProvider
                                                  .notifier)
                                              .refresh());
                                    },
                                    onReject: (reason) {
                                      ref
                                          .read(_pendingProvider.notifier)
                                          .updateStatus(
                                              appt['id'].toString(),
                                              'rejected',
                                              reason: reason)
                                          .then((_) => ref
                                              .read(pendingCountProvider
                                                  .notifier)
                                              .refresh());
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                );
              },
            ),
    );
  }
}

/// Helper used by the pending-approvals list to detect past appointments
/// (by combining the raw API `date` + `startTime`).
bool _isAppointmentPast(Map<String, dynamic> a) {
  final date = a['date'] as String?;
  final startTime = a['startTime'] as String?;
  if (date == null || startTime == null) return false;
  try {
    final dt = DateTime.parse('${date}T$startTime:00');
    return dt.isBefore(DateTime.now());
  } catch (_) {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Appointment tile
// ---------------------------------------------------------------------------

class _AppointmentTile extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onApprove;
  final ValueChanged<String?> onReject;

  const _AppointmentTile({
    required this.appointment,
    required this.onApprove,
    required this.onReject,
  });

  Future<void> _dialPhone(BuildContext context, String phone) async {
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
    // Resolve client name — OwnerAppointmentResource shape (clientFirstName/clientLastName)
    // or fallback keys from other shapes.
    String joinNames(String? a, String? b) =>
        [a ?? '', b ?? ''].where((s) => s.isNotEmpty).join(' ');

    final clientName = () {
      final full = appointment['clientFullName'] as String?;
      if (full != null && full.trim().isNotEmpty) return full.trim();

      final fromOwner = joinNames(
        appointment['clientFirstName'] as String?,
        appointment['clientLastName'] as String?,
      );
      if (fromOwner.isNotEmpty) return fromOwner;

      final fromWalkIn = joinNames(
        appointment['walkInFirstName'] as String?,
        appointment['walkInLastName'] as String?,
      );
      if (fromWalkIn.isNotEmpty) return fromWalkIn;

      final userMap = appointment['user'] as Map<String, dynamic>?;
      if (userMap != null) {
        final fromUser = joinNames(
          userMap['firstName'] as String?,
          userMap['lastName'] as String?,
        );
        if (fromUser.isNotEmpty) return fromUser;
      }

      // Flat snake_case keys (legacy shape)
      final fromSnake = joinNames(
        appointment['client_first_name'] as String?,
        appointment['client_last_name'] as String?,
      );
      if (fromSnake.isNotEmpty) return fromSnake;

      return '';
    }();

    final serviceName = (appointment['service'] as Map<String, dynamic>?)?['name'] as String?
        ?? appointment['serviceName'] as String?
        ?? appointment['service_name'] as String?
        ?? '';

    // Date/time: prefer OwnerAppointmentResource separate fields, else ISO dateTime.
    final date = appointment['date'] as String?;
    final startTime = appointment['startTime'] as String?;
    final endTime = appointment['endTime'] as String?;
    final isoDateTime = appointment['dateTime'] as String?
        ?? appointment['date_time'] as String?;
    final dateTimeDisplay = (date != null && startTime != null)
        ? '$date $startTime${endTime != null ? ' – $endTime' : ''}'
        : (isoDateTime != null
            ? (isoDateTime.length > 16 ? isoDateTime.substring(0, 16) : isoDateTime)
            : '');

    final phoneValue = appointment['clientPhone'] as String?
        ?? appointment['walkInPhone'] as String?
        ?? (appointment['user'] as Map<String, dynamic>?)?['phone'] as String?
        ?? appointment['client_phone'] as String?
        ?? '';
    final hasPhone = phoneValue.isNotEmpty;

    // Build initials from client name
    final nameParts = (clientName.isNotEmpty ? clientName : 'C')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Client initials avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.30),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    nameParts,
                    style: GoogleFonts.fraunces(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName.isNotEmpty ? clientName : context.l10n.clientFallback,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (serviceName.isNotEmpty)
                      Text(
                        serviceName,
                        style: GoogleFonts.instrumentSerif(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              // Pending pill badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Text(
                  context.l10n.appointmentPending,
                  style: AppTextStyles.overline.copyWith(
                    color: AppColors.secondaryDark,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.textHint),
              const SizedBox(width: 4),
              if (dateTimeDisplay.isNotEmpty)
                Expanded(
                  child: Text(
                    dateTimeDisplay,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              if (hasPhone)
                GestureDetector(
                  onTap: () => _dialPhone(context, phoneValue),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        phoneValue,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              // Ghost "Refuser" button
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final result = await showRejectAppointmentDialog(
                      context,
                      clientName: clientName.isNotEmpty
                          ? clientName
                          : context.l10n.clientFallback,
                    );
                    if (result == null || !result.confirmed) return;
                    onReject(result.reason);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    context.l10n.reject,
                    style: AppTextStyles.buttonSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Burgundy "Accepter" filled button
              Expanded(
                child: FilledButton(
                  onPressed: onApprove,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    context.l10n.approve,
                    style: AppTextStyles.buttonSmall.copyWith(
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gold circle with check icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 32,
                color: AppColors.secondaryDark,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Fraunces serif italic headline
            Text(
              context.l10n.pendingEmptyTitle,
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Muted InstrumentSans subline
            Text(
              context.l10n.pendingEmptySubtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
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
// Auto-approve editorial empty state
//
// Shown when the salon is in capacity_based mode AND capacityAutoApprove=true.
// Replaces the pending list content (the menu item itself stays visible).
// ---------------------------------------------------------------------------

class _AutoApproveEmptyView extends StatelessWidget {
  final VoidCallback onEditSetting;

  const _AutoApproveEmptyView({required this.onEditSetting});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bordeaux circle (64dp) with checkmark + dashed ring
            _DashedRingIcon(),
            const SizedBox(height: AppSpacing.lg),
            // Fraunces italic headline — design proposal copy
            Text(
              context.l10n.autoApprovalEnabled,
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Instrument Sans body — explain why the list is empty
            Text(
              context.l10n.autoApprovalEmptyMessage,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            // CTA — navigate to capacity settings to toggle the flag
            OutlinedButton(
              onPressed: onEditSetting,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 12,
                ),
              ),
              child: Text(
                context.l10n.autoApprovalEditCta,
                style: AppTextStyles.buttonSmall
                    .copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 64dp circle in bordeaux with a white checkmark and a dashed outer ring.
class _DashedRingIcon extends StatelessWidget {
  const _DashedRingIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(
        painter: _DashedCirclePainter(
          color: AppColors.primary.withValues(alpha: 0.35),
          strokeWidth: 1.5,
          dashLength: 4,
          gapLength: 3,
        ),
        child: Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 30,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  const _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = (size.width / 2) - strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * 3.141592653589793 * radius;
    final dashCount = circumference / (dashLength + gapLength);
    final dashAngle = (dashLength / circumference) * 2 * 3.141592653589793;
    final gapAngle = (gapLength / circumference) * 2 * 3.141592653589793;

    double startAngle = -3.141592653589793 / 2;
    for (int i = 0; i < dashCount.floor(); i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
      startAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength;
}
