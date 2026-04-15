import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    // TODO: Populate with real user data from auth state
    _firstNameController = TextEditingController(text: 'Jean');
    _lastNameController = TextEditingController(text: 'Dupont');
    _emailController = TextEditingController(text: 'jean.dupont@email.com');
    _phoneController = TextEditingController(text: '+33 6 12 34 56 78');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // TODO: Call API to update user info
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    context.showSnackBar(context.l10n.changesSaved);
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
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: newPwController,
                label: context.l10n.newPassword,
                obscureText: true,
                prefixIcon: Icons.lock_rounded,
                validator: (v) => Validators.password(v,
                    requiredMessage: context.l10n.passwordRequired,
                    tooShortMessage: context.l10n.passwordTooShort),
              ),
              const SizedBox(height: AppSpacing.md),
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
            onPressed: () {
              if (pwFormKey.currentState!.validate()) {
                // TODO: Call API to change password
                Navigator.of(ctx).pop();
                context.showSnackBar(context.l10n.changesSaved);
              }
            },
            child: Text(context.l10n.saveChanges),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet() {
    final currentLocale = ref.read(localeProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(context.l10n.language, style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.md),
            _LanguageTile(
              label: context.l10n.french,
              flag: '🇫🇷',
              isSelected: currentLocale.languageCode == 'fr',
              onTap: () {
                ref.read(localeProvider.notifier).state = const Locale('fr');
                Navigator.of(context).pop();
              },
            ),
            const Divider(height: 1),
            _LanguageTile(
              label: context.l10n.english,
              flag: '🇬🇧',
              isSelected: currentLocale.languageCode == 'en',
              onTap: () {
                ref.read(localeProvider.notifier).state = const Locale('en');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
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
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: context.l10n.editProfile,
              onPressed: () => setState(() => _isEditing = true),
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Profile avatar
            _ProfileAvatar(
              name: '${_firstNameController.text} ${_lastNameController.text}',
              isEditing: _isEditing,
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
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _firstNameController,
                            label: context.l10n.firstName,
                            enabled: _isEditing,
                            prefixIcon: Icons.person_outline,
                            validator: _isEditing
                                ? (v) => Validators.required(v,
                                    message: context.l10n.firstNameRequired)
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            controller: _lastNameController,
                            label: context.l10n.lastName,
                            enabled: _isEditing,
                            prefixIcon: Icons.person_outline,
                            validator: _isEditing
                                ? (v) => Validators.required(v,
                                    message: context.l10n.lastNameRequired)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _emailController,
                      label: context.l10n.email,
                      enabled: _isEditing,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _isEditing
                          ? (v) => Validators.email(v,
                              requiredMessage: context.l10n.emailRequired,
                              invalidMessage: context.l10n.emailInvalid)
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _phoneController,
                      label: context.l10n.phone,
                      enabled: _isEditing,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: context.l10n.cancel,
                              isOutlined: true,
                              onPressed: () =>
                                  setState(() => _isEditing = false),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppButton(
                              text: context.l10n.saveChanges,
                              isLoading: _isSaving,
                              onPressed: _saveChanges,
                            ),
                          ),
                        ],
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
                      ref.watch(localeProvider).languageCode == 'fr'
                          ? context.l10n.french
                          : context.l10n.english,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: _showLanguageSheet,
                  ),
                  const Divider(height: 1, indent: 48),

                  // Notifications
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: context.l10n.notifications,
                    subtitle: context.l10n.notificationsSubtitle,
                    trailing: Switch.adaptive(
                      value: _notificationsEnabled,
                      activeTrackColor: AppColors.primary,
                      onChanged: (v) =>
                          setState(() => _notificationsEnabled = v),
                    ),
                  ),
                  const Divider(height: 1, indent: 48),

                  // Change password
                  _SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    title: context.l10n.changePassword,
                    onTap: _showChangePasswordDialog,
                  ),
                ],
              ),
            ),

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
                    iconColor: AppColors.error,
                    title: context.l10n.logout,
                    titleColor: AppColors.error,
                    onTap: _showLogoutDialog,
                  ),
                  const Divider(height: 1, indent: 48),

                  // Delete account
                  _SettingsTile(
                    icon: Icons.delete_outline_rounded,
                    iconColor: AppColors.error,
                    title: context.l10n.deleteAccount,
                    subtitle: context.l10n.deleteAccountWarning,
                    titleColor: AppColors.error,
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
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
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
// Section card
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
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
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
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    title,
                    style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              title.isEmpty ? AppSpacing.xs : 0,
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

// ---------------------------------------------------------------------------
// Language tile
// ---------------------------------------------------------------------------

class _LanguageTile extends StatelessWidget {
  final String label;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label, style: AppTextStyles.body),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded,
              color: AppColors.primary, size: 22)
          : null,
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    );
  }
}
