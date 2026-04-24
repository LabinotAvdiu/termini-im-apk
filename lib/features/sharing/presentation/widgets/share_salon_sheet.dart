import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/share_url_builder.dart';

/// Entry point called from both mobile (bottom sheet) and desktop (dialog)
/// surfaces. Decides the presentation mode by window width.
///
///  * [companyId] is the target salon.
///  * [salonName] is shown in the subtitle ("Partager ce salon — <name>").
///  * [bookingMode] is the salon's booking mode ('employee_based' or
///    'capacity_based'). The employee toggle is hidden when not employee-based.
///  * [isCurrentUserEmployee] is `true` iff the logged-in user's id appears
///    in this salon's employee list. The toggle only appears when true.
Future<void> showShareSalonSheet(
  BuildContext context, {
  required String companyId,
  required String salonName,
  required String bookingMode,
  required bool isCurrentUserEmployee,
}) {
  final isDesktop = MediaQuery.sizeOf(context).width >= 840;

  if (isDesktop) {
    return showDialog<void>(
      context: context,
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.36),
      builder: (ctx) => _ShareSalonDialog(
        companyId: companyId,
        salonName: salonName,
        bookingMode: bookingMode,
        isCurrentUserEmployee: isCurrentUserEmployee,
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.textPrimary.withValues(alpha: 0.36),
    builder: (ctx) => _ShareSalonBottomSheet(
      companyId: companyId,
      salonName: salonName,
      bookingMode: bookingMode,
      isCurrentUserEmployee: isCurrentUserEmployee,
    ),
  );
}

// ---------------------------------------------------------------------------
// Mobile bottom sheet
// ---------------------------------------------------------------------------
class _ShareSalonBottomSheet extends StatelessWidget {
  final String companyId;
  final String salonName;
  final String bookingMode;
  final bool isCurrentUserEmployee;

  const _ShareSalonBottomSheet({
    required this.companyId,
    required this.salonName,
    required this.bookingMode,
    required this.isCurrentUserEmployee,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: _ShareSheetContent(
          companyId: companyId,
          salonName: salonName,
          bookingMode: bookingMode,
          isCurrentUserEmployee: isCurrentUserEmployee,
          showHandle: true,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop centered dialog
// ---------------------------------------------------------------------------
class _ShareSalonDialog extends StatelessWidget {
  final String companyId;
  final String salonName;
  final String bookingMode;
  final bool isCurrentUserEmployee;

  const _ShareSalonDialog({
    required this.companyId,
    required this.salonName,
    required this.bookingMode,
    required this.isCurrentUserEmployee,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thin bordeaux accent on top — matches the design mockup.
            Container(
              height: 3,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Stack(
              children: [
                _ShareSheetContent(
                  companyId: companyId,
                  salonName: salonName,
                  bookingMode: bookingMode,
                  isCurrentUserEmployee: isCurrentUserEmployee,
                  showHandle: false,
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _DesktopCloseButton(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopCloseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).pop(),
        child: const SizedBox(
          width: 28,
          height: 28,
          child: Icon(Icons.close_rounded, size: 14, color: AppColors.textHint),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared content (same for mobile sheet and desktop dialog)
// ---------------------------------------------------------------------------
class _ShareSheetContent extends ConsumerStatefulWidget {
  final String companyId;
  final String salonName;
  final String bookingMode;
  final bool isCurrentUserEmployee;
  final bool showHandle;

  const _ShareSheetContent({
    required this.companyId,
    required this.salonName,
    required this.bookingMode,
    required this.isCurrentUserEmployee,
    required this.showHandle,
  });

  @override
  ConsumerState<_ShareSheetContent> createState() =>
      _ShareSheetContentState();
}

class _ShareSheetContentState extends ConsumerState<_ShareSheetContent> {
  /// Toggle default is ON for employees — the whole point of the share is
  /// recommending yourself. The owner can flip it off for a generic share.
  bool _includeMe = true;

  /// The toggle row is visible iff the viewer is an employee of this salon
  /// AND the salon is in employee_based mode (capacity_based can't
  /// pre-select a pro — it'd be misleading).
  bool get _showToggle =>
      widget.isCurrentUserEmployee &&
      widget.bookingMode == 'employee_based';

  String get _shareUrl {
    final userId = ref.read(authStateProvider).user?.id;
    final includeEmp = _showToggle && _includeMe && userId != null;
    return buildSalonShareUrl(
      widget.companyId,
      employeeId: includeEmp ? userId : null,
    );
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _shareUrl));
    // E25 — share_link_copied
    final userId = ref.read(authStateProvider).user?.id;
    final includeEmp = _showToggle && _includeMe && userId != null;
    ref.read(analyticsProvider).logShareLinkCopied(
          salonId: widget.companyId,
          employeeId: includeEmp ? userId : null,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.shareLinkCopied)),
    );
  }

  Future<void> _openWhatsApp() async {
    final message = context.l10n
        .shareWhatsAppMessage(widget.salonName, _shareUrl);
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );
    Navigator.of(context).pop();
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openNativeShare() async {
    final message = context.l10n
        .shareWhatsAppMessage(widget.salonName, _shareUrl);
    final box = context.findRenderObject() as RenderBox?;
    Navigator.of(context).pop();
    await Share.share(
      message,
      subject: widget.salonName,
      // iPad requires an origin rect — pass the sheet's center if available.
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHandle) const _Handle(),
          // Header — kicker + Fraunces title + salon subtitle
          const SizedBox(height: AppSpacing.sm),
          _KickerDot(label: l.shareSalon.toUpperCase()),
          const SizedBox(height: 10),
          Text(
            l.shareSalonSheetTitle,
            style: GoogleFonts.fraunces(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              height: 1.05,
              letterSpacing: -0.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.salonName} · ${l.shareSalonSheetSubtitle}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Optional employee toggle
          if (_showToggle) ...[
            _MeRecommendCard(
              value: _includeMe,
              onChanged: (v) => setState(() => _includeMe = v),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          const _CenteredRule(),
          const SizedBox(height: 4),

          // Destinations
          _DestinationRow(
            iconBg: const Color(0xFF25D366).withValues(alpha: 0.14),
            iconColor: const Color(0xFF25D366),
            icon: Icons.chat_bubble_rounded,
            label: l.shareViaWhatsApp,
            caption: l.shareViaWhatsAppCaption,
            onTap: _openWhatsApp,
          ),
          const _DashedDivider(),
          _DestinationRow(
            iconBg: AppColors.primary.withValues(alpha: 0.10),
            iconColor: AppColors.primary,
            icon: Icons.ios_share_rounded,
            label: l.shareMore,
            caption: l.shareMoreCaption,
            onTap: _openNativeShare,
          ),
          const _DashedDivider(),
          _DestinationRow(
            iconBg: AppColors.primary.withValues(alpha: 0.10),
            iconColor: AppColors.primary,
            icon: Icons.link_rounded,
            label: l.shareCopyLink,
            caption: _shareUrl
                .replaceFirst('https://', '')
                .replaceAll('/', ' / '),
            onTap: _copyLink,
          ),

          // E27 — share incentive gate (flag Remote Config)
          if (ref.watch(remoteConfigProvider).shareIncentiveEnabled) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.card_giftcard_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      // TODO i18n sprint — ajouter shareIncentiveText à l'ARB
                      'Invite un·e ami·e — il·elle obtient 20%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _LinkPreview(url: _shareUrl),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _Handle extends StatelessWidget {
  const _Handle();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 6, bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _KickerDot extends StatelessWidget {
  final String label;
  const _KickerDot({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 3,
            color: AppColors.textHint,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Editorial "Me recommander" card — thin bordeaux rule on the left edge,
/// gold dot accent, italic Instrument Serif label. Matches the HTML mockup.
class _MeRecommendCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MeRecommendCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 14, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.05),
                AppColors.secondary.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.shareIncludeMeAsPro,
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 17,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.shareIncludeMeAsProHelp,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textHint,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: value,
                activeColor: AppColors.primary,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        // Bordeaux left rule
        Positioned(
          top: 14,
          bottom: 14,
          left: 0,
          child: Container(
            width: 2,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        // Gold dot accent midway up the rule
        Positioned(
          left: -3,
          top: 0,
          bottom: 0,
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.background,
                  width: 3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CenteredRule extends StatelessWidget {
  const _CenteredRule();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 1,
          color: AppColors.border,
        ),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.divider,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final dashCount = (c.maxWidth / 6).floor();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: List.generate(dashCount, (_) {
              return Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  color: AppColors.border.withValues(alpha: 0.55),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _DestinationRow extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  const _DestinationRow({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.fraunces(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      letterSpacing: 0.15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textHint.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkPreview extends StatelessWidget {
  final String url;
  const _LinkPreview({required this.url});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              l.shareLinkPreviewLabel.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              url.replaceFirst('https://', ''),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textPrimary,
                letterSpacing: 0.1,
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
