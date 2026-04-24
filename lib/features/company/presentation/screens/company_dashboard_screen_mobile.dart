import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/widgets/avatar_editor.dart';
import '../../../sharing/presentation/widgets/share_button.dart';
import '../../../support/data/models/support_models.dart';
import '../../../support/presentation/widgets/contact_support_dialog.dart';
import '../../data/models/gallery_photo_model.dart';
import '../../data/models/my_company_model.dart';
import '../../../shell/presentation/providers/shell_nav_provider.dart';
import '../providers/company_dashboard_provider.dart';
import '../widgets/auto_approve_card.dart';
import '../widgets/salon_geocoding_banner.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';

// ---------------------------------------------------------------------------
// Callback typedefs
// ---------------------------------------------------------------------------

typedef OnEditCompany = void Function(MyCompanyModel company);
typedef OnEditCategory = void Function(MyCategoryModel cat);
typedef OnDeleteCategory = void Function(MyCategoryModel cat);
typedef OnAddService = void Function(String categoryId);
typedef OnEditService = void Function(String categoryId, MyServiceModel svc);
typedef OnDeleteService = void Function(String categoryId, MyServiceModel svc);
typedef OnEditEmployee = void Function(
    MyEmployeeModel emp, List<MyServiceModel> allServices);
typedef OnRemoveEmployee = void Function(MyEmployeeModel emp);
typedef OnEditHours = void Function(
    MyCompanyModel company, List<String> dayLabels);
typedef OnPickAndUploadPhoto = Future<void> Function();
typedef OnDeleteGalleryPhoto = Future<void> Function(GalleryPhotoModel photo);
typedef OnReorderGalleryPhotos = Future<void> Function(
    List<GalleryPhotoModel> reordered);

// ---------------------------------------------------------------------------
// Mobile presentation
// ---------------------------------------------------------------------------

/// Mobile layout — preserves the original scrollable card list.
/// All mutations are delegated to callbacks owned by [CompanyDashboardScreen].
class CompanyDashboardScreenMobile extends ConsumerWidget {
  final OnEditCompany onEditCompany;
  final VoidCallback onAddCategory;
  final OnEditCategory onEditCategory;
  final OnDeleteCategory onDeleteCategory;
  final OnAddService onAddService;
  final OnEditService onEditService;
  final OnDeleteService onDeleteService;
  final VoidCallback onInviteEmployee;
  final VoidCallback onCreateEmployee;
  final OnEditEmployee onEditEmployee;
  final OnRemoveEmployee onRemoveEmployee;
  final OnEditHours onEditHours;
  final OnPickAndUploadPhoto onPickAndUploadPhoto;
  final OnDeleteGalleryPhoto onDeleteGalleryPhoto;
  final OnReorderGalleryPhotos onReorderGalleryPhotos;

  const CompanyDashboardScreenMobile({
    super.key,
    required this.onEditCompany,
    required this.onAddCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onAddService,
    required this.onEditService,
    required this.onDeleteService,
    required this.onInviteEmployee,
    required this.onCreateEmployee,
    required this.onEditEmployee,
    required this.onRemoveEmployee,
    required this.onEditHours,
    required this.onPickAndUploadPhoto,
    required this.onDeleteGalleryPhoto,
    required this.onReorderGalleryPhotos,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companyDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: state.isLoading && state.company == null
          ? const SkeletonDashboard()
          : state.error != null && state.company == null
              ? _MobileErrorView(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(companyDashboardProvider.notifier).load(),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: () =>
                      ref.read(companyDashboardProvider.notifier).load(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      _MobileAppBar(company: state.company),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.xxl,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (state.company != null) ...[
                              // Red warning when the salon has no Google
                              // address + no GPS — blocks proximity ranking.
                              const SalonGeocodingBanner(),
                              _MobileCompanyInfoCard(
                                company: state.company!,
                                onEdit: () =>
                                    onEditCompany(state.company!),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _MobileServicesCard(
                                company: state.company!,
                                expandedCategories: state.expandedCategories,
                                onToggleCategory: (id) => ref
                                    .read(companyDashboardProvider.notifier)
                                    .toggleCategory(id),
                                onAddCategory: onAddCategory,
                                onEditCategory: onEditCategory,
                                onDeleteCategory: onDeleteCategory,
                                onAddService: onAddService,
                                onEditService: onEditService,
                                onDeleteService: onDeleteService,
                              ),
                              // Auto-approve sits right after services so it's
                              // the first capacity-related card the owner
                              // sees — before the breaks/days-off settings.
                              if (state.company!.bookingMode ==
                                  'capacity_based') ...[
                                const SizedBox(height: AppSpacing.md),
                                AutoApproveCard(
                                  key: ref.watch(autoApproveCardKeyProvider),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              if (state.company!.bookingMode ==
                                  'capacity_based') ...[
                                _MobileCapacityCard(
                                    company: state.company!),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              if (state.company!.bookingMode ==
                                  'employee_based') ...[
                                _MobileTeamCard(
                                  company: state.company!,
                                  onInvite: onInviteEmployee,
                                  onCreate: onCreateEmployee,
                                  onEdit: onEditEmployee,
                                  onRemove: onRemoveEmployee,
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              _MobileOpeningHoursCard(
                                company: state.company!,
                                onEdit: () => onEditHours(
                                  state.company!,
                                  _getDayLabels(context),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _MobileGalleryCard(
                                onAddPhoto: onPickAndUploadPhoto,
                                onDeletePhoto: onDeleteGalleryPhoto,
                                onReorder: onReorderGalleryPhotos,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _MobileSupportCard(company: state.company!),
                            ],
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  static List<String> _getDayLabels(BuildContext context) {
    final l = context.l10n;
    return [
      l.monday,
      l.tuesday,
      l.wednesday,
      l.thursday,
      l.friday,
      l.saturday,
      l.sunday,
    ];
  }
}

// ---------------------------------------------------------------------------
// SliverAppBar
// ---------------------------------------------------------------------------

class _MobileAppBar extends ConsumerWidget {
  final MyCompanyModel? company;
  const _MobileAppBar({this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Greet the connected user by first name (pro-app convention).
    final user = ref.watch(authStateProvider.select((s) => s.user));
    final firstName = (user?.firstName.isNotEmpty ?? false)
        ? user!.firstName.titleCase
        : context.l10n.mySalon;

    // Build initials for avatar fallback.
    final initials = [
      user?.firstName.trim() ?? '',
      user?.lastName.trim() ?? '',
    ].where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();

    final avatarUrl = user?.thumbnailUrl ?? user?.profileImageUrl;

    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.cardShadow,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar 40×40 — read-only, tapping opens Settings.
          AvatarDisplay(
            photoUrl: avatarUrl,
            initials: initials,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.greetingHello,
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.textHint,
                  letterSpacing: 1.4,
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: firstName,
                      style: AppTextStyles.h3,
                    ),
                    const TextSpan(
                      text: '.',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (company != null)
          ShareIconButton(
            companyId: company!.id,
            salonName: company!.name,
            bookingMode: company!.bookingMode,
            employeeIds: {
              for (final e in company!.employees) e.userId,
            },
            showFreshBadge: true,
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppColors.divider),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section card — exported for reuse in desktop
// ---------------------------------------------------------------------------

/// Carte de section exportée — réutilisée dans le layout desktop.
///
/// Délègue intégralement à [AppCard.section] pour garantir un chrome uniforme
/// avec toutes les autres cartes de l'app (pastille ronde 40×40 ivoryAlt,
/// titre h3 Fraunces, border divider, ombre cardShadow).
class DashboardSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const DashboardSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard.section(
      title: title,
      icon: icon,
      trailing: trailing,
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Info row — exported
// ---------------------------------------------------------------------------

class DashboardInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const DashboardInfoRow({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textHint),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Company info card
// ---------------------------------------------------------------------------

class _MobileCompanyInfoCard extends ConsumerWidget {
  final MyCompanyModel company;
  final VoidCallback onEdit;

  const _MobileCompanyInfoCard({
    required this.company,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Prefer the first gallery photo (what clients actually see on the
    // public page) over the seeded profileImageUrl, which may be a generic
    // placeholder unrelated to this salon.
    final firstGalleryPhoto = ref.watch(
      companyDashboardProvider.select(
        (s) => s.galleryPhotos.isNotEmpty ? s.galleryPhotos.first : null,
      ),
    );
    final thumbUrl = firstGalleryPhoto?.displayUrl;

    return DashboardSectionCard(
      title: context.l10n.companyInfo,
      icon: Icons.storefront_rounded,
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
        tooltip: context.l10n.editProfile,
        onPressed: onEdit,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tooltip(
              message: context.l10n.salonCoverPhotoHint,
              waitDuration: const Duration(milliseconds: 300),
              preferBelow: false,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              textStyle: AppTextStyles.caption.copyWith(color: Colors.white),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.salonCoverPhotoHint),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.20)),
                  ),
                  child: thumbUrl != null && thumbUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          child: CachedNetworkImage(
                            imageUrl: thumbUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _photoIcon(),
                            errorWidget: (_, __, ___) => _photoIcon(),
                          ),
                        )
                      : _photoIcon(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company.name.titleCase, style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.xs),
                  DashboardInfoRow(
                    icon: Icons.location_on_outlined,
                    text: '${company.address}, ${company.city}',
                  ),
                  DashboardInfoRow(
                      icon: Icons.phone_outlined, text: company.phone),
                  DashboardInfoRow(
                      icon: Icons.email_outlined, text: company.email),
                  DashboardInfoRow(
                    icon: Icons.timer_off_outlined,
                    text: company.minCancelHours == 0
                        ? context.l10n.minCancelHoursNone
                        : context.l10n
                            .minCancelHoursValue(company.minCancelHours),
                  ),
                  if (company.description != null &&
                      company.description!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      company.description!,
                      style: AppTextStyles.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoIcon() => const Icon(
        Icons.storefront_rounded,
        size: 32,
        color: AppColors.primary,
      );
}

// ---------------------------------------------------------------------------
// Services card
// ---------------------------------------------------------------------------

class _MobileServicesCard extends StatelessWidget {
  final MyCompanyModel company;
  final Set<String> expandedCategories;
  final void Function(String id) onToggleCategory;
  final VoidCallback onAddCategory;
  final OnEditCategory onEditCategory;
  final OnDeleteCategory onDeleteCategory;
  final OnAddService onAddService;
  final OnEditService onEditService;
  final OnDeleteService onDeleteService;

  const _MobileServicesCard({
    required this.company,
    required this.expandedCategories,
    required this.onToggleCategory,
    required this.onAddCategory,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onAddService,
    required this.onEditService,
    required this.onDeleteService,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardSectionCard(
      title: context.l10n.servicesAndCategories,
      icon: Icons.content_cut_rounded,
      trailing: IconButton(
        icon: const Icon(Icons.add_rounded, size: 22, color: AppColors.primary),
        tooltip: context.l10n.addCategory,
        onPressed: onAddCategory,
      ),
      child: company.categories.isEmpty
          ? DashboardEmptySection(
              message: context.l10n.addCategory,
              icon: Icons.category_outlined,
            )
          : Column(
              children: company.categories
                  .map(
                    (cat) => DashboardCategoryTile(
                      category: cat,
                      isExpanded: expandedCategories.contains(cat.id),
                      onToggle: () => onToggleCategory(cat.id),
                      onEditCategory: () => onEditCategory(cat),
                      onDeleteCategory: () => onDeleteCategory(cat),
                      onAddService: () => onAddService(cat.id),
                      onEditService: (svc) => onEditService(cat.id, svc),
                      onDeleteService: (svc) =>
                          onDeleteService(cat.id, svc),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Capacity card
// ---------------------------------------------------------------------------

class _MobileCapacityCard extends StatelessWidget {
  final MyCompanyModel company;
  const _MobileCapacityCard({required this.company});

  @override
  Widget build(BuildContext context) {
    return DashboardSectionCard(
      title: context.l10n.capacitySettingsTitle,
      icon: Icons.tune_rounded,
      trailing: IconButton(
        icon: const Icon(Icons.arrow_forward_ios_rounded,
            size: 16, color: AppColors.primary),
        tooltip: context.l10n.capacitySettingsTitle,
        onPressed: () => context.goNamed(RouteNames.capacitySettings),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.tune_rounded,
                size: 20, color: AppColors.textSecondary),
            title: Text(context.l10n.capacitySettingsTitle,
                style: AppTextStyles.body),
            trailing: const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textHint),
            onTap: () => context.goNamed(RouteNames.capacitySettings),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Team card
// ---------------------------------------------------------------------------

class _MobileTeamCard extends StatelessWidget {
  final MyCompanyModel company;
  final VoidCallback onInvite;
  final VoidCallback onCreate;
  final OnEditEmployee onEdit;
  final OnRemoveEmployee onRemove;

  const _MobileTeamCard({
    required this.company,
    required this.onInvite,
    required this.onCreate,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final allServices = company.categories.expand((c) => c.services).toList();
    final firstOpenHour = company.openingHours
        .where((h) => !h.isClosed && h.openTime != null && h.closeTime != null)
        .firstOrNull;
    final companyHoursLabel = firstOpenHour != null
        ? '${firstOpenHour.openTime} - ${firstOpenHour.closeTime}'
        : null;

    return DashboardSectionCard(
      title: context.l10n.team,
      icon: Icons.people_alt_outlined,
      child: Column(
        children: [
          if (company.employees.isEmpty)
            DashboardEmptySection(
              message: context.l10n.inviteEmployee,
              icon: Icons.person_add_outlined,
            )
          else
            ...company.employees.map(
              (emp) => DashboardEmployeeTile(
                employee: emp,
                allServices: allServices,
                companyHoursLabel: companyHoursLabel,
                onEdit: () => onEdit(emp, allServices),
                onRemove: () => onRemove(emp),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    ),
                    onPressed: onInvite,
                    icon: const Icon(Icons.mail_outline_rounded, size: 16),
                    label: Text(context.l10n.inviteEmployee,
                        style: AppTextStyles.buttonSmall),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    ),
                    onPressed: onCreate,
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: Text(context.l10n.createEmployee,
                        style: AppTextStyles.buttonSmall),
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

// ---------------------------------------------------------------------------
// Opening hours card
// ---------------------------------------------------------------------------

class _MobileOpeningHoursCard extends StatelessWidget {
  final MyCompanyModel company;
  final VoidCallback onEdit;

  const _MobileOpeningHoursCard({
    required this.company,
    required this.onEdit,
  });

  static String _trimTime(String? time) {
    if (time == null) return '--:--';
    return time.length > 5 ? time.substring(0, 5) : time;
  }

  @override
  Widget build(BuildContext context) {
    final hoursMap = {for (final h in company.openingHours) h.dayOfWeek: h};
    final dayLabels = _getDayLabels(context);

    return DashboardSectionCard(
      title: context.l10n.openingHours,
      icon: Icons.access_time_rounded,
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
        tooltip: context.l10n.editProfile,
        onPressed: onEdit,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        child: Column(
          children: List.generate(7, (i) {
            final hour = hoursMap[i];
            final isClosed = hour == null || hour.isClosed;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      dayLabels[i],
                      style:
                          AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: isClosed
                        ? Text(
                            context.l10n.closed,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textHint),
                          )
                        : Text(
                            '${_trimTime(hour.openTime)} – ${_trimTime(hour.closeTime)}',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textPrimary),
                          ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isClosed
                          ? AppColors.textHint.withValues(alpha: 0.4)
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  static List<String> _getDayLabels(BuildContext context) {
    final l = context.l10n;
    return [
      l.monday,
      l.tuesday,
      l.wednesday,
      l.thursday,
      l.friday,
      l.saturday,
      l.sunday,
    ];
  }
}

// ---------------------------------------------------------------------------
// Exported shared widgets (used by desktop presentation too)
// ---------------------------------------------------------------------------

/// A category row with expand/collapse and action buttons.
class DashboardCategoryTile extends StatelessWidget {
  final MyCategoryModel category;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onEditCategory;
  final VoidCallback onDeleteCategory;
  final VoidCallback onAddService;
  final void Function(MyServiceModel) onEditService;
  final void Function(MyServiceModel) onDeleteService;

  const DashboardCategoryTile({
    super.key,
    required this.category,
    required this.isExpanded,
    required this.onToggle,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onAddService,
    required this.onEditService,
    required this.onDeleteService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppColors.textSecondary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    category.name,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${category.services.length}',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppSpacing.sm),
                DashboardItemActions(
                  onEdit: onEditCategory,
                  onDelete: onDeleteCategory,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              ...category.services.map(
                (svc) => DashboardServiceRow(
                  service: svc,
                  onEdit: () => onEditService(svc),
                  onDelete: () => onDeleteService(svc),
                ),
              ),
              InkWell(
                onTap: onAddService,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl + AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle_outline_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        context.l10n.addService,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(
          height: 1,
          thickness: 0.5,
          color: AppColors.divider,
          indent: AppSpacing.md,
        ),
      ],
    );
  }
}

/// A single service row inside a category.
class DashboardServiceRow extends StatelessWidget {
  final MyServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DashboardServiceRow({
    super.key,
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final price = service.price;
    final priceStr = price.truncateToDouble() == price
        ? '${price.toStringAsFixed(0)} €'
        : '${price.toStringAsFixed(2)} €';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl + AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(child: Text(service.name, style: AppTextStyles.body)),
          Text('${service.durationMinutes} min',
              style: AppTextStyles.bodySmall),
          const SizedBox(width: AppSpacing.sm),
          Text(
            priceStr,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          DashboardItemActions(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }
}

/// Edit + delete icon button pair.
class DashboardItemActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DashboardItemActions({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.edit_outlined,
                size: 16, color: AppColors.textSecondary),
            onPressed: onEdit,
            tooltip: context.l10n.editProfile,
          ),
        ),
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.delete_outline_rounded,
                size: 16, color: AppColors.error),
            onPressed: onDelete,
            tooltip: context.l10n.cancel,
          ),
        ),
      ],
    );
  }
}

/// Empty-state placeholder row.
class DashboardEmptySection extends StatelessWidget {
  final String message;
  final IconData icon;

  const DashboardEmptySection({
    super.key,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textHint.withValues(alpha: 0.5)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

/// Active / inactive badge.
class DashboardStatusBadge extends StatelessWidget {
  final bool isActive;
  const DashboardStatusBadge({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.textHint;
    final label = isActive ? context.l10n.active : context.l10n.inactive;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Employee tile with avatar, specialties, and action buttons.
class DashboardEmployeeTile extends StatelessWidget {
  final MyEmployeeModel employee;
  final List<MyServiceModel> allServices;
  final String? companyHoursLabel;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const DashboardEmployeeTile({
    super.key,
    required this.employee,
    required this.allServices,
    required this.onEdit,
    required this.onRemove,
    this.companyHoursLabel,
  });

  @override
  Widget build(BuildContext context) {
    final assignedServices = allServices
        .where((s) => employee.serviceIds.contains(s.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundImage:
                  employee.photoUrl != null ? NetworkImage(employee.photoUrl!) : null,
              child: employee.photoUrl == null
                  ? Text(
                      employee.fullName.isNotEmpty
                          ? employee.fullName[0].toUpperCase()
                          : '?',
                      style:
                          AppTextStyles.subtitle.copyWith(color: AppColors.primary),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.fullName, style: AppTextStyles.body),
                if (assignedServices.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: assignedServices
                        .map(
                          (s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.30),
                              ),
                            ),
                            child: Text(
                              s.name,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          DashboardStatusBadge(isActive: employee.isActive),
          const SizedBox(width: AppSpacing.xs),
          DashboardItemActions(onEdit: onEdit, onDelete: onRemove),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit employee dialog — exported (stateful, FilterChip toggles)
// ---------------------------------------------------------------------------

class DashboardEditEmployeeDialog extends StatefulWidget {
  final MyEmployeeModel employee;
  final List<MyServiceModel> allServices;
  final Future<void> Function(List<String> serviceIds) onSave;

  const DashboardEditEmployeeDialog({
    super.key,
    required this.employee,
    required this.allServices,
    required this.onSave,
  });

  @override
  State<DashboardEditEmployeeDialog> createState() =>
      _DashboardEditEmployeeDialogState();
}

class _DashboardEditEmployeeDialogState
    extends State<DashboardEditEmployeeDialog> {
  late Set<String> _selectedServiceIds;

  @override
  void initState() {
    super.initState();
    _selectedServiceIds = Set<String>.from(widget.employee.serviceIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.employee.fullName, style: AppTextStyles.h3),
      contentPadding:
          const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppTextField(
                  controller:
                      TextEditingController(text: widget.employee.email),
                  label: context.l10n.employeeEmail,
                  prefixIcon: Icons.email_outlined,
                  enabled: false,
                ),
              ),
              if (widget.allServices.isNotEmpty) ...[
                Text(
                  context.l10n.assignedServices,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: widget.allServices.map((service) {
                    final selected = _selectedServiceIds.contains(service.id);
                    return FilterChip(
                      label: Text(service.name),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedServiceIds.add(service.id);
                          } else {
                            _selectedServiceIds.remove(service.id);
                          }
                        });
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      side: BorderSide(
                        color: selected ? AppColors.primary : AppColors.divider,
                      ),
                      labelStyle: AppTextStyles.caption.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      backgroundColor: AppColors.surface,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () => widget.onSave(_selectedServiceIds.toList()),
          child: Text(context.l10n.saveChanges),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Opening hours display helper — exported
// ---------------------------------------------------------------------------

class DashboardOpeningHoursDisplay extends StatelessWidget {
  final MyCompanyModel company;
  final List<String> dayLabels;

  const DashboardOpeningHoursDisplay({
    super.key,
    required this.company,
    required this.dayLabels,
  });

  static String _trimTime(String? time) {
    if (time == null) return '--:--';
    return time.length > 5 ? time.substring(0, 5) : time;
  }

  @override
  Widget build(BuildContext context) {
    final hoursMap = {for (final h in company.openingHours) h.dayOfWeek: h};

    return Column(
      children: List.generate(7, (i) {
        final hour = hoursMap[i];
        final isClosed = hour == null || hour.isClosed;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  dayLabels[i],
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: isClosed
                    ? Text(
                        context.l10n.closed,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textHint),
                      )
                    : Text(
                        '${_trimTime(hour.openTime)} – ${_trimTime(hour.closeTime)}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textPrimary),
                      ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isClosed
                      ? AppColors.textHint.withValues(alpha: 0.4)
                      : AppColors.success,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Hours edit dialog — exported (stateful)
// ---------------------------------------------------------------------------

class DashboardHoursEditDialog extends StatefulWidget {
  final List<OpeningHourModel> hours;
  final List<String> dayLabels;
  final void Function(List<OpeningHourModel>) onSave;

  const DashboardHoursEditDialog({
    super.key,
    required this.hours,
    required this.dayLabels,
    required this.onSave,
  });

  @override
  State<DashboardHoursEditDialog> createState() =>
      _DashboardHoursEditDialogState();
}

class _DashboardHoursEditDialogState extends State<DashboardHoursEditDialog> {
  late List<OpeningHourModel> _hours;

  @override
  void initState() {
    super.initState();
    _hours = widget.hours.map((h) => h.copyWith()).toList();
  }

  Future<void> _pickTime(int index, bool isOpen) async {
    final hour = _hours[index];
    final initial = _parseTime(isOpen ? hour.openTime : hour.closeTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      _hours[index] = isOpen
          ? _hours[index].copyWith(openTime: formatted)
          : _hours[index].copyWith(closeTime: formatted);
    });
  }

  TimeOfDay _parseTime(String? time) {
    if (time == null) return const TimeOfDay(hour: 9, minute: 0);
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.openingHours, style: AppTextStyles.h3),
      contentPadding:
          const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(7, (i) {
              final hour = _hours[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 78,
                      child: Text(widget.dayLabels[i],
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w500)),
                    ),
                    Switch(
                      value: !hour.isClosed,
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.40),
                      onChanged: (val) => setState(() {
                        if (val) {
                          _hours[i] = hour.copyWith(
                            isClosed: false,
                            openTime: hour.openTime ?? '09:00',
                            closeTime: hour.closeTime ?? '18:00',
                          );
                        } else {
                          _hours[i] = hour.copyWith(isClosed: true);
                        }
                      }),
                    ),
                    if (!hour.isClosed) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickTime(i, true),
                          child: _TimeChip(time: hour.openTime ?? '09:00'),
                        ),
                      ),
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                        child:
                            Text('–', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickTime(i, false),
                          child: _TimeChip(time: hour.closeTime ?? '18:00'),
                        ),
                      ),
                    ] else
                      Expanded(
                        child: Text(context.l10n.closed,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textHint)),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () => widget.onSave(_hours),
          child: Text(context.l10n.saveChanges),
        ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  const _TimeChip({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.30)),
      ),
      child: Text(
        time,
        style: AppTextStyles.bodySmall
            .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exported global dialog helpers
// ---------------------------------------------------------------------------

void dashboardShowNameDialog({
  required BuildContext context,
  required String title,
  required String label,
  required TextEditingController controller,
  required VoidCallback onSave,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: AppTextStyles.h3),
      contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      content: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: AppTextField(controller: controller, label: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(ctx.l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: onSave,
          child: Text(ctx.l10n.saveChanges),
        ),
      ],
    ),
  );
}

void dashboardShowConfirmDialog({
  required BuildContext context,
  required String title,
  required VoidCallback onConfirm,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: AppTextStyles.h3),
      content: Text(context.l10n.deleteAccountWarning, style: AppTextStyles.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(context.l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: onConfirm,
          child: Text(context.l10n.confirm),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Gallery card — exported for desktop reuse
// ---------------------------------------------------------------------------

/// Reorderable grid of gallery thumbnails with add / delete actions.
/// Uses Flutter's built-in [ReorderableListView] wrapped in a horizontal
/// scroll for the grid — no extra package needed.
class _MobileGalleryCard extends ConsumerWidget {
  final OnPickAndUploadPhoto onAddPhoto;
  final OnDeleteGalleryPhoto onDeletePhoto;
  final OnReorderGalleryPhotos onReorder;

  const _MobileGalleryCard({
    required this.onAddPhoto,
    required this.onDeletePhoto,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryState = ref.watch(
      companyDashboardProvider.select(
        (s) => (
          photos: s.galleryPhotos,
          loading: s.galleryLoading,
          uploading: s.galleryUploading,
          progress: s.galleryUploadProgress,
          error: s.galleryError,
        ),
      ),
    );

    return DashboardSectionCard(
      title: context.l10n.gallery,
      icon: Icons.photo_library_outlined,
      trailing: galleryState.uploading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined,
                  size: 22, color: AppColors.primary),
              tooltip: context.l10n.galleryAddPhoto,
              onPressed: onAddPhoto,
            ),
      child: _GalleryCardBody(
        photos: galleryState.photos,
        loading: galleryState.loading,
        uploading: galleryState.uploading,
        uploadProgress: galleryState.progress,
        error: galleryState.error,
        onDeletePhoto: onDeletePhoto,
        onReorder: onReorder,
        onAddPhoto: onAddPhoto,
      ),
    );
  }
}

class _GalleryCardBody extends StatelessWidget {
  final List<GalleryPhotoModel> photos;
  final bool loading;
  final bool uploading;
  final double? uploadProgress;
  final String? error;
  final OnDeleteGalleryPhoto onDeletePhoto;
  final OnReorderGalleryPhotos onReorder;
  final OnPickAndUploadPhoto onAddPhoto;

  const _GalleryCardBody({
    required this.photos,
    required this.loading,
    required this.uploading,
    required this.uploadProgress,
    required this.error,
    required this.onDeletePhoto,
    required this.onReorder,
    required this.onAddPhoto,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (error != null && photos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 18, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                context.l10n.galleryUploadError,
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    if (photos.isEmpty && !uploading) {
      return GestureDetector(
        onTap: onAddPhoto,
        child: DashboardEmptySection(
          message: context.l10n.galleryEmpty,
          icon: Icons.add_photo_alternate_outlined,
        ),
      );
    }

    // Upload progress banner — shown above the grid while uploading.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (uploading) _UploadProgressBanner(progress: uploadProgress),
        // Context sentence: clarifies that order drives what clients see.
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.l10n.galleryOrderExplanation,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        _GalleryReorderableGrid(
          photos: photos,
          onDeletePhoto: onDeletePhoto,
          onReorder: onReorder,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
          child: Text(
            context.l10n.galleryReorderHint,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadProgressBanner extends StatelessWidget {
  final double? progress;
  const _UploadProgressBanner({this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.galleryUploading,
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.divider,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

/// The reorderable photo grid — exported so the desktop card can reuse it.
class _GalleryReorderableGrid extends StatefulWidget {
  final List<GalleryPhotoModel> photos;
  final OnDeleteGalleryPhoto onDeletePhoto;
  final OnReorderGalleryPhotos onReorder;

  const _GalleryReorderableGrid({
    required this.photos,
    required this.onDeletePhoto,
    required this.onReorder,
  });

  @override
  State<_GalleryReorderableGrid> createState() =>
      _GalleryReorderableGridState();
}

class _GalleryReorderableGridState extends State<_GalleryReorderableGrid> {
  late List<GalleryPhotoModel> _photos;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.photos);
  }

  @override
  void didUpdateWidget(covariant _GalleryReorderableGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photos != widget.photos) {
      _photos = List.from(widget.photos);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, item);
    });
    widget.onReorder(_photos);
  }

  @override
  Widget build(BuildContext context) {
    // Horizontal scrollable row — each thumb is 96x96.
    return SizedBox(
      height: 96 + AppSpacing.md * 2,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        buildDefaultDragHandles: false,
        onReorder: _onReorder,
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Material(
                color: Colors.transparent,
                elevation: 8 * animation.value,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: child,
              );
            },
            child: child,
          );
        },
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          final photo = _photos[index];
          return ReorderableDragStartListener(
            key: ValueKey(photo.id),
            index: index,
            child: _GalleryThumb(
              photo: photo,
              onDelete: () => _confirmDelete(context, photo),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, GalleryPhotoModel photo) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.galleryDelete, style: AppTextStyles.h3),
        content:
            Text(context.l10n.galleryDeleteConfirm, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDeletePhoto(photo);
            },
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );
  }
}

class _GalleryThumb extends StatelessWidget {
  final GalleryPhotoModel photo;
  final VoidCallback onDelete;

  const _GalleryThumb({required this.photo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.20)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: CachedNetworkImage(
                imageUrl: photo.displayUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ),
          // Delete button — top-right, 32×32 (≥ 48dp effective area via hitSlop)
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Drag handle overlay — centered pill at the bottom, clearly
          // inside the thumb so users know the whole tile is draggable.
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.drag_handle_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exported gallery card (desktop reuses the same card body logic)
// ---------------------------------------------------------------------------

/// Exported gallery card for the desktop layout.
/// Desktop shows a wider grid (up to 6 thumbs visible without scrolling).
class DashboardGalleryCard extends ConsumerWidget {
  final OnPickAndUploadPhoto onAddPhoto;
  final OnDeleteGalleryPhoto onDeletePhoto;
  final OnReorderGalleryPhotos onReorder;

  const DashboardGalleryCard({
    super.key,
    required this.onAddPhoto,
    required this.onDeletePhoto,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryState = ref.watch(
      companyDashboardProvider.select(
        (s) => (
          photos: s.galleryPhotos,
          loading: s.galleryLoading,
          uploading: s.galleryUploading,
          progress: s.galleryUploadProgress,
          error: s.galleryError,
        ),
      ),
    );

    return _GalleryCardBody(
      photos: galleryState.photos,
      loading: galleryState.loading,
      uploading: galleryState.uploading,
      uploadProgress: galleryState.progress,
      error: galleryState.error,
      onDeletePhoto: onDeletePhoto,
      onReorder: onReorder,
      onAddPhoto: onAddPhoto,
    );
  }
}

// ---------------------------------------------------------------------------
// Error view
// ---------------------------------------------------------------------------

class _MobileErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _MobileErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.error, style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Support card — mobile
// ---------------------------------------------------------------------------

class _MobileSupportCard extends ConsumerWidget {
  final MyCompanyModel company;
  const _MobileSupportCard({required this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => showContactSupportDialog(
          context,
          ref: ref,
          sourcePage: SupportSourcePage.myCompany,
          sourceContext: {'companyId': company.id},
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(Icons.headset_mic_rounded,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.contactSupport,
                      style: AppTextStyles.subtitle
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.supportSubtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
