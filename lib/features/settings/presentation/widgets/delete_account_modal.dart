import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Entry-point — call from the settings tile's onTap.
Future<void> showDeleteAccountModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    builder: (_) => const _DeleteAccountSheet(),
  );
}

// ---------------------------------------------------------------------------
// Sheet — owns the step state via a StatefulWidget
// ---------------------------------------------------------------------------

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet();

  @override
  ConsumerState<_DeleteAccountSheet> createState() =>
      _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  // Step 1 — disclosure + checkbox
  bool _understood = false;

  // Step 2 — confirmation keyword input
  bool _onStep2 = false;
  final TextEditingController _keywordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String get _expectedKeyword => context.l10n.deleteAccountTypeKeyword;

  bool get _keywordMatches =>
      _keywordController.text.trim().toUpperCase() ==
      _expectedKeyword.toUpperCase();

  Future<void> _submit() async {
    if (!_keywordMatches || _isLoading) return;

    setState(() => _isLoading = true);

    final result =
        await ref.read(authStateProvider.notifier).deleteAccount();

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case DeleteAccountSuccess():
        // Close the sheet, then navigate to landing.
        Navigator.of(context).pop();
        context.goNamed(RouteNames.landing);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.deleteAccountSuccess),
            backgroundColor: AppColors.primary,
          ),
        );

      case DeleteAccountOwnerSalon():
        // Close sheet, show blocking dialog explaining what to do.
        Navigator.of(context).pop();
        if (!mounted) return;
        _showOwnerBlockedDialog(context);

      case DeleteAccountError():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.deleteAccountErrorGeneric),
            backgroundColor: Colors.red.shade700,
          ),
        );
    }
  }

  void _showOwnerBlockedDialog(BuildContext ctx) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(
          ctx.l10n.deleteAccountModalTitle,
          style: AppTextStyles.h3.copyWith(color: AppColors.primary),
        ),
        content: Text(
          ctx.l10n.deleteAccountErrorOwnerSalon,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _onStep2 ? _buildStep2() : _buildStep1(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1 — disclosure + checkbox
  // ---------------------------------------------------------------------------

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag handle
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

        const SizedBox(height: AppSpacing.lg),

        // Icon
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.20),
              ),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Title
        Center(
          child: Text(
            context.l10n.deleteAccountModalTitle,
            style: AppTextStyles.h3.copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Description
        Text(
          context.l10n.deleteAccountModalDescription,
          style:
              AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.lg),

        // Checkbox
        InkWell(
          onTap: () => setState(() => _understood = !_understood),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: _understood,
                  onChanged: (v) =>
                      setState(() => _understood = v ?? false),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    context.l10n.deleteAccountModalCheckbox,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // CTA
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _understood
                ? () => setState(() => _onStep2 = true)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.30),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Text(
              context.l10n.deleteAccountModalContinue,
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Dismiss
        SizedBox(
          width: double.infinity,
          height: 44,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              context.l10n.cancel,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2 — keyword confirmation + destructive action button
  // ---------------------------------------------------------------------------

  Widget _buildStep2() {
    return Column(
      key: const ValueKey('step2'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag handle
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

        const SizedBox(height: AppSpacing.lg),

        // Back arrow + title row
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _onStep2 = false),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                context.l10n.deleteAccountModalTitle,
                style: AppTextStyles.h3.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // Prompt label
        Text(
          context.l10n.deleteAccountConfirmPrompt(
            context.l10n.deleteAccountTypeKeyword,
          ),
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Keyword text field
        TextField(
          controller: _keywordController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: _expectedKeyword,
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.textHint,
              letterSpacing: 1,
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMd),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Destructive action button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (_keywordMatches && !_isLoading) ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              disabledBackgroundColor:
                  Colors.red.shade700.withValues(alpha: 0.30),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    context.l10n.deleteAccountConfirmAction,
                    style:
                        AppTextStyles.button.copyWith(color: Colors.white),
                  ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        SizedBox(
          width: double.infinity,
          height: 44,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              context.l10n.cancel,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
