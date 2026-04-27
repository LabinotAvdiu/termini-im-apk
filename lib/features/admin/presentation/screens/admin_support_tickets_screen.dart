import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/models/admin_support_ticket_model.dart';
import '../providers/admin_support_tickets_provider.dart';

class AdminSupportTicketsScreen extends ConsumerStatefulWidget {
  const AdminSupportTicketsScreen({super.key});

  @override
  ConsumerState<AdminSupportTicketsScreen> createState() =>
      _AdminSupportTicketsScreenState();
}

class _AdminSupportTicketsScreenState
    extends ConsumerState<AdminSupportTicketsScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminSupportTicketsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(adminSupportTicketsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSupportTicketsProvider);
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          l.adminSupportTicketsTitle,
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, AdminSupportTicketsState state) {
    final l = context.l10n;

    if (state.isLoading && state.tickets.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null && state.tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.errorMessage(state.error),
                style: AppTextStyles.body.copyWith(color: AppColors.textHint),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () =>
                    ref.read(adminSupportTicketsProvider.notifier).load(),
                child: Text(l.supportErrorRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.tickets.isEmpty) {
      return Center(
        child: Text(
          l.adminTicketsEmpty,
          style: AppTextStyles.body.copyWith(color: AppColors.textHint),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => ref.read(adminSupportTicketsProvider.notifier).load(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        itemCount: state.tickets.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.tickets.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          final ticket = state.tickets[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _TicketCard(ticket: ticket),
          );
        },
      ),
    );
  }
}

class _TicketCard extends ConsumerWidget {
  final AdminSupportTicket ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final isResolved = ticket.isResolved;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isResolved
              ? AppColors.divider
              : AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${ticket.id} · ${ticket.firstName}',
                    style: AppTextStyles.h3.copyWith(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatusBadge(isResolved: isResolved),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            _ContactRow(
              icon: Icons.phone_outlined,
              label: ticket.phone,
              onTap: () => _callPhone(ticket.phone),
            ),
            if (ticket.email != null)
              _ContactRow(
                icon: Icons.email_outlined,
                label: ticket.email!,
                onTap: null,
              ),
            const SizedBox(height: AppSpacing.sm),
            _SourcePageChip(sourcePage: ticket.sourcePage),
            const SizedBox(height: AppSpacing.sm),
            Text(
              ticket.message,
              style: AppTextStyles.body.copyWith(height: 1.5),
            ),
            if (ticket.attachmentUrls.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _AttachmentRow(urls: ticket.attachmentUrls),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(ticket.createdAt),
                    style: AppTextStyles.caption,
                  ),
                ),
                if (!isResolved)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () async {
                      try {
                        await ref
                            .read(adminSupportTicketsProvider.notifier)
                            .markResolved(ticket.id);
                      } catch (_) {
                        if (context.mounted) {
                          context.showErrorSnackBar(
                            Exception(context.l10n.actionFailed),
                          );
                        }
                      }
                    },
                    child: Text(
                      l.adminMarkResolved,
                      style: AppTextStyles.buttonSmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year} · '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isResolved;
  const _StatusBadge({required this.isResolved});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: isResolved
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        isResolved ? l.adminTicketResolved : l.adminTicketOpen,
        style: GoogleFonts.instrumentSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: isResolved ? AppColors.success : AppColors.primary,
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textHint),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color:
                    onTap != null ? AppColors.primary : AppColors.textSecondary,
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourcePageChip extends StatelessWidget {
  final String sourcePage;
  const _SourcePageChip({required this.sourcePage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.ivoryAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        sourcePage.toUpperCase().replaceAll('_', ' '),
        style: AppTextStyles.overline,
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  final List<String> urls;
  const _AttachmentRow({required this.urls});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      children: urls
          .map(
            (url) => ActionChip(
              avatar: const Icon(Icons.attach_file, size: 14),
              label: Text(
                url.split('/').last,
                style: AppTextStyles.caption,
              ),
              backgroundColor: AppColors.ivoryAlt,
              side: BorderSide.none,
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          )
          .toList(),
    );
  }
}
