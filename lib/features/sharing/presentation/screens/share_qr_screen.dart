import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../company/presentation/providers/company_dashboard_provider.dart';
import '../../data/share_qr_service.dart';
import '../../domain/share_url_builder.dart';

/// Settings → Partage QR — owner / employee generates a QR code that
/// scans into the salon booking flow. Toggle "with me as employee" is
/// shared between the link and the QR (single state).
///
/// Layout adapts at 840px breakpoint:
///   * mobile : single-column, QR card stacked under the input
///   * desktop: 640px max content width centered, two-column section for
///     "input + email send" left and "QR card" right
class ShareQrScreen extends ConsumerStatefulWidget {
  const ShareQrScreen({super.key});

  @override
  ConsumerState<ShareQrScreen> createState() => _ShareQrScreenState();
}

class _ShareQrScreenState extends ConsumerState<ShareQrScreen> {
  late final TextEditingController _captionCtrl;
  final GlobalKey _qrCardKey = GlobalKey();
  bool _includeMe = true;
  bool _sendingEmail = false;

  @override
  void initState() {
    super.initState();
    _captionCtrl = TextEditingController();
    // Pre-fill with the salon name once the dashboard is loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(companyDashboardProvider);
      if (state.company != null && _captionCtrl.text.isEmpty) {
        _captionCtrl.text = state.company!.name;
      }
    });
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  bool get _showToggle {
    final company = ref.read(companyDashboardProvider).company;
    final user = ref.read(authStateProvider).user;
    if (company == null || user == null) return false;
    if (company.bookingMode != 'employee_based') return false;
    return company.employees.any((e) => e.userId == user.id);
  }

  String _buildShareUrl() {
    final company = ref.read(companyDashboardProvider).company;
    final user = ref.read(authStateProvider).user;
    if (company == null) return '';
    final useEmployee = _showToggle && _includeMe && user != null;
    return buildSalonShareUrl(
      company.id,
      employeeId: useEmployee ? user.id : null,
    );
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _buildShareUrl()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.shareLinkCopied)),
    );
  }

  Future<Uint8List?> _captureQrPng() async {
    try {
      final boundary = _qrCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendEmail() async {
    final company = ref.read(companyDashboardProvider).company;
    final user = ref.read(authStateProvider).user;
    if (company == null || user == null || _sendingEmail) return;

    setState(() => _sendingEmail = true);
    try {
      final pngBytes = await _captureQrPng();
      if (pngBytes == null) {
        throw Exception('QR capture failed');
      }
      await ref.read(shareQrServiceProvider).emailQr(
            companyId: company.id,
            pngBytes: pngBytes,
            caption: _captionCtrl.text.trim().isEmpty
                ? null
                : _captionCtrl.text.trim(),
            employeeId: (_showToggle && _includeMe) ? user.id : null,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.shareQrEmailSent)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.shareQrEmailFailed),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final company = ref.watch(companyDashboardProvider).company;
    final user = ref.watch(authStateProvider).user;
    final isDesktop = MediaQuery.sizeOf(context).width >= 840;

    if (company == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(context.l10n.shareQrPageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          context.l10n.shareQrPageTitle,
          style: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : AppSpacing.lg,
                vertical: isDesktop ? 32 : AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Block 1: Link copy + toggle ----
                  _BlockHeader(
                    pretitle: context.l10n.shareQrLinkPretitle,
                    title: context.l10n.shareQrLinkTitle,
                    helper: context.l10n.shareQrLinkHelper,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _LinkPreview(
                    url: _buildShareUrl(),
                    onTap: _copyLink,
                  ),
                  if (_showToggle) ...[
                    const SizedBox(height: AppSpacing.md),
                    _MeToggle(
                      value: _includeMe,
                      onChanged: (v) => setState(() => _includeMe = v),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // ---- Block 2: input + QR ----
                  _BlockHeader(
                    pretitle: context.l10n.shareQrCaptionPretitle,
                    title: context.l10n.shareQrCaptionTitle,
                    helper: context.l10n.shareQrCaptionHelper,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _CaptionInput(controller: _captionCtrl),
                              const SizedBox(height: AppSpacing.xl),
                              _EmailSend(
                                email: user?.email ?? '',
                                loading: _sendingEmail,
                                onTap: _sendEmail,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: _QrCard(
                            cardKey: _qrCardKey,
                            caption: _captionCtrl.text.trim().isEmpty
                                ? company.name
                                : _captionCtrl.text.trim(),
                            url: _buildShareUrl(),
                            bottomText: context.l10n.shareQrBottomText,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _CaptionInput(controller: _captionCtrl),
                    const SizedBox(height: AppSpacing.lg),
                    _QrCard(
                      cardKey: _qrCardKey,
                      caption: _captionCtrl.text.trim().isEmpty
                          ? company.name
                          : _captionCtrl.text.trim(),
                      url: _buildShareUrl(),
                      bottomText: context.l10n.shareQrBottomText,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _EmailSend(
                      email: user?.email ?? '',
                      loading: _sendingEmail,
                      onTap: _sendEmail,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _BlockHeader extends StatelessWidget {
  final String pretitle;
  final String title;
  final String helper;

  const _BlockHeader({
    required this.pretitle,
    required this.title,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pretitle.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 2.6,
            color: AppColors.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            height: 1.2,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          helper,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textHint,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _LinkPreview extends StatelessWidget {
  final String url;
  final VoidCallback onTap;

  const _LinkPreview({required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final shortUrl = url.replaceFirst('https://', '');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                shortUrl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.05,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.copy_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: AppColors.secondary, width: 2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.shareQrToggleLabel,
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.shareQrToggleHelp,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _CaptionInput extends StatelessWidget {
  final TextEditingController controller;

  const _CaptionInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.shareQrCaptionInputLabel.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 2.0,
            color: AppColors.textHint,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: 80,
          onChanged: (_) => (context as Element).markNeedsBuild(),
          style: GoogleFonts.fraunces(
            fontSize: 17,
            color: AppColors.textPrimary,
            letterSpacing: -0.05,
          ),
          decoration: InputDecoration(
            isDense: true,
            counterText: '',
            hintText: context.l10n.shareQrCaptionInputHint,
            hintStyle: GoogleFonts.instrumentSerif(
              fontSize: 17,
              fontStyle: FontStyle.italic,
              color: AppColors.textHint,
            ),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _QrCard extends StatelessWidget {
  final GlobalKey cardKey;
  final String caption;
  final String url;
  final String bottomText;

  const _QrCard({
    required this.cardKey,
    required this.caption,
    required this.url,
    required this.bottomText,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: cardKey,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.secondary),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              caption,
              textAlign: TextAlign.center,
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  QrImageView(
                    data: url,
                    version: QrVersions.auto,
                    size: 220,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.textPrimary,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.textPrimary,
                    ),
                    // Level H = 30% error correction — survives the central
                    // logo overlay without losing scan reliability.
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border.all(color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'im',
                        style: GoogleFonts.instrumentSerif(
                          fontSize: 22,
                          fontStyle: FontStyle.italic,
                          color: AppColors.primary,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              bottomText,
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSerif(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.primary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailSend extends StatelessWidget {
  final String email;
  final bool loading;
  final VoidCallback onTap;

  const _EmailSend({
    required this.email,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.shareQrEmailSendLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 2.0,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: loading ? null : onTap,
            icon: loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 14),
            label: Text(context.l10n.shareQrEmailSendButton),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
