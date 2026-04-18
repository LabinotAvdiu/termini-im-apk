import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/language_sheet.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/widgets/notification_preferences_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;
  bool _hasChanges = false;

  // Original values to detect changes
  late String _origFirstName;
  late String _origLastName;
  late String _origPhone;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    _origFirstName = user?.firstName ?? '';
    _origLastName = user?.lastName ?? '';
    _origPhone = user?.phone ?? '';

    _firstNameController = TextEditingController(text: _origFirstName);
    _lastNameController = TextEditingController(text: _origLastName);
    _phoneController = TextEditingController(text: _origPhone);

    _firstNameController.addListener(_checkChanges);
    _lastNameController.addListener(_checkChanges);
    _phoneController.addListener(_checkChanges);
  }

  void _checkChanges() {
    final changed = _firstNameController.text != _origFirstName ||
        _lastNameController.text != _origLastName ||
        _phoneController.text != _origPhone;
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(authRepositoryProvider);
      final updatedUser = await repository.updateProfile(data: {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      if (!mounted) return;

      ref.read(authStateProvider.notifier).updateUser(updatedUser);

      // Update originals so button hides
      _origFirstName = _firstNameController.text;
      _origLastName = _lastNameController.text;
      _origPhone = _phoneController.text;

      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });

      context.showSnackBar(context.l10n.changesSaved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      context.showErrorSnackBar(e);
    }
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(context.l10n.logout, style: AppTextStyles.h3),
        content: Text(
          context.l10n.logoutConfirm,
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.logout),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    final pwFormKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(context.l10n.changePassword, style: AppTextStyles.h3),
        content: Form(
          key: pwFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: currentPwController,
                label: context.l10n.currentPassword,
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
                validator: (v) => Validators.password(v,
                    requiredMessage: context.l10n.passwordRequired),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: newPwController,
                label: context.l10n.newPassword,
                obscureText: true,
                prefixIcon: Icons.lock_rounded,
                validator: (v) => Validators.password(v,
                    requiredMessage: context.l10n.passwordRequired,
                    tooShortMessage: context.l10n.passwordTooShort),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: confirmPwController,
                label: context.l10n.confirmNewPassword,
                obscureText: true,
                prefixIcon: Icons.lock_rounded,
                validator: (v) => Validators.confirmPassword(
                    v, newPwController.text,
                    message: context.l10n.passwordsDoNotMatch),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!pwFormKey.currentState!.validate()) return;
              try {
                final repository = ref.read(authRepositoryProvider);
                await repository.changePassword(
                  currentPassword: currentPwController.text,
                  password: newPwController.text,
                  passwordConfirmation: confirmPwController.text,
                );
                if (!mounted) return;
                Navigator.of(ctx).pop();
                context.showSnackBar(context.l10n.resetPasswordSuccess);
              } catch (e) {
                if (!mounted) return;
                Navigator.of(ctx).pop();
                context.showErrorSnackBar(e);
              }
            },
            child: Text(context.l10n.saveChanges),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet() {
    final repository = ref.read(authRepositoryProvider);
    final isAuthenticated = ref.read(authStateProvider).isAuthenticated;
    showLanguageSheet(
      context,
      repository: isAuthenticated ? repository : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle, style: AppTextStyles.h3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
          children: [
            // Profile avatar
            _ProfileAvatar(
              name: '${_firstNameController.text} ${_lastNameController.text}',
              isEditing: false,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Personal info form
            _SectionCard(
              title: context.l10n.personalInfo,
              icon: Icons.person_outline_rounded,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email (read-only)
                    AppTextField(
                      controller: TextEditingController(
                        text: ref.watch(authStateProvider).user?.email ?? '',
                      ),
                      label: context.l10n.email,
                      enabled: false,
                      prefixIcon: Icons.email_outlined,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _firstNameController,
                            label: context.l10n.firstName,
                            prefixIcon: Icons.person_outline,
                            validator: (v) => Validators.required(v,
                                message: context.l10n.firstNameRequired),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            controller: _lastNameController,
                            label: context.l10n.lastName,
                            prefixIcon: Icons.person_outline,
                            validator: (v) => Validators.required(v,
                                message: context.l10n.lastNameRequired),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: _phoneController,
                      label: context.l10n.phone,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    // Update button — only visible when changes detected
                    if (_hasChanges) ...[
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        text: context.l10n.saveChanges,
                        isLoading: _isSaving,
                        onPressed: _saveChanges,
                        width: double.infinity,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Settings options
            _SectionCard(
              title: context.l10n.settingsTitle,
              icon: Icons.tune_rounded,
              child: Column(
                children: [
                  // Language
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    title: context.l10n.language,
                    trailing: Text(
                      switch (ref.watch(localeProvider).languageCode) {
                        'fr' => context.l10n.french,
                        'sq' => context.l10n.albanian,
                        _ => context.l10n.english,
                      },
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: _showLanguageSheet,
                  ),
                  const Divider(height: 1, color: AppColors.divider, indent: 48),

                  // Change password
                  _SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    title: context.l10n.changePassword,
                    onTap: _showChangePasswordDialog,
                  ),
                ],
              ),
            ),

            // Section Notifications — uniquement pour owner et employee.
            // Les clients (UserRole.user) n'ont pas de préférences configurables :
            // leurs notifications sont toutes forcées côté serveur.
            if (ref.watch(authStateProvider.select((s) => !s.isClient))) ...[
              const SizedBox(height: AppSpacing.md),
              const NotificationPreferencesSection(),
            ],

            const SizedBox(height: AppSpacing.md),

            // Danger zone
            _SectionCard(
              title: '',
              icon: null,
              child: Column(
                children: [
                  // Logout
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    iconColor: AppColors.primary,
                    title: context.l10n.logout,
                    titleColor: AppColors.primary,
                    onTap: _showLogoutDialog,
                  ),
                  const Divider(height: 1, color: AppColors.divider, indent: 48),

                  // Delete account
                  _SettingsTile(
                    icon: Icons.delete_outline_rounded,
                    iconColor: AppColors.primary,
                    title: context.l10n.deleteAccount,
                    subtitle: context.l10n.deleteAccountWarning,
                    titleColor: AppColors.primary,
                    onTap: () {
                      // TODO: Implement delete account flow
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile avatar
// ---------------------------------------------------------------------------

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final bool isEditing;

  const _ProfileAvatar({required this.name, required this.isEditing});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withValues(alpha: 0.10),
              child: Text(
                initials,
                style: GoogleFonts.fraunces(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  color: AppColors.primary,
                  height: 1.0,
                ),
              ),
            ),
            if (isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(name, style: AppTextStyles.h3),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section card — editorial: 1px border, Fraunces section heading + overline
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: AppColors.textHint),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    title.toUpperCase(),
                    style: AppTextStyles.overline.copyWith(letterSpacing: 1.8),
                  ),
                ],
              ),
            ),
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs,
              ),
              child: Text(title, style: AppTextStyles.h3),
            ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings tile
// ---------------------------------------------------------------------------

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor ?? AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      color: titleColor ?? AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textHint,
                ),
          ],
        ),
      ),
    );
  }
}

