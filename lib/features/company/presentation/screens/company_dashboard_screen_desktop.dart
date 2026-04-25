import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/widgets/avatar_editor.dart';
import '../../../reviews/data/models/review_model.dart';
import '../../../reviews/presentation/providers/review_provider.dart';
import '../../../sharing/presentation/widgets/share_button.dart';
import '../../../support/data/models/support_models.dart';
import '../../../support/presentation/widgets/contact_support_dialog.dart';
import '../../data/models/gallery_photo_model.dart';
import '../../data/models/my_company_model.dart';
import '../../../shell/presentation/providers/shell_nav_provider.dart';
import '../providers/company_dashboard_provider.dart';
import '../widgets/auto_approve_card.dart';
import '../widgets/salon_geocoding_banner.dart';
import 'company_dashboard_screen_mobile.dart';
import '../../../../core/widgets/skeletons/skeleton_widgets.dart';

// ---------------------------------------------------------------------------
// Callback re-imports (same typedefs live in mobile file)
// ---------------------------------------------------------------------------

typedef _OnEditCompany = void Function(MyCompanyModel company);
typedef _OnEditCategory = void Function(MyCategoryModel cat);
typedef _OnDeleteCategory = void Function(MyCategoryModel cat);
typedef _OnAddService = void Function(String categoryId);
typedef _OnEditService = void Function(String categoryId, MyServiceModel svc);
typedef _OnDeleteService = void Function(String categoryId, MyServiceModel svc);
typedef _OnEditEmployee = void Function(
    MyEmployeeModel emp, List<MyServiceModel> allServices);
typedef _OnRemoveEmployee = void Function(MyEmployeeModel emp);
typedef _OnEditHours = void Function(
    MyCompanyModel company, List<String> dayLabels);
typedef _OnPickAndUploadPhoto = Future<void> Function();
typedef _OnDeleteGalleryPhoto = Future<void> Function(GalleryPhotoModel photo);
typedef _OnReorderGalleryPhotos = Future<void> Function(
    List<GalleryPhotoModel> reordered);

// ---------------------------------------------------------------------------
// Desktop presentation (D4)
// ---------------------------------------------------------------------------

/// Full-screen two-column desktop layout.
///
/// Left column (~240 px): dark ink sidebar with brand + nav.
/// Right column: scrollable main content — greeting hero, metric tiles,
/// salon info card, categories/services, team, opening hours.
class CompanyDashboardScreenDesktop extends ConsumerWidget {
  final _OnEditCompany onEditCompany;
  final VoidCallback onAddCategory;
  final _OnEditCategory onEditCategory;
  final _OnDeleteCategory onDeleteCategory;
  final _OnAddService onAddService;
  final _OnEditService onEditService;
  final _OnDeleteService onDeleteService;
  final VoidCallback onInviteEmployee;
  final VoidCallback onCreateEmployee;
  final _OnEditEmployee onEditEmployee;
  final _OnRemoveEmployee onRemoveEmployee;
  final _OnEditHours onEditHours;
  final _OnPickAndUploadPhoto onPickAndUploadPhoto;
  final _OnDeleteGalleryPhoto onDeleteGalleryPhoto;
  final _OnReorderGalleryPhotos onReorderGalleryPhotos;

  const CompanyDashboardScreenDesktop({
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

    // Sidebar is now provided by the shell (MainShell) on desktop; this
    // screen only renders its main content area.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: state.isLoading && state.company == null
          ? const SkeletonDashboard()
          : state.error != null && state.company == null
              ? _DesktopErrorView(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(companyDashboardProvider.notifier).load(),
                )
              : _DesktopMainContent(
                  state: state,
                  onEditCompany: onEditCompany,
                  onAddCategory: onAddCategory,
                  onEditCategory: onEditCategory,
                  onDeleteCategory: onDeleteCategory,
                  onAddService: onAddService,
                  onEditService: onEditService,
                  onDeleteService: onDeleteService,
                  onInviteEmployee: onInviteEmployee,
                  onCreateEmployee: onCreateEmployee,
                  onEditEmployee: onEditEmployee,
                  onRemoveEmployee: onRemoveEmployee,
                  onEditHours: onEditHours,
                  onPickAndUploadPhoto: onPickAndUploadPhoto,
                  onDeleteGalleryPhoto: onDeleteGalleryPhoto,
                  onReorderGalleryPhotos: onReorderGalleryPhotos,
                  onRefresh: () =>
                      ref.read(companyDashboardProvider.notifier).load(),
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main scrollable content
// ---------------------------------------------------------------------------

class _DesktopMainContent extends ConsumerWidget {
  final CompanyDashboardState state;
  final _OnEditCompany onEditCompany;
  final VoidCallback onAddCategory;
  final _OnEditCategory onEditCategory;
  final _OnDeleteCategory onDeleteCategory;
  final _OnAddService onAddService;
  final _OnEditService onEditService;
  final _OnDeleteService onDeleteService;
  final VoidCallback onInviteEmployee;
  final VoidCallback onCreateEmployee;
  final _OnEditEmployee onEditEmployee;
  final _OnRemoveEmployee onRemoveEmployee;
  final _OnEditHours onEditHours;
  final _OnPickAndUploadPhoto onPickAndUploadPhoto;
  final _OnDeleteGalleryPhoto onDeleteGalleryPhoto;
  final _OnReorderGalleryPhotos onReorderGalleryPhotos;
  final VoidCallback onRefresh;

  const _DesktopMainContent({
    required this.state,
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
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final company = state.company;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl + AppSpacing.sm, // 42 px ≈ spec
            AppSpacing.xl + AppSpacing.sm,
            AppSpacing.xl + AppSpacing.sm,
            AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ──────────────────────────────────────────────────
            _DesktopGreeting(company: company),

            const SizedBox(height: AppSpacing.xl),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: AppSpacing.xl),

            // Red warning when the salon lacks geocoding — hidden once
            // address/GPS is set.
            const SalonGeocodingBanner(),

            // ── Metric tiles ──────────────────────────────────────────────
            if (company != null)
              _MetricTilesRow(company: company),

            const SizedBox(height: AppSpacing.xl),

            // ── Two-column: salon info + capacity/hours ───────────────────
            if (company != null) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Salon info (left, 2fr)
                    Expanded(
                      flex: 2,
                      child: _DesktopSalonInfoCard(
                        company: company,
                        onEdit: () => onEditCompany(company),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    // Opening hours (right, 1fr)
                    Expanded(
                      child: _DesktopHoursCard(
                        company: company,
                        onEdit: () => onEditHours(
                          company,
                          _getDayLabels(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Categories & Services ─────────────────────────────────
              _DesktopServicesSection(
                company: company,
                expandedCategories: state.expandedCategories,
                onToggleCategory: (id) {
                  // Needs ref — handled via ConsumerWidget wrapper below.
                },
                onAddCategory: onAddCategory,
                onEditCategory: onEditCategory,
                onDeleteCategory: onDeleteCategory,
                onAddService: onAddService,
                onEditService: onEditService,
                onDeleteService: onDeleteService,
              ),

              // Auto-approve sits right after services so it lands high on
              // the page — the owner sees the validation policy before the
              // scheduling details.
              if (company.bookingMode == 'capacity_based') ...[
                const SizedBox(height: AppSpacing.xl),
                AutoApproveCard(key: ref.watch(autoApproveCardKeyProvider)),
              ],

              const SizedBox(height: AppSpacing.xl),

              // ── Team (employee_based only) ────────────────────────────
              if (company.bookingMode == 'employee_based')
                _DesktopTeamSection(
                  company: company,
                  onInvite: onInviteEmployee,
                  onCreate: onCreateEmployee,
                  onEdit: onEditEmployee,
                  onRemove: onRemoveEmployee,
                ),

              // ── Capacity settings (capacity_based only) ───────────────
              if (company.bookingMode == 'capacity_based')
                _DesktopCapacityCard(),

              // ── Reviews received — owner aperçu ──────────────────────
              // Wrapped in a Consumer so we can collapse the entire block
              // (card + surrounding spacing) when the salon has zero reviews.
              Consumer(
                builder: (ctx, wRef, _) {
                  final st = wRef.watch(myCompanyReviewsProvider);
                  if (!st.isLoading && st.reviews.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: const [
                      SizedBox(height: AppSpacing.xl),
                      _DesktopReviewsCard(),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Gallery ───────────────────────────────────────────────
              _DesktopGallerySection(
                onAddPhoto: onPickAndUploadPhoto,
                onDeletePhoto: onDeleteGalleryPhoto,
                onReorder: onReorderGalleryPhotos,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Support card ──────────────────────────────────────────
              _DesktopSupportCard(company: company),
            ],
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
// Greeting hero
// ---------------------------------------------------------------------------

class _DesktopGreeting extends ConsumerWidget {
  final MyCompanyModel? company;
  const _DesktopGreeting({this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    // Show the connected user's first name — matches pro-app convention
    // (Fresha, Booksy) and avoids redundancy with the "Mon salon" page title.
    final user = ref.watch(authStateProvider.select((s) => s.user));
    final firstName = (user?.firstName.isNotEmpty ?? false)
        ? user!.firstName.titleCase
        : l.mySalon;
    final now = DateTime.now();
    final months = [
      l.monthJan, l.monthFeb, l.monthMar, l.monthApr,
      l.monthMay, l.monthJun, l.monthJul, l.monthAug,
      l.monthSep, l.monthOct, l.monthNov, l.monthDec,
    ];
    final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';

    final initials = [
      user?.firstName.trim() ?? '',
      user?.lastName.trim() ?? '',
    ].where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();
    final avatarUrl = user?.thumbnailUrl ?? user?.profileImageUrl;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar 56×56 desktop
        AvatarDisplay(
          photoUrl: avatarUrl,
          initials: initials,
          size: 56,
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l.greetingHello},',
              style: AppTextStyles.overline.copyWith(
                color: AppColors.textHint,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            RichText(
              text: TextSpan(
                style: GoogleFonts.fraunces(
                  fontSize: 56,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                  height: 0.95,
                  letterSpacing: -1.5,
                ),
                children: [
                  TextSpan(text: firstName),
                  const TextSpan(
                    text: '.',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              dateStr,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
        const Spacer(),
        if (company != null)
          ShareOutlinedButton(
            companyId: company!.id,
            salonName: company!.name,
            bookingMode: company!.bookingMode,
            employeeIds: {for (final e in company!.employees) e.userId},
            showFreshBadge: true,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Metric tiles row (D4 KPI grid)
// ---------------------------------------------------------------------------

class _MetricTilesRow extends StatelessWidget {
  final MyCompanyModel company;
  const _MetricTilesRow({required this.company});

  @override
  Widget build(BuildContext context) {
    final serviceCount =
        company.categories.fold<int>(0, (sum, c) => sum + c.services.length);
    final employeeCount = company.employees.length;
    final categoryCount = company.categories.length;

    final l = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _KpiTile(
            label: l.dashboardKpiServices,
            value: '$serviceCount',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _KpiTile(
            label: l.dashboardKpiCategories,
            value: '$categoryCount',
          ),
        ),
        if (company.bookingMode == 'employee_based') ...[
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _KpiTile(
              label: l.dashboardKpiTeam,
              value: '$employeeCount',
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _KpiTile(
            label: l.dashboardKpiMode,
            value: company.bookingMode == 'capacity_based'
                ? l.capacityMode
                : l.employee,
            isTextValue: true,
            // Capacity-only: a tiny overline ("VALIDATION") above the
            // italic qualifier ("auto" / "manuelle") so the footnote reads
            // unambiguously — the mini-title makes clear what `auto` refers
            // to. Without it, just "auto" felt orphaned.
            sublabelTitle: company.bookingMode == 'capacity_based'
                ? l.autoApprovalBadgeTitle
                : null,
            sublabel: company.bookingMode == 'capacity_based'
                ? (company.capacityAutoApprove
                    ? l.autoApprovalBadgeAuto
                    : l.autoApprovalBadgeManual)
                : null,
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isTextValue;
  /// Optional micro-title for the footnote, rendered as an overline above
  /// [sublabel] (e.g. "VALIDATION" before "auto"). Gives the qualifier a
  /// clear subject so it can be read in isolation.
  final String? sublabelTitle;
  /// Optional footnote under the value (e.g. "auto" / "manuelle" for the
  /// capacity mode tile). Rendered with a short gold rule and an italic
  /// serif line so it reads as a quiet editorial note, not a second KPI.
  final String? sublabel;

  const _KpiTile({
    required this.label,
    required this.value,
    this.isTextValue = false,
    this.sublabelTitle,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg - 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.overline.copyWith(
              color: AppColors.textHint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          isTextValue
              ? Text(
                  value,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                )
              : Text(
                  value,
                  style: GoogleFonts.fraunces(
                    fontSize: 38,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.8,
                    height: 1.0,
                  ),
                ),
          if (sublabel != null) ...[
            const SizedBox(height: 10),
            Container(
              width: 22,
              height: 1,
              color: AppColors.secondary.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 6),
            if (sublabelTitle != null)
              Text(
                sublabelTitle!.toUpperCase(),
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.textHint,
                  letterSpacing: 1.4,
                  fontSize: 10,
                ),
              ),
            Text(
              sublabel!,
              style: GoogleFonts.instrumentSerif(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: AppColors.primary,
                letterSpacing: 0.1,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Salon info card
// ---------------------------------------------------------------------------

class _DesktopSalonInfoCard extends ConsumerWidget {
  final MyCompanyModel company;
  final VoidCallback onEdit;

  const _DesktopSalonInfoCard({
    required this.company,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstGalleryPhoto = ref.watch(
      companyDashboardProvider.select(
        (s) => s.galleryPhotos.isNotEmpty ? s.galleryPhotos.first : null,
      ),
    );
    final thumbUrl = firstGalleryPhoto?.displayUrl;

    return _DesktopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.companyInfo,
                style: AppTextStyles.h3,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.primary),
                label: Text(
                  context.l10n.editProfile,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo thumbnail — tooltip on hover, snackbar on click.
              Tooltip(
                message: context.l10n.salonCoverPhotoHint,
                waitDuration: const Duration(milliseconds: 300),
                preferBelow: false,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                textStyle: AppTextStyles.caption.copyWith(color: Colors.white),
                child: MouseRegion(
                  cursor: SystemMouseCursors.help,
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
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                            color:
                                AppColors.primary.withValues(alpha: 0.20)),
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
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name.titleCase,
                      style: AppTextStyles.h3,
                    ),
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
        ],
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
// Opening hours card (desktop)
// ---------------------------------------------------------------------------

class _DesktopHoursCard extends StatelessWidget {
  final MyCompanyModel company;
  final VoidCallback onEdit;

  const _DesktopHoursCard({required this.company, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final dayLabels = _getDayLabels(context);

    return _DesktopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.openingHours,
                style: AppTextStyles.h3,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.primary),
                onPressed: onEdit,
                tooltip: context.l10n.editHoursTooltip,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.sm),
          DashboardOpeningHoursDisplay(
            company: company,
            dayLabels: dayLabels,
          ),
        ],
      ),
    );
  }

  static List<String> _getDayLabels(BuildContext context) {
    final l = context.l10n;
    return [
      l.monday, l.tuesday, l.wednesday, l.thursday,
      l.friday, l.saturday, l.sunday,
    ];
  }
}

// ---------------------------------------------------------------------------
// Services section — wraps a ConsumerWidget to get toggleCategory ref call
// ---------------------------------------------------------------------------

class _DesktopServicesSection extends ConsumerWidget {
  final MyCompanyModel company;
  final Set<String> expandedCategories;
  final void Function(String id) onToggleCategory;
  final VoidCallback onAddCategory;
  final _OnEditCategory onEditCategory;
  final _OnDeleteCategory onDeleteCategory;
  final _OnAddService onAddService;
  final _OnEditService onEditService;
  final _OnDeleteService onDeleteService;

  const _DesktopServicesSection({
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
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(
      companyDashboardProvider.select((s) => s.expandedCategories),
    );

    return _DesktopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.servicesAndCategories,
                style: AppTextStyles.h3,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddCategory,
                icon: const Icon(Icons.add_rounded,
                    size: 16, color: AppColors.primary),
                label: Text(
                  context.l10n.addCategory,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.divider, height: 1),
          company.categories.isEmpty
              ? DashboardEmptySection(
                  message: context.l10n.addCategory,
                  icon: Icons.category_outlined,
                )
              : Column(
                  children: company.categories
                      .map(
                        (cat) => DashboardCategoryTile(
                          category: cat,
                          isExpanded: expanded.contains(cat.id),
                          onToggle: () => ref
                              .read(companyDashboardProvider.notifier)
                              .toggleCategory(cat.id),
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
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Team section
// ---------------------------------------------------------------------------

class _DesktopTeamSection extends StatelessWidget {
  final MyCompanyModel company;
  final VoidCallback onInvite;
  final VoidCallback onCreate;
  final _OnEditEmployee onEdit;
  final _OnRemoveEmployee onRemove;

  const _DesktopTeamSection({
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

    return _DesktopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.team, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.sm),

          if (company.employees.isEmpty)
            DashboardEmptySection(
              message: context.l10n.inviteEmployee,
              icon: Icons.person_add_outlined,
            )
          else
            // 2 tiles per row — Wrap so each tile has intrinsic height,
            // otherwise tiles with many service chips overflow the fixed
            // mainAxisExtent of a GridView by up to 30+ px and push the
            // "Inviter / Créer" buttons on top of the cards.
            LayoutBuilder(
              builder: (context, constraints) {
                // Two columns above 680 px, one column below.
                final twoCols = constraints.maxWidth >= 680;
                final tileWidth = twoCols
                    ? (constraints.maxWidth - AppSpacing.sm) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: company.employees.map((emp) {
                    return SizedBox(
                      width: tileWidth,
                      child: DashboardEmployeeTile(
                        employee: emp,
                        allServices: allServices,
                        companyHoursLabel: companyHoursLabel,
                        onEdit: () => onEdit(emp, allServices),
                        onRemove: () => onRemove(emp),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
                onPressed: onInvite,
                icon: const Icon(Icons.mail_outline_rounded, size: 16),
                label: Text(context.l10n.inviteEmployee,
                    style: AppTextStyles.buttonSmall),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
                onPressed: onCreate,
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: Text(context.l10n.createEmployee,
                    style: AppTextStyles.buttonSmall),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Capacity settings shortcut card
// ---------------------------------------------------------------------------

class _DesktopCapacityCard extends StatelessWidget {
  const _DesktopCapacityCard();

  @override
  Widget build(BuildContext context) {
    return _DesktopCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(Icons.tune_rounded,
                size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.capacitySettingsTitle,
                    style: AppTextStyles.subtitle
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(
                  context.l10n.capacitySettingsDescription,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.pushNamed(RouteNames.capacitySettings),
            child: Text(
              context.l10n.configureAction,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gallery section (desktop)
// ---------------------------------------------------------------------------

class _DesktopGallerySection extends ConsumerWidget {
  final _OnPickAndUploadPhoto onAddPhoto;
  final _OnDeleteGalleryPhoto onDeletePhoto;
  final _OnReorderGalleryPhotos onReorder;

  const _DesktopGallerySection({
    required this.onAddPhoto,
    required this.onDeletePhoto,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploading = ref.watch(
      companyDashboardProvider.select((s) => s.galleryUploading),
    );

    return _DesktopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(context.l10n.gallery, style: AppTextStyles.h3),
              const Spacer(),
              if (uploading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                TextButton.icon(
                  onPressed: onAddPhoto,
                  icon: const Icon(Icons.add_photo_alternate_outlined,
                      size: 16, color: AppColors.primary),
                  label: Text(
                    context.l10n.galleryAddPhoto,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.sm),
          DashboardGalleryCard(
            onAddPhoto: onAddPhoto,
            onDeletePhoto: onDeletePhoto,
            onReorder: onReorder,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reviews received card — owner dashboard aperçu
// ---------------------------------------------------------------------------

class _DesktopReviewsCard extends ConsumerWidget {
  const _DesktopReviewsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myCompanyReviewsProvider);

    return _DesktopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                context.l10n.reviewsReceivedCardTitle,
                style: AppTextStyles.h3,
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    context.pushNamed(RouteNames.myCompanyReviews),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  context.l10n.seeAllReviews,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.md),

          // ── Body ─────────────────────────────────────────────────────────
          if (state.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: CircularProgressIndicator(color: AppColors.secondary),
              ),
            )
          else if (state.reviews.isEmpty)
            _ReviewsEmptyState()
          else if (state.reviews
              .every((r) => (r.comment?.trim().isEmpty ?? true)))
            // Stars-only situation — one concise note, still shows the
            // average via _RatingSummary for completeness.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _RatingSummary(reviews: state.reviews),
                  const SizedBox(width: AppSpacing.xl),
                  Container(width: 1, color: AppColors.divider),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 18, color: AppColors.secondaryDark),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            context.l10n.reviewsOnlyRatings,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.secondaryDark,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left — big average rating
                  _RatingSummary(reviews: state.reviews),
                  const SizedBox(width: AppSpacing.xl),
                  // Vertical divider
                  Container(
                    width: 1,
                    color: AppColors.divider,
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  // Right — last 3 reviews
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: state.reviews
                          .take(3)
                          .map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md),
                              child: _CompactReviewRow(review: r),
                            ),
                          )
                          .toList(),
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

class _RatingSummary extends StatelessWidget {
  final List<ReviewModel> reviews;

  const _RatingSummary({required this.reviews});

  @override
  Widget build(BuildContext context) {
    final avg = reviews.isEmpty
        ? 0.0
        : reviews.fold<double>(0, (s, r) => s + r.rating) / reviews.length;

    return SizedBox(
      width: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            avg.toStringAsFixed(1),
            style: GoogleFonts.fraunces(
              fontSize: 56,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              letterSpacing: -2.0,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.averageRatingOutOf,
            style: AppTextStyles.overline.copyWith(
              color: AppColors.textHint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          // Star row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return Icon(
                i < avg.round()
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 14,
                color: i < avg.round()
                    ? AppColors.secondary
                    : AppColors.divider,
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            '${reviews.length} avis',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactReviewRow extends StatelessWidget {
  final ReviewModel review;

  const _CompactReviewRow({required this.review});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: review.authorProfileImageUrl != null
              ? NetworkImage(review.authorProfileImageUrl!)
              : null,
          child: review.authorProfileImageUrl == null
              ? Text(
                  review.authorFirstName.isNotEmpty
                      ? review.authorFirstName[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author + stars
              Row(
                children: [
                  Expanded(
                    child: Text(
                      review.authorDisplay,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < review.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 11,
                        color: i < review.rating
                            ? AppColors.secondary
                            : AppColors.divider,
                      );
                    }),
                  ),
                ],
              ),
              // Comment (2 lines truncate)
              if (review.comment != null && review.comment!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  review.comment!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewsEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        children: [
          Icon(
            Icons.star_outline_rounded,
            size: 28,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            context.l10n.noReviewsYetOwner,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generic desktop cream card wrapper
// ---------------------------------------------------------------------------

class _DesktopCard extends StatelessWidget {
  final Widget child;

  const _DesktopCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg + 4), // 28 px ≈ spec
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl - 4), // 20 px
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF171311).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Error view
// ---------------------------------------------------------------------------

class _DesktopErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DesktopErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}

// ---------------------------------------------------------------------------
// Support card — desktop
// ---------------------------------------------------------------------------

class _DesktopSupportCard extends ConsumerWidget {
  final MyCompanyModel company;
  const _DesktopSupportCard({required this.company});

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
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(Icons.headset_mic_rounded,
                    size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.contactSupport,
                      style: AppTextStyles.h3
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.supportSubtitle,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => showContactSupportDialog(
                  context,
                  ref: ref,
                  sourcePage: SupportSourcePage.myCompany,
                  sourceContext: {'companyId': company.id},
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 4),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: Text(l.contactSupport),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

