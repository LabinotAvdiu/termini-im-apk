import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/notifications/models/in_app_notification.dart';
import '../../../../core/notifications/providers/in_app_notification_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/language_sheet.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/providers/ux_prefs_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/personal_gender_selector.dart';
import '../../../company/presentation/providers/company_dashboard_provider.dart';
import '../../../notifications/presentation/providers/notifications_log_provider.dart';
import '../../../notifications/presentation/widgets/fcm_diagnostic_section.dart';
import '../../../notifications/presentation/widgets/notification_preferences_section.dart';
import '../../../profile/presentation/widgets/avatar_editor.dart';
import '../../../support/data/models/support_models.dart';
import '../../../support/presentation/widgets/contact_support_dialog.dart';
import '../widgets/delete_account_modal.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  /// When true, the "Mon profil" section opens directly in edit mode.
  /// Used by the "Complete your profile" banner on /home so the user lands
  /// with the phone / gender inputs ready instead of on a read-only view.
  final bool startInProfileEdit;

  const SettingsScreen({super.key, this.startInProfileEdit = false});

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
  late bool _isEditingProfile = widget.startInProfileEdit;

  // Anchor keys — used by the desktop sidebar to scroll-to-section when
  // the user clicks a nav item. Ignored on mobile (single column layout).
  final _profileAnchor = GlobalKey();
  final _pagesAnchor = GlobalKey();
  final _ownerSpaceAnchor = GlobalKey();
  final _settingsAnchor = GlobalKey();
  final _experienceAnchor = GlobalKey();
  final _notificationsAnchor = GlobalKey();
  final _supportAnchor = GlobalKey();
  final _dangerAnchor = GlobalKey();

  Future<void> _scrollToAnchor(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
      alignment: 0.02,
    );
  }

  // Original values to detect changes
  late String _origFirstName;
  late String _origLastName;
  late String _origPhone;
  String? _origGender;

  /// Editable personal gender — 'men' / 'women' / null.
  String? _gender;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    _origFirstName = user?.firstName ?? '';
    _origLastName = user?.lastName ?? '';
    _origPhone = user?.phone ?? '';
    _origGender = user?.gender;
    _gender = _origGender;

    _firstNameController = TextEditingController(text: _origFirstName);
    _lastNameController = TextEditingController(text: _origLastName);
    _phoneController = TextEditingController(text: _origPhone);

    _firstNameController.addListener(_checkChanges);
    _lastNameController.addListener(_checkChanges);
    _phoneController.addListener(_checkChanges);
  }

  static String _computeInitials(String first, String last) {
    final parts = [first.trim(), last.trim()].where((w) => w.isNotEmpty);
    return parts.take(2).map((w) => w[0].toUpperCase()).join();
  }

  void _checkChanges() {
    final changed = _firstNameController.text != _origFirstName ||
        _lastNameController.text != _origLastName ||
        _phoneController.text != _origPhone ||
        _gender != _origGender;
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
        'gender': _gender,
      });

      if (!mounted) return;

      ref.read(authStateProvider.notifier).updateUser(updatedUser);

      // Update originals so button hides
      _origFirstName = _firstNameController.text;
      _origLastName = _lastNameController.text;
      _origPhone = _phoneController.text;
      _origGender = _gender;

      setState(() {
        _isSaving = false;
        _hasChanges = false;
        _isEditingProfile = false;
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
              // Reset locale so the next guest session defaults to SQ
              // instead of inheriting the previous user's preference.
              ref.read(localeProvider.notifier).reset();
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
                    requiredMessage: context.l10n.passwordRequired,
                    tooShortMessage: context.l10n.passwordTooShort,
                    needsUpperMessage: context.l10n.passwordNeedsUpper,
                    needsLowerMessage: context.l10n.passwordNeedsLower,
                    needsNumberMessage: context.l10n.passwordNeedsNumber),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: newPwController,
                label: context.l10n.newPassword,
                obscureText: true,
                prefixIcon: Icons.lock_rounded,
                validator: (v) => Validators.password(v,
                    requiredMessage: context.l10n.passwordRequired,
                    tooShortMessage: context.l10n.passwordTooShort,
                    needsUpperMessage: context.l10n.passwordNeedsUpper,
                    needsLowerMessage: context.l10n.passwordNeedsLower,
                    needsNumberMessage: context.l10n.passwordNeedsNumber),
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
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar.standard(
        title: context.l10n.settingsTitle,
        onBack: () => context.go('/home'),
      ),
      body: isDesktop ? _buildDesktop(context) : _buildMobile(context),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: _buildSections(context),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left sidebar — 260px, sticky once scrolled
            SizedBox(
              width: 260,
              child: _DesktopSidebar(
                onProfile: () => _scrollToAnchor(_profileAnchor),
                onPages: () => _scrollToAnchor(_pagesAnchor),
                onOwnerSpace: () => _scrollToAnchor(_ownerSpaceAnchor),
                onSettings: () => _scrollToAnchor(_settingsAnchor),
                onExperience: () => _scrollToAnchor(_experienceAnchor),
                onNotifications: () => _scrollToAnchor(_notificationsAnchor),
                onSupport: () => _scrollToAnchor(_supportAnchor),
                onDanger: () => _scrollToAnchor(_dangerAnchor),
              ),
            ),
            // Right content — scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl + AppSpacing.sm,
                  vertical: AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildSections(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context) {
    // We keep the original large children tree below; each top-level block
    // that the desktop sidebar targets is wrapped in a KeyedSubtree so
    // Scrollable.ensureVisible can reach it.
    return [
            // ── Section "Mon profil" ─────────────────────────────────────
            KeyedSubtree(
              key: _profileAnchor,
              child: Builder(
              builder: (context) {
                final authUser = ref.watch(authStateProvider).user;
                final isPro = (authUser?.companyRole ?? '').isNotEmpty;
                final initials = _computeInitials(
                  _firstNameController.text,
                  _lastNameController.text,
                );
                return _SectionCard(
                  title: context.l10n.myProfile,
                  icon: Icons.person_outline_rounded,
                  trailing: _ProfileEditToggle(
                    editing: _isEditingProfile,
                    onPressed: () {
                      setState(() {
                        if (_isEditingProfile) {
                          // Cancel — reset fields to originals
                          _firstNameController.text = _origFirstName;
                          _lastNameController.text = _origLastName;
                          _phoneController.text = _origPhone;
                          _gender = _origGender;
                          _hasChanges = false;
                        }
                        _isEditingProfile = !_isEditingProfile;
                      });
                    },
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        if (isPro)
                          AvatarEditor(
                            size: 120,
                            initials: initials,
                          )
                        else
                          AvatarDisplay(
                            size: 120,
                            initials: initials,
                            photoUrl: authUser?.thumbnailUrl ??
                                authUser?.profileImageUrl,
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          authUser?.email ?? '',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        if (_isEditingProfile) ...[
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
                          const SizedBox(height: AppSpacing.md),
                          PersonalGenderSelector(
                            value: _gender,
                            onChanged: (g) {
                              setState(() => _gender = g);
                              _checkChanges();
                            },
                          ),
                          if (_hasChanges) ...[
                            const SizedBox(height: AppSpacing.lg),
                            AppButton(
                              text: context.l10n.saveChanges,
                              isLoading: _isSaving,
                              onPressed: _saveChanges,
                              width: double.infinity,
                            ),
                          ],
                        ] else ...[
                          _ProfileReadRow(
                            icon: Icons.person_outline,
                            label: context.l10n.fullName,
                            value: [
                              _firstNameController.text,
                              _lastNameController.text,
                            ].where((s) => s.trim().isNotEmpty).join(' '),
                          ),
                          const Divider(
                              height: 1, color: AppColors.divider, indent: 44),
                          _ProfileReadRow(
                            icon: Icons.phone_outlined,
                            label: context.l10n.phone,
                            value: _phoneController.text.trim(),
                          ),
                          if (_gender != null) ...[
                            const Divider(
                                height: 1,
                                color: AppColors.divider,
                                indent: 44),
                            _ProfileReadRow(
                              icon: _gender == 'women'
                                  ? Icons.female_rounded
                                  : Icons.male_rounded,
                              label: context.l10n.gender,
                              value: _gender == 'women'
                                  ? context.l10n.personalGenderWomen
                                  : context.l10n.personalGenderMen,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            ),

            // ── Mes pages (navigation vers d'autres vues) ─────────────────
            KeyedSubtree(
              key: _pagesAnchor,
              child: const _MyPagesSection(),
            ),

            // ── Espace propriétaire (horaires + pauses) ───────────────────
            KeyedSubtree(
              key: _ownerSpaceAnchor,
              child: const _OwnerSpaceSection(),
            ),

            const SizedBox(height: AppSpacing.md),

            // Settings options
            KeyedSubtree(
              key: _settingsAnchor,
              child: _SectionCard(
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
            ),

            // ── Section Expérience — haptic, sons, animations ──────────────
            const SizedBox(height: AppSpacing.md),
            KeyedSubtree(
              key: _experienceAnchor,
              child: _UxPrefsSection(),
            ),

            // Section Notifications — préférences uniquement pour owner et employee.
            // Les clients (UserRole.user) n'ont pas de préférences configurables :
            // leurs notifications sont toutes forcées côté serveur.
            // Le diagnostic FCM est montré à TOUS les rôles — c'est l'outil
            // qui aide l'utilisateur à comprendre pourquoi il ne reçoit pas
            // de push malgré la permission accordée.
            const SizedBox(height: AppSpacing.md),
            KeyedSubtree(
              key: _notificationsAnchor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ref.watch(authStateProvider.select((s) => !s.isClient)))
                    const NotificationPreferencesSection(),
                  if (ref.watch(authStateProvider.select((s) => !s.isClient)))
                    const SizedBox(height: AppSpacing.sm),
                  const FcmDiagnosticSection(),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Help & Support
            KeyedSubtree(
              key: _supportAnchor,
              child: _SectionCard(
              title: '',
              icon: null,
              child: _SettingsTile(
                icon: Icons.help_outline_rounded,
                title: context.l10n.helpAndSupport,
                subtitle: context.l10n.contactSupport,
                onTap: () => showContactSupportDialog(
                  context,
                  ref: ref,
                  sourcePage: SupportSourcePage.settings,
                ),
              ),
            ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Section debug — uniquement en mode kDebugMode ──────────────
            if (kDebugMode)
              _InAppNotifDebugSection(),

            if (kDebugMode)
              const SizedBox(height: AppSpacing.md),

            // Danger zone
            KeyedSubtree(
              key: _dangerAnchor,
              child: _SectionCard(
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
                    onTap: () => showDeleteAccountModal(context),
                  ),
                ],
              ),
            ),
            ),

            const SizedBox(height: AppSpacing.xxl),
    ];
  }
}

// ---------------------------------------------------------------------------
// Section card — editorial: 1px border, Fraunces section heading + overline
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    // Chrome aligné sur AppCard : divider (pas border), ombre cardShadow,
    // radius 16. L'accent éditorial (gradient stripe + _EditorialTitle) est
    // conservé comme signature propre à la page Réglages.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            // Mince liseré bourgogne — accent éditorial propre à Settings.
            Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
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
                    // Pastille ronde 40×40 ivoryAlt — alignée sur AppCard.
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.ivoryAlt,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 20, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: _EditorialTitle(title),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ],
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(
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
    // Pastille ronde 40×40 ivoryAlt (cas normal) ou colorée (cas danger/accent).
    final resolvedIconColor = iconColor ?? AppColors.textPrimary;
    final pillBg = iconColor != null
        ? iconColor!.withValues(alpha: 0.10)
        : AppColors.ivoryAlt;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: pillBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: resolvedIconColor,
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
// _UxPrefsSection — section Expérience dans Settings
// ---------------------------------------------------------------------------

class _UxPrefsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(uxPrefsProvider);

    return _SectionCard(
      title: context.l10n.experienceSection,
      icon: Icons.auto_awesome_rounded,
      child: Column(
        children: [
          // Vibrations
          _SettingsTile(
            icon: Icons.vibration_rounded,
            title: context.l10n.hapticLabel,
            subtitle: context.l10n.hapticDesc,
            trailing: Switch.adaptive(
              value: prefs.hapticEnabled,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
              onChanged: (v) =>
                  ref.read(uxPrefsProvider.notifier).setHaptic(v),
            ),
          ),
          const Divider(
            height: 1,
            color: AppColors.divider,
            indent: 48,
          ),

          // Sons de l'interface
          _SettingsTile(
            icon: Icons.music_note_rounded,
            title: context.l10n.soundsLabel,
            subtitle: context.l10n.soundsDesc,
            trailing: Switch.adaptive(
              value: prefs.soundsEnabled,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
              onChanged: (v) =>
                  ref.read(uxPrefsProvider.notifier).setSounds(v),
            ),
          ),
          const Divider(
            height: 1,
            color: AppColors.divider,
            indent: 48,
          ),

          // Animations
          _SettingsTile(
            icon: Icons.animation_rounded,
            title: context.l10n.animationsLabel,
            subtitle: context.l10n.animationsDesc,
            trailing: Switch.adaptive(
              value: prefs.animationsEnabled,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
              onChanged: (v) =>
                  ref.read(uxPrefsProvider.notifier).setAnimations(v),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile section helpers — view mode rows + edit/cancel toggle
// ---------------------------------------------------------------------------

class _ProfileReadRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileReadRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textHint),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: AppTextStyles.body.copyWith(
                    color: value.isEmpty
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
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

class _ProfileEditToggle extends StatelessWidget {
  final bool editing;
  final VoidCallback onPressed;
  const _ProfileEditToggle({required this.editing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 4, vertical: AppSpacing.xs),
        minimumSize: const Size(0, 32),
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(
        editing ? Icons.close_rounded : Icons.edit_outlined,
        size: 16,
      ),
      label: Text(
        editing ? context.l10n.cancel : context.l10n.edit,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mes pages — navigation hub for pro users (Mes rendez-vous, notifications
// inbox, messages). Hidden for regular clients since bottom nav already
// surfaces what they need.
// ---------------------------------------------------------------------------

class _MyPagesSection extends ConsumerWidget {
  const _MyPagesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCompany = ref.watch(
      authStateProvider.select((s) => s.isOwner || s.isEmployee),
    );
    if (!hasCompany) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: _SectionCard(
        title: context.l10n.myPagesSection,
        icon: Icons.apps_rounded,
        child: Column(
          children: [
            _SettingsTile(
              icon: Icons.calendar_month_rounded,
              title: context.l10n.myAppointments,
              onTap: () => context.goNamed(RouteNames.myAppointments),
            ),
            const Divider(
                height: 1, color: AppColors.divider, indent: 48),
            _MyNotificationsTile(),
            const Divider(
                height: 1, color: AppColors.divider, indent: 48),
            _SettingsTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: context.l10n.messages,
              subtitle: context.l10n.messagesSubtitle,
              trailing: _ComingSoonBadge(),
              onTap: () => _showComingSoon(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile "Mes notifications" — affiche le compteur unread depuis le provider,
// navigue vers l'écran dédié /notifications.
// ---------------------------------------------------------------------------

class _MyNotificationsTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MyNotificationsTile> createState() =>
      _MyNotificationsTileState();
}

class _MyNotificationsTileState extends ConsumerState<_MyNotificationsTile> {
  @override
  void initState() {
    super.initState();
    // Charge l'historique en arrière-plan pour que le badge s'affiche même
    // sans avoir ouvert l'inbox au préalable.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsLogProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(
      notificationsLogProvider.select((s) => s.unreadCount),
    );

    return _SettingsTile(
      icon: Icons.notifications_none_rounded,
      title: context.l10n.myNotifications,
      trailing: unread > 0
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unread > 99 ? '99+' : unread.toString(),
                style: AppTextStyles.buttonSmall.copyWith(
                  color: AppColors.background,
                  letterSpacing: 0.2,
                ),
              ),
            )
          : null,
      onTap: () => context.goNamed(RouteNames.notificationsInbox),
    );
  }
}

// ---------------------------------------------------------------------------
// Espace propriétaire — horaires + pauses pour les pros en mode individuel.
// En mode capacité, tout est géré au niveau salon dans "Mon salon".
// ---------------------------------------------------------------------------

class _OwnerSpaceSection extends ConsumerWidget {
  const _OwnerSpaceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final isEmployee = auth.isEmployee;
    // Only owners read the dashboard provider — employees always live in
    // individual mode (capacity mode has no employees).
    final bookingMode = auth.isOwner
        ? ref.watch(
            companyDashboardProvider
                .select((s) => s.company?.bookingMode ?? 'employee_based'),
          )
        : 'employee_based';
    final isIndividual = (auth.isOwner || isEmployee) &&
        bookingMode == 'employee_based';

    if (!isIndividual) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: _SectionCard(
        title: context.l10n.ownerSpaceSection,
        icon: Icons.schedule_rounded,
        child: Column(
          children: [
            _SettingsTile(
              icon: Icons.event_available_rounded,
              title: context.l10n.myScheduleEntry,
              subtitle: context.l10n.myScheduleEntrySubtitle,
              onTap: () => context.goNamed(RouteNames.mySchedule),
            ),
            const Divider(
                height: 1, color: AppColors.divider, indent: 48),
            _SettingsTile(
              icon: Icons.coffee_outlined,
              title: context.l10n.myBreaksEntry,
              subtitle: context.l10n.myBreaksEntrySubtitle,
              onTap: () => context.goNamed(RouteNames.myBreaks),
            ),
          ],
        ),
      ),
    );
  }
}

void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(context.l10n.comingSoonMessage),
      ),
    );
}

class _ComingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        context.l10n.comingSoon.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.secondaryDark,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          fontSize: 9,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editorial section title — Fraunces with the last word in italic bordeaux
// when the title has at least two words. Single-word titles stay upright.
// ---------------------------------------------------------------------------

class _EditorialTitle extends StatelessWidget {
  final String text;
  const _EditorialTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    // Split on the last whitespace to isolate prefix + accent suffix.
    final lastSpace = trimmed.lastIndexOf(' ');
    final base = GoogleFonts.fraunces(
      fontSize: 19,
      fontWeight: FontWeight.w500,
      height: 1.15,
      letterSpacing: -0.2,
      color: AppColors.textPrimary,
    );

    if (lastSpace <= 0) {
      return Text(trimmed, style: base);
    }

    final prefix = trimmed.substring(0, lastSpace + 1);
    final accent = trimmed.substring(lastSpace + 1);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: prefix),
          TextSpan(
            text: accent,
            style: GoogleFonts.instrumentSerif(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: AppColors.primary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop sidebar — sticky left column with profile mini card + nav anchors.
// Each item scrolls the right-hand content to the matching section.
// ---------------------------------------------------------------------------

class _DesktopSidebar extends ConsumerWidget {
  final VoidCallback onProfile;
  final VoidCallback onPages;
  final VoidCallback onOwnerSpace;
  final VoidCallback onSettings;
  final VoidCallback onExperience;
  final VoidCallback onNotifications;
  final VoidCallback onSupport;
  final VoidCallback onDanger;

  const _DesktopSidebar({
    required this.onProfile,
    required this.onPages,
    required this.onOwnerSpace,
    required this.onSettings,
    required this.onExperience,
    required this.onNotifications,
    required this.onSupport,
    required this.onDanger,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.user;
    final isPro = auth.isOwner || auth.isEmployee;
    final isClient = auth.isClient || auth.isGuest;
    final roleLabel = isPro
        ? (auth.isOwner ? 'Owner' : 'Pro')
        : context.l10n.myAppointments;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SidebarProfileCard(
              initials: _initialsFor(user?.firstName, user?.lastName),
              name: (user?.firstName.isNotEmpty ?? false)
                  ? '${user!.firstName} ${user.lastName}'.trim()
                  : context.l10n.myProfile,
              role: roleLabel,
            ),
            const SizedBox(height: AppSpacing.lg),
            _SidebarNavItem(
              icon: Icons.person_outline_rounded,
              label: context.l10n.myProfile,
              onTap: onProfile,
            ),
            if (isPro) ...[
              _SidebarNavItem(
                icon: Icons.apps_rounded,
                label: context.l10n.myPagesSection,
                onTap: onPages,
              ),
              _SidebarNavItem(
                icon: Icons.schedule_rounded,
                label: context.l10n.ownerSpaceSection,
                onTap: onOwnerSpace,
              ),
            ],
            _SidebarNavItem(
              icon: Icons.tune_rounded,
              label: context.l10n.settingsTitle,
              onTap: onSettings,
            ),
            _SidebarNavItem(
              icon: Icons.auto_awesome_rounded,
              label: context.l10n.experienceSection,
              onTap: onExperience,
            ),
            if (!isClient)
              _SidebarNavItem(
                icon: Icons.notifications_none_rounded,
                label: context.l10n.notifications,
                onTap: onNotifications,
              ),
            _SidebarNavItem(
              icon: Icons.help_outline_rounded,
              label: context.l10n.helpAndSupport,
              onTap: onSupport,
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppSpacing.sm),
            _SidebarNavItem(
              icon: Icons.logout_rounded,
              label: context.l10n.logout,
              color: AppColors.primary,
              onTap: onDanger,
            ),
          ],
        ),
      ),
    );
  }

  String _initialsFor(String? first, String? last) {
    final f = (first ?? '').trim();
    final l = (last ?? '').trim();
    final initials = [
      if (f.isNotEmpty) f[0],
      if (l.isNotEmpty) l[0],
    ].take(2).join();
    return initials.isEmpty ? '•' : initials.toUpperCase();
  }
}

class _SidebarProfileCard extends StatelessWidget {
  final String initials;
  final String name;
  final String role;

  const _SidebarProfileCard({
    required this.initials,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              initials,
              style: GoogleFonts.fraunces(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fraunces(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                Text(
                  role.toUpperCase(),
                  style: GoogleFonts.instrumentSans(
                    fontSize: 9,
                    letterSpacing: 1.8,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
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

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? AppColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: resolved.withValues(alpha: 0.85)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: resolved,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// DEBUG — Section de test des notifications in-app (kDebugMode uniquement)
// ---------------------------------------------------------------------------

class _InAppNotifDebugSection extends ConsumerWidget {
  const _InAppNotifDebugSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(inAppNotificationProvider.notifier);

    void showVariant({
      required String title,
      required String body,
      required InAppNotificationVariant variant,
      required IconData icon,
    }) {
      notifier.show(
        InAppNotification(
          title: title,
          body: body,
          variant: variant,
          icon: icon,
          onTap: () => debugPrint('[DEBUG] Notif in-app tappée : $title'),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: AppColors.secondary.withValues(alpha: 0.04),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.bug_report_rounded,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'DEBUG — Notifications in-app',
                style: GoogleFonts.instrumentSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Visible uniquement en mode debug. Teste les 3 variants + rafale.',
            style: GoogleFonts.instrumentSans(
              fontSize: 11,
              color: AppColors.textHint,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Boutons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Variant positive
              _DebugNotifButton(
                label: 'Positive',
                color: AppColors.secondary,
                onTap: () => showVariant(
                  title: 'Rendez-vous confirmé',
                  body: 'Votre RDV avec Salon Elite est confirmé pour demain à 14h30.',
                  variant: InAppNotificationVariant.positive,
                  icon: Icons.event_available_rounded,
                ),
              ),

              // Variant info
              _DebugNotifButton(
                label: 'Info',
                color: AppColors.primary,
                onTap: () => showVariant(
                  title: 'Nouvel avis 5 étoiles',
                  body: 'Un client a laissé un avis excellent sur votre salon.',
                  variant: InAppNotificationVariant.info,
                  icon: Icons.star_rounded,
                ),
              ),

              // Variant attention
              _DebugNotifButton(
                label: 'Attention',
                color: AppColors.primaryDark,
                onTap: () => showVariant(
                  title: 'RDV annulé',
                  body: 'Alexandre Martin a annulé son rendez-vous du 24 avril.',
                  variant: InAppNotificationVariant.attention,
                  icon: Icons.event_busy_rounded,
                ),
              ),

              // Rafale (3 notifs d'un coup)
              _DebugNotifButton(
                label: 'Rafale ×4',
                color: AppColors.textHint,
                onTap: () {
                  showVariant(
                    title: 'Rafale 1/4 — RDV confirmé',
                    body: 'Premier push de la rafale.',
                    variant: InAppNotificationVariant.positive,
                    icon: Icons.event_available_rounded,
                  );
                  Future.delayed(const Duration(milliseconds: 100), () {
                    showVariant(
                      title: 'Rafale 2/4 — Nouvel avis',
                      body: 'Deuxième push de la rafale.',
                      variant: InAppNotificationVariant.info,
                      icon: Icons.star_rounded,
                    );
                  });
                  Future.delayed(const Duration(milliseconds: 200), () {
                    showVariant(
                      title: 'Rafale 3/4 — Walk-in',
                      body: 'Troisième push de la rafale.',
                      variant: InAppNotificationVariant.attention,
                      icon: Icons.person_add_rounded,
                    );
                  });
                  Future.delayed(const Duration(milliseconds: 300), () {
                    showVariant(
                      title: 'Rafale 4/4 — En queue',
                      body: 'Ce toast attend qu\'un slot se libère.',
                      variant: InAppNotificationVariant.info,
                      icon: Icons.notifications_active_rounded,
                    );
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebugNotifButton extends StatelessWidget {
  const _DebugNotifButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.instrumentSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

