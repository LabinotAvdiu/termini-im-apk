import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/support_models.dart';
import '../providers/support_provider.dart';

/// Pushes the editorial Contact Support modal.
///
/// [sourcePage] is saved in the database so the support team can see where the
/// request came from. [sourceContext] lets callers pass extra context (e.g.
/// `{'companyId': '...'}` when opened from a salon page).
Future<void> showContactSupportDialog(
  BuildContext context, {
  required WidgetRef ref,
  required SupportSourcePage sourcePage,
  Map<String, Object?>? sourceContext,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.textPrimary.withValues(alpha: 0.45),
    builder: (_) => ContactSupportDialog(
      sourcePage: sourcePage,
      sourceContext: sourceContext,
    ),
  );
}

class ContactSupportDialog extends ConsumerStatefulWidget {
  final SupportSourcePage sourcePage;
  final Map<String, Object?>? sourceContext;

  const ContactSupportDialog({
    super.key,
    required this.sourcePage,
    this.sourceContext,
  });

  @override
  ConsumerState<ContactSupportDialog> createState() =>
      _ContactSupportDialogState();
}

class _ContactSupportDialogState extends ConsumerState<ContactSupportDialog> {
  static const int _maxAttachments = 3;
  static const int _maxMessageChars = 2000;
  static const int _minMessageChars = 10;
  static const int _maxFileSizeBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  final _messageCtrl = TextEditingController();

  final List<SupportAttachment> _attachments = [];
  bool _submitting = false;
  String? _attachmentError;
  String? _submitError;
  bool _success = false;

  bool _firstNamePrefilled = false;
  bool _phonePrefilled = false;
  bool _emailPrefilled = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _firstNamePrefilled = (user?.firstName ?? '').isNotEmpty;
    _phonePrefilled = (user?.phone ?? '').isNotEmpty;
    _emailPrefilled = (user?.email ?? '').isNotEmpty;
    _messageCtrl.addListener(_triggerRebuild);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.removeListener(_triggerRebuild);
    _messageCtrl.dispose();
    super.dispose();
  }

  void _triggerRebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _pickAttachment() async {
    setState(() => _attachmentError = null);
    final remaining = _maxAttachments - _attachments.length;
    if (remaining <= 0) return;

    final l = context.l10n;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      allowMultiple: remaining > 1,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    for (final f in result.files) {
      if (_attachments.length >= _maxAttachments) {
        setState(() => _attachmentError = l.supportMaxThreeFiles);
        break;
      }
      final bytes = f.bytes;
      if (bytes == null) continue;
      if (bytes.length > _maxFileSizeBytes) {
        setState(() => _attachmentError = l.supportFileTooLarge);
        continue;
      }
      final mime = _mimeFromName(f.name);
      if (mime == null) {
        setState(() => _attachmentError = l.supportFileUnsupported);
        continue;
      }
      _attachments.add(SupportAttachment(
        name: f.name,
        bytes: Uint8List.fromList(bytes),
        mime: mime,
        sizeBytes: bytes.length,
      ));
    }
    if (mounted) setState(() {});
  }

  String? _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return null;
  }

  void _removeAttachment(int index) {
    setState(() => _attachments.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final request = SupportTicketRequest(
      firstName: _firstNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
      sourcePage: widget.sourcePage,
      sourceContext: widget.sourceContext,
      attachments: List.unmodifiable(_attachments),
    );

    final result = await ref.read(supportControllerProvider).submit(request);
    if (!mounted) return;

    switch (result) {
      case SubmitSupportSuccess():
        setState(() {
          _submitting = false;
          _success = true;
        });
      case SubmitSupportError():
        setState(() {
          _submitting = false;
          _submitError = result.validationMessage
              ?? context.errorMessage(result.cause);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.13), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.28),
                blurRadius: 48,
                offset: const Offset(0, 24),
              ),
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _success
              ? _SuccessCard(onClose: () => Navigator.of(context).pop())
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SupportHeader(
                          onClose: () => Navigator.of(context).pop(),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md + 4,
                            AppSpacing.sm,
                            AppSpacing.md + 4,
                            AppSpacing.md + 4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _FieldLabel(l.supportFirstNameLabel),
                              const SizedBox(height: AppSpacing.xs + 2),
                              _TextField(
                                controller: _firstNameCtrl,
                                hint: l.supportFirstNamePlaceholder,
                                prefilled: _firstNamePrefilled,
                                prefilledBadge: l.supportPrefilledBadge,
                                textCapitalization:
                                    TextCapitalization.words,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? l.supportFieldRequired
                                        : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _FieldLabel(l.supportPhoneLabel),
                              const SizedBox(height: AppSpacing.xs + 2),
                              _TextField(
                                controller: _phoneCtrl,
                                hint: l.supportPhonePlaceholder,
                                prefilled: _phonePrefilled,
                                prefilledBadge: l.supportPrefilledBadge,
                                keyboardType: TextInputType.phone,
                                validator: (v) =>
                                    (v == null || v.trim().length < 4)
                                        ? l.supportFieldRequired
                                        : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _FieldLabel(l.supportEmailLabel),
                              const SizedBox(height: AppSpacing.xs + 2),
                              _TextField(
                                controller: _emailCtrl,
                                hint: l.supportEmailPlaceholder,
                                prefilled: _emailPrefilled,
                                prefilledBadge: l.supportPrefilledBadge,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _FieldLabel(l.supportMessageLabel),
                              const SizedBox(height: AppSpacing.xs + 2),
                              _MessageField(
                                controller: _messageCtrl,
                                hint: l.supportMessagePlaceholder,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return l.supportFieldRequired;
                                  }
                                  if (v.trim().length < _minMessageChars) {
                                    return l.supportMessageMinLength;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  l.supportMessageCounter(
                                    _messageCtrl.text.length,
                                    _maxMessageChars,
                                  ),
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: 11,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _FieldLabel(l.supportAttachmentsLabel),
                              const SizedBox(height: AppSpacing.xs + 2),
                              _AttachmentsRow(
                                attachments: _attachments,
                                maxCount: _maxAttachments,
                                onAdd: _attachments.length < _maxAttachments &&
                                        !_submitting
                                    ? _pickAttachment
                                    : null,
                                onRemove: _submitting
                                    ? null
                                    : _removeAttachment,
                              ),
                              const SizedBox(height: AppSpacing.xs + 2),
                              Text(
                                _attachmentError ?? l.supportAttachmentsHint,
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 11,
                                  color: _attachmentError != null
                                      ? AppColors.error
                                      : AppColors.textHint,
                                ),
                              ),
                              if (_submitError != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                _ErrorBlock(message: _submitError!),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              const _EditorialRule(),
                              const SizedBox(height: AppSpacing.md),
                              _SubmitButton(
                                label: _submitting
                                    ? l.supportSubmitting
                                    : l.supportSubmit,
                                submitting: _submitting,
                                onPressed: _submitting ? null : _submit,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Header
// ===========================================================================

class _SupportHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _SupportHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md + 4,
            AppSpacing.md + 6,
            AppSpacing.md + 4,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Text(
                    l.supportKicker,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.8,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    height: 1.05,
                    letterSpacing: -0.36,
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    TextSpan(text: '${l.supportTitle} '),
                    TextSpan(
                      text: l.supportTitleAccent,
                      style: GoogleFonts.instrumentSerif(
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                l.supportSubtitle,
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  color: AppColors.textHint,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 14,
          right: 14,
          child: Material(
            color: AppColors.background,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClose,
              child: const SizedBox(
                width: 28,
                height: 28,
                child: Icon(Icons.close_rounded,
                    size: 14, color: AppColors.textHint),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Field label
// ===========================================================================

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.instrumentSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.0,
        color: AppColors.textHint,
      ),
    );
  }
}

// ===========================================================================
// Text field with optional "PREFILLED" badge
// ===========================================================================

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool prefilled;
  final String prefilledBadge;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _TextField({
    required this.controller,
    required this.hint,
    required this.prefilledBadge,
    this.prefilled = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: GoogleFonts.instrumentSans(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.instrumentSans(
          fontSize: 14,
          color: AppColors.textHint.withValues(alpha: 0.7),
        ),
        filled: true,
        fillColor: AppColors.background,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        suffixIcon: prefilled
            ? Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _PrefilledBadge(text: prefilledBadge),
              )
            : null,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.primary, width: 1.5),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error, width: 1.5),
        errorStyle: GoogleFonts.instrumentSans(
          fontSize: 11,
          color: AppColors.error,
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color c, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: c, width: width),
      );
}

class _PrefilledBadge extends StatelessWidget {
  final String text;
  const _PrefilledBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.instrumentSans(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.6,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ===========================================================================
// Multiline message field
// ===========================================================================

class _MessageField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;

  const _MessageField({
    required this.controller,
    required this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: 4,
      maxLines: 7,
      maxLength: 2000,
      validator: validator,
      style: GoogleFonts.instrumentSans(
        fontSize: 14,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle: GoogleFonts.instrumentSans(
          fontSize: 14,
          color: AppColors.textHint.withValues(alpha: 0.7),
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.all(14),
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.primary, width: 1.5),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error, width: 1.5),
        errorStyle: GoogleFonts.instrumentSans(
          fontSize: 11,
          color: AppColors.error,
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color c, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: c, width: width),
      );
}

// ===========================================================================
// Attachments row (3 slots)
// ===========================================================================

class _AttachmentsRow extends StatelessWidget {
  final List<SupportAttachment> attachments;
  final int maxCount;
  final VoidCallback? onAdd;
  final void Function(int)? onRemove;

  const _AttachmentsRow({
    required this.attachments,
    required this.maxCount,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Build 3 slots with a consistent height and even gaps. Using a bounded
    // SizedBox avoids "hit test a render box with no size" issues that happen
    // when Row(stretch) + Expanded + transient empty children interact with
    // MouseTracker during hover.
    final children = <Widget>[];
    for (var i = 0; i < maxCount; i++) {
      if (i > 0) {
        children.add(const SizedBox(width: AppSpacing.sm));
      }
      if (i < attachments.length) {
        children.add(Expanded(
          child: _FilledAttachmentTile(
            attachment: attachments[i],
            onRemove: onRemove != null ? () => onRemove!(i) : null,
          ),
        ));
      } else {
        children.add(Expanded(
          child: _EmptyAttachmentSlot(onTap: onAdd),
        ));
      }
    }
    return SizedBox(
      height: 72,
      child: Row(children: children),
    );
  }
}

class _EmptyAttachmentSlot extends StatelessWidget {
  final VoidCallback? onTap;
  const _EmptyAttachmentSlot({this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Center(
            child: Icon(
              Icons.add_rounded,
              size: 22,
              color: disabled
                  ? AppColors.textHint.withValues(alpha: 0.35)
                  : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilledAttachmentTile extends StatelessWidget {
  final SupportAttachment attachment;
  final VoidCallback? onRemove;
  const _FilledAttachmentTile({required this.attachment, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final icon = attachment.isPdf
        ? Icons.picture_as_pdf_rounded
        : Icons.image_rounded;
    final sizeKb = (attachment.sizeBytes / 1024).round();
    final label = sizeKb < 1024
        ? '$sizeKb Ko'
        : '${(sizeKb / 1024).toStringAsFixed(1)} Mo';

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(height: 2),
              Text(
                attachment.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.instrumentSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.instrumentSans(
                  fontSize: 10,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 2,
            right: 2,
            child: Material(
              color: AppColors.surface,
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.border),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: Icon(Icons.close_rounded,
                      size: 12, color: AppColors.textHint),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ===========================================================================
// Error block
// ===========================================================================

class _ErrorBlock extends StatelessWidget {
  final String message;
  const _ErrorBlock({required this.message});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF3F3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: AppColors.error.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.supportErrorTitle,
                  style: GoogleFonts.fraunces(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 12,
                    color: AppColors.textHint,
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

// ===========================================================================
// Editorial rule (1px line with centered dot)
// ===========================================================================

class _EditorialRule extends StatelessWidget {
  const _EditorialRule();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
            child: Divider(height: 1, thickness: 1, color: AppColors.divider)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
        ),
        const Expanded(
            child: Divider(height: 1, thickness: 1, color: AppColors.divider)),
      ],
    );
  }
}

// ===========================================================================
// Submit button
// ===========================================================================

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool submitting;
  final VoidCallback? onPressed;
  const _SubmitButton({
    required this.label,
    required this.submitting,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            AppColors.primary.withValues(alpha: 0.55),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        shadowColor: AppColors.primary.withValues(alpha: 0.4),
        elevation: 6,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (submitting) ...[
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ] else ...[
            const Icon(Icons.send_rounded, size: 16),
          ],
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.instrumentSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Success card
// ===========================================================================

class _SuccessCard extends StatelessWidget {
  final VoidCallback onClose;
  const _SuccessCard({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md + 4,
        AppSpacing.xl,
        AppSpacing.md + 4,
        AppSpacing.md + 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.13),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.5)),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 36,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.fraunces(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                height: 1.1,
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(text: '${l.supportSuccessTitle} '),
                TextSpan(
                  text: l.supportSuccessTitleAccent,
                  style: GoogleFonts.instrumentSerif(
                    fontStyle: FontStyle.italic,
                    color: AppColors.primary,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l.supportSuccessSubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSans(
              fontSize: 13,
              color: AppColors.textHint,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg + 4),
          OutlinedButton(
            onPressed: onClose,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Text(
              l.supportSuccessClose,
              style: GoogleFonts.instrumentSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
