import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/datasources/my_company_remote_datasource.dart';
import '../providers/company_dashboard_provider.dart';
import '../providers/pending_count_provider.dart';

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

  Future<void> updateStatus(String id, String status) async {
    if (!mounted) return;
    final previous = state.appointments
        .map((a) => a['id'].toString() == id
            ? {...a, 'status': status}
            : a)
        .toList();
    state = state.copyWith(appointments: previous);

    try {
      await _datasource.updateAppointmentStatus(id, status);
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.pendingApprovals, style: AppTextStyles.h3),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.cardShadow,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () =>
                  ref.read(_pendingProvider.notifier).load(),
              child: state.appointments.isEmpty
                  ? _EmptyView()
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: state.appointments.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final appt = state.appointments[index];
                        return _AppointmentTile(
                          appointment: appt,
                          onApprove: () {
                            ref
                                .read(_pendingProvider.notifier)
                                .updateStatus(
                                    appt['id'].toString(), 'confirmed')
                                .then((_) => ref
                                    .read(pendingCountProvider.notifier)
                                    .refresh());
                          },
                          onReject: () {
                            ref
                                .read(_pendingProvider.notifier)
                                .updateStatus(
                                    appt['id'].toString(), 'rejected')
                                .then((_) => ref
                                    .read(pendingCountProvider.notifier)
                                    .refresh());
                          },
                        );
                      },
                        ),
                      ),
                    ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Appointment tile
// ---------------------------------------------------------------------------

class _AppointmentTile extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onApprove;
  final VoidCallback onReject;

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
                  onPressed: onReject,
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
