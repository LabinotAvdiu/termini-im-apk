import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/my_company_model.dart';
import '../providers/company_dashboard_provider.dart';

// ---------------------------------------------------------------------------
// Root screen
// ---------------------------------------------------------------------------

class CompanyDashboardScreen extends ConsumerStatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  ConsumerState<CompanyDashboardScreen> createState() =>
      _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState
    extends ConsumerState<CompanyDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data on first mount; use addPostFrameCallback to avoid
    // calling notifier during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(companyDashboardProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: state.isLoading && state.company == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : state.error != null && state.company == null
              ? _ErrorView(
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
                      _DashboardAppBar(company: state.company),
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
                              _CompanyInfoCard(company: state.company!),
                              const SizedBox(height: AppSpacing.md),
                              _ServicesCard(company: state.company!),
                              const SizedBox(height: AppSpacing.md),
                              if (state.company!.bookingMode == 'capacity_based') ...[
                                _CapacitySectionCard(company: state.company!),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              if (state.company!.bookingMode == 'employee_based') ...[
                                _TeamCard(company: state.company!),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              _OpeningHoursCard(company: state.company!),
                            ],
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// SliverAppBar
// ---------------------------------------------------------------------------

class _DashboardAppBar extends StatelessWidget {
  final MyCompanyModel? company;

  const _DashboardAppBar({this.company});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.cardShadow,
      title: Text(
        context.l10n.mySalon,
        style: AppTextStyles.h3,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppColors.divider),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section card wrapper
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
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
    return Container(
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
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(title,
                      style: AppTextStyles.subtitle
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                ?trailing,
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: AppColors.divider),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 1 — Company info card
// ---------------------------------------------------------------------------

class _CompanyInfoCard extends ConsumerWidget {
  final MyCompanyModel company;

  const _CompanyInfoCard({required this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionCard(
      title: context.l10n.companyInfo,
      icon: Icons.storefront_rounded,
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined,
            size: 20, color: AppColors.primary),
        tooltip: context.l10n.editProfile,
        onPressed: () => _showEditDialog(context, ref),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo placeholder
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.20)),
              ),
              child: company.profileImageUrl != null &&
                      company.profileImageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      child: Image.network(
                        company.profileImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            _photoPlaceholderIcon(),
                      ),
                    )
                  : _photoPlaceholderIcon(),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company.name, style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.xs),
                  _InfoRow(
                      icon: Icons.location_on_outlined,
                      text: '${company.address}, ${company.city}'),
                  _InfoRow(
                      icon: Icons.phone_outlined, text: company.phone),
                  _InfoRow(
                      icon: Icons.email_outlined, text: company.email),
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

  Widget _photoPlaceholderIcon() => const Icon(
        Icons.storefront_rounded,
        size: 32,
        color: AppColors.primary,
      );

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: company.name);
    final addressCtrl = TextEditingController(text: company.address);
    final cityCtrl = TextEditingController(text: company.city);
    final phoneCtrl = TextEditingController(text: company.phone);
    final phoneSecondaryCtrl =
        TextEditingController(text: company.phoneSecondary ?? '');
    final descCtrl = TextEditingController(text: company.description ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => _CompanyEditDialog(
        nameCtrl: nameCtrl,
        addressCtrl: addressCtrl,
        cityCtrl: cityCtrl,
        phoneCtrl: phoneCtrl,
        phoneSecondaryCtrl: phoneSecondaryCtrl,
        descCtrl: descCtrl,
        onSave: () async {
          final secondaryRaw = phoneSecondaryCtrl.text.trim();
          final ok = await ref
              .read(companyDashboardProvider.notifier)
              .updateCompanyInfo({
            'name': nameCtrl.text.trim(),
            'address': addressCtrl.text.trim(),
            'city': cityCtrl.text.trim(),
            'phone': phoneCtrl.text.trim(),
            'phone_secondary': secondaryRaw.isEmpty ? null : secondaryRaw,
            'description': descCtrl.text.trim(),
          });
          if (ctx.mounted) Navigator.of(ctx).pop();
          if (ok && context.mounted) {
            context.showSnackBar(context.l10n.changesSaved);
          }
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

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
// Company edit dialog
// ---------------------------------------------------------------------------

class _CompanyEditDialog extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController phoneSecondaryCtrl;
  final TextEditingController descCtrl;
  final VoidCallback onSave;

  const _CompanyEditDialog({
    required this.nameCtrl,
    required this.addressCtrl,
    required this.cityCtrl,
    required this.phoneCtrl,
    required this.phoneSecondaryCtrl,
    required this.descCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.companyInfo, style: AppTextStyles.h3),
      contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppTextField(
                controller: nameCtrl,
                label: context.l10n.companyName,
                prefixIcon: Icons.storefront_outlined,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppTextField(
                controller: addressCtrl,
                label: context.l10n.address,
                prefixIcon: Icons.location_on_outlined,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppTextField(
                controller: cityCtrl,
                label: context.l10n.city,
                prefixIcon: Icons.location_city_outlined,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppTextField(
                controller: phoneCtrl,
                label: context.l10n.phone,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                hint: '044 123 456',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppTextField(
                controller: phoneSecondaryCtrl,
                label: context.l10n.phoneSecondary,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                hint: '044 123 456',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppTextField(
                controller: descCtrl,
                label: context.l10n.descriptionLabel,
                prefixIcon: Icons.notes_outlined,
                maxLines: 3,
              ),
            ),
          ],
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
          onPressed: onSave,
          child: Text(context.l10n.saveChanges),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section 2 — Services & Categories
// ---------------------------------------------------------------------------

class _ServicesCard extends ConsumerWidget {
  final MyCompanyModel company;

  const _ServicesCard({required this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded =
        ref.watch(companyDashboardProvider).expandedCategories;

    return _SectionCard(
      title: context.l10n.servicesAndCategories,
      icon: Icons.content_cut_rounded,
      trailing: IconButton(
        icon: const Icon(Icons.add_rounded, size: 22, color: AppColors.primary),
        tooltip: context.l10n.addCategory,
        onPressed: () => _showAddCategoryDialog(context, ref),
      ),
      child: company.categories.isEmpty
          ? _EmptySection(
              message: context.l10n.addCategory,
              icon: Icons.category_outlined,
            )
          : Column(
              children: company.categories
                  .map((cat) => _CategoryTile(
                        category: cat,
                        isExpanded: expanded.contains(cat.id),
                        onToggle: () => ref
                            .read(companyDashboardProvider.notifier)
                            .toggleCategory(cat.id),
                        onEditCategory: () =>
                            _showEditCategoryDialog(context, ref, cat),
                        onDeleteCategory: () =>
                            _confirmDeleteCategory(context, ref, cat),
                        onAddService: () =>
                            _showAddServiceDialog(context, ref, cat.id),
                        onEditService: (svc) => _showEditServiceDialog(
                            context, ref, cat.id, svc),
                        onDeleteService: (svc) =>
                            _confirmDeleteService(context, ref, cat.id, svc),
                      ))
                  .toList(),
            ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    _showNameDialog(
      context: context,
      title: context.l10n.addCategory,
      label: context.l10n.categoryName,
      controller: ctrl,
      onSave: () async {
        if (ctrl.text.trim().isEmpty) return;
        final ok = await ref
            .read(companyDashboardProvider.notifier)
            .addCategory(ctrl.text.trim());
        if (context.mounted) Navigator.of(context).pop();
        if (ok && context.mounted) {
          context.showSnackBar(context.l10n.changesSaved);
        }
      },
    );
  }

  void _showEditCategoryDialog(
      BuildContext context, WidgetRef ref, MyCategoryModel cat) {
    final ctrl = TextEditingController(text: cat.name);
    _showNameDialog(
      context: context,
      title: context.l10n.addCategory,
      label: context.l10n.categoryName,
      controller: ctrl,
      onSave: () async {
        if (ctrl.text.trim().isEmpty) return;
        final ok = await ref
            .read(companyDashboardProvider.notifier)
            .editCategory(cat.id, ctrl.text.trim());
        if (context.mounted) Navigator.of(context).pop();
        if (ok && context.mounted) {
          context.showSnackBar(context.l10n.changesSaved);
        }
      },
    );
  }

  void _confirmDeleteCategory(
      BuildContext context, WidgetRef ref, MyCategoryModel cat) {
    _showConfirmDialog(
      context: context,
      title: cat.name,
      onConfirm: () async {
        final ok = await ref
            .read(companyDashboardProvider.notifier)
            .removeCategory(cat.id);
        if (context.mounted) Navigator.of(context).pop();
        if (ok && context.mounted) {
          context.showSnackBar(context.l10n.changesSaved);
        }
      },
    );
  }

  void _showAddServiceDialog(
      BuildContext context, WidgetRef ref, String categoryId) {
    _showServiceDialog(
      context: context,
      categoryId: categoryId,
      ref: ref,
    );
  }

  void _showEditServiceDialog(BuildContext context, WidgetRef ref,
      String categoryId, MyServiceModel svc) {
    _showServiceDialog(
      context: context,
      categoryId: categoryId,
      service: svc,
      ref: ref,
    );
  }

  void _confirmDeleteService(BuildContext context, WidgetRef ref,
      String categoryId, MyServiceModel svc) {
    _showConfirmDialog(
      context: context,
      title: svc.name,
      onConfirm: () async {
        final ok = await ref
            .read(companyDashboardProvider.notifier)
            .removeService(serviceId: svc.id, categoryId: categoryId);
        if (context.mounted) Navigator.of(context).pop();
        if (ok && context.mounted) {
          context.showSnackBar(context.l10n.changesSaved);
        }
      },
    );
  }

  void _showServiceDialog({
    required BuildContext context,
    required String categoryId,
    required WidgetRef ref,
    MyServiceModel? service,
  }) {
    final nameCtrl = TextEditingController(text: service?.name ?? '');
    final durationCtrl = TextEditingController(
        text: service != null ? service.durationMinutes.toString() : '');
    final priceCtrl = TextEditingController(
        text: service != null ? service.price.toStringAsFixed(2) : '');
    final maxCtrl = TextEditingController(
        text: service?.maxConcurrent?.toString() ?? '');
    final isCapacity =
        ref.read(companyDashboardProvider).company?.bookingMode ==
            'capacity_based';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          service == null ? context.l10n.addService : context.l10n.services,
          style: AppTextStyles.h3,
        ),
        contentPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppTextField(
                  controller: nameCtrl,
                  label: context.l10n.services,
                  prefixIcon: Icons.content_cut_rounded,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppTextField(
                  controller: durationCtrl,
                  label: context.l10n.serviceDuration,
                  prefixIcon: Icons.timer_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppTextField(
                  controller: priceCtrl,
                  label: context.l10n.servicePrice,
                  prefixIcon: Icons.euro_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              if (isCapacity)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppTextField(
                    controller: maxCtrl,
                    label: context.l10n.maxConcurrent,
                    prefixIcon: Icons.people_outline_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final duration = int.tryParse(durationCtrl.text.trim()) ?? 0;
              final price =
                  double.tryParse(priceCtrl.text.trim().replaceAll(',', '.')) ??
                      0.0;
              final maxConcurrent = isCapacity
                  ? int.tryParse(maxCtrl.text.trim())
                  : null;
              if (name.isEmpty || duration <= 0) return;

              bool ok;
              if (service == null) {
                ok = await ref
                    .read(companyDashboardProvider.notifier)
                    .addService(
                      categoryId: categoryId,
                      name: name,
                      durationMinutes: duration,
                      price: price,
                      maxConcurrent: maxConcurrent,
                    );
              } else {
                ok = await ref
                    .read(companyDashboardProvider.notifier)
                    .editService(
                      serviceId: service.id,
                      categoryId: categoryId,
                      name: name,
                      durationMinutes: duration,
                      price: price,
                      maxConcurrent: maxConcurrent,
                    );
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (ok && context.mounted) {
                context.showSnackBar(context.l10n.changesSaved);
              }
            },
            child: Text(context.l10n.saveChanges),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Capacity section card (capacity_based mode only)
// ---------------------------------------------------------------------------

class _CapacitySectionCard extends StatelessWidget {
  final MyCompanyModel company;

  const _CapacitySectionCard({required this.company});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
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
            title: Text(
              context.l10n.capacitySettingsTitle,
              style: AppTextStyles.body,
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textHint),
            onTap: () => context.goNamed(RouteNames.capacitySettings),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final MyCategoryModel category;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onEditCategory;
  final VoidCallback onDeleteCategory;
  final VoidCallback onAddService;
  final void Function(MyServiceModel) onEditService;
  final void Function(MyServiceModel) onDeleteService;

  const _CategoryTile({
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
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${category.services.length}',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppSpacing.sm),
                _ItemActions(
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
                (svc) => _ServiceRow(
                  service: svc,
                  onEdit: () => onEditService(svc),
                  onDelete: () => onDeleteService(svc),
                ),
              ),
              // Add service button
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
            height: 1, thickness: 0.5, color: AppColors.divider,
            indent: AppSpacing.md),
      ],
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final MyServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceRow({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl + AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(service.name, style: AppTextStyles.body),
          ),
          Text(
            '${service.durationMinutes} min',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${service.price.toStringAsFixed(service.price.truncateToDouble() == service.price ? 0 : 2)} €',
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: AppSpacing.xs),
          _ItemActions(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 3 — Team
// ---------------------------------------------------------------------------

class _TeamCard extends ConsumerWidget {
  final MyCompanyModel company;

  const _TeamCard({required this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Flatten all services from all categories once for reuse in tiles/dialogs.
    final allServices = company.categories
        .expand((cat) => cat.services)
        .toList();

    // Build a representative working hours string from the first non-closed day.
    // Employees follow company hours until per-employee schedules are introduced.
    final firstOpenHour = company.openingHours
        .where((h) => !h.isClosed && h.openTime != null && h.closeTime != null)
        .firstOrNull;
    final companyHoursLabel = firstOpenHour != null
        ? '${firstOpenHour.openTime} - ${firstOpenHour.closeTime}'
        : null;

    return _SectionCard(
      title: context.l10n.team,
      icon: Icons.people_alt_outlined,
      child: Column(
        children: [
          if (company.employees.isEmpty)
            _EmptySection(
              message: context.l10n.inviteEmployee,
              icon: Icons.person_add_outlined,
            )
          else
            ...company.employees.map(
              (emp) => _EmployeeTile(
                employee: emp,
                allServices: allServices,
                companyHoursLabel: companyHoursLabel,
                onEdit: () =>
                    _showEditEmployeeDialog(context, ref, emp, allServices),
                onRemove: () => _confirmRemoveEmployee(context, ref, emp),
              ),
            ),
          // Action buttons
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
                    onPressed: () =>
                        _showInviteEmployeeDialog(context, ref),
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
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                    ),
                    onPressed: () =>
                        _showCreateEmployeeDialog(context, ref),
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

  void _showInviteEmployeeDialog(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.inviteEmployee, style: AppTextStyles.h3),
        contentPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppTextField(
                controller: emailCtrl,
                label: context.l10n.employeeEmail,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              final ok = await ref
                  .read(companyDashboardProvider.notifier)
                  .inviteEmployee(email: email, specialties: const []);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (ok && context.mounted) {
                context.showSnackBar(context.l10n.changesSaved);
              }
            },
            child: Text(context.l10n.saveChanges),
          ),
        ],
      ),
    );
  }

  void _showCreateEmployeeDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.createEmployee, style: AppTextStyles.h3),
        contentPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppTextField(
                controller: nameCtrl,
                label: context.l10n.firstName,
                prefixIcon: Icons.person_outline_rounded,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppTextField(
                controller: emailCtrl,
                label: context.l10n.employeeEmail,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final email = emailCtrl.text.trim();
              if (name.isEmpty || email.isEmpty) return;
              final ok = await ref
                  .read(companyDashboardProvider.notifier)
                  .createEmployee({
                'name': name,
                'email': email,
                'specialties': <String>[],
              });
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (ok && context.mounted) {
                context.showSnackBar(context.l10n.changesSaved);
              }
            },
            child: Text(context.l10n.saveChanges),
          ),
        ],
      ),
    );
  }

  void _showEditEmployeeDialog(
    BuildContext context,
    WidgetRef ref,
    MyEmployeeModel emp,
    List<MyServiceModel> allServices,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _EditEmployeeDialog(
        employee: emp,
        allServices: allServices,
        onSave: (serviceIds) async {
          final ok = await ref
              .read(companyDashboardProvider.notifier)
              .editEmployee(emp.id, {
            'service_ids': serviceIds,
          });
          if (ctx.mounted) Navigator.of(ctx).pop();
          if (ok && context.mounted) {
            context.showSnackBar(context.l10n.changesSaved);
          }
        },
      ),
    );
  }

  void _confirmRemoveEmployee(
      BuildContext context, WidgetRef ref, MyEmployeeModel emp) {
    _showConfirmDialog(
      context: context,
      title: emp.fullName,
      onConfirm: () async {
        final ok = await ref
            .read(companyDashboardProvider.notifier)
            .removeEmployee(emp.id);
        if (context.mounted) Navigator.of(context).pop();
        if (ok && context.mounted) {
          context.showSnackBar(context.l10n.changesSaved);
        }
      },
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  final MyEmployeeModel employee;
  final List<MyServiceModel> allServices;
  /// Formatted company hours string, e.g. "09:00 - 19:00".
  /// Null when company has no open hours configured yet.
  final String? companyHoursLabel;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _EmployeeTile({
    required this.employee,
    required this.allServices,
    required this.onEdit,
    required this.onRemove,
    this.companyHoursLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve the names of the assigned services for display.
    final assignedServices = allServices
        .where((s) => employee.serviceIds.contains(s.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundImage: employee.photoUrl != null
                  ? NetworkImage(employee.photoUrl!)
                  : null,
              child: employee.photoUrl == null
                  ? Text(
                      employee.fullName.isNotEmpty
                          ? employee.fullName[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.subtitle
                          .copyWith(color: AppColors.primary),
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
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm),
                              border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.30),
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
                if (companyHoursLabel != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_outlined,
                        size: 12,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        context.l10n.employeeScheduleHint(companyHoursLabel!),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textHint),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Active badge + actions — aligned to top
          _StatusBadge(isActive: employee.isActive),
          const SizedBox(width: AppSpacing.xs),
          _ItemActions(onEdit: onEdit, onDelete: onRemove),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit employee dialog — stateful so FilterChip toggles update reactively
// ---------------------------------------------------------------------------

class _EditEmployeeDialog extends StatefulWidget {
  final MyEmployeeModel employee;
  final List<MyServiceModel> allServices;
  final Future<void> Function(List<String> serviceIds) onSave;

  const _EditEmployeeDialog({
    required this.employee,
    required this.allServices,
    required this.onSave,
  });

  @override
  State<_EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<_EditEmployeeDialog> {
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
      contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      content: SizedBox(
        // Constrain width so the dialog doesn't exceed the screen on tablets.
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Email (read-only) -----------------------------------------
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppTextField(
                  controller: TextEditingController(
                      text: widget.employee.email),
                  label: context.l10n.employeeEmail,
                  prefixIcon: Icons.email_outlined,
                  enabled: false,
                ),
              ),

              // --- Service assignment section ---------------------------------
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
                        color: selected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                      labelStyle: AppTextStyles.caption.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      backgroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 0),
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

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.textHint;
    final label =
        isActive ? context.l10n.active : context.l10n.inactive;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style:
            AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 4 — Opening hours
// ---------------------------------------------------------------------------

class _OpeningHoursCard extends ConsumerWidget {
  final MyCompanyModel company;

  const _OpeningHoursCard({required this.company});

  static List<String> _getDayLabels(BuildContext context) {
    final l = context.l10n;
    return [l.monday, l.tuesday, l.wednesday, l.thursday, l.friday, l.saturday, l.sunday];
  }

  /// Trim "09:00:00" → "09:00"
  static String _trimTime(String? time) {
    if (time == null) return '--:--';
    return time.length > 5 ? time.substring(0, 5) : time;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Build a map keyed by dayOfWeek so we can display all 7 days.
    final hoursMap = {
      for (final h in company.openingHours) h.dayOfWeek: h,
    };

    return _SectionCard(
      title: context.l10n.openingHours,
      icon: Icons.access_time_rounded,
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined,
            size: 20, color: AppColors.primary),
        tooltip: context.l10n.editProfile,
        onPressed: () => _showEditHoursDialog(context, ref),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        child: Column(
          children: List.generate(7, (i) {
            final dayIndex = i; // 0=Mon … 6=Sun
            final hour = hoursMap[dayIndex];
            final isClosed = hour == null || hour.isClosed;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      _getDayLabels(context)[i],
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
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
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
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

  void _showEditHoursDialog(BuildContext context, WidgetRef ref) {
    // Build an editable copy of the 7-day hours list
    final hoursMap = {
      for (final h in company.openingHours) h.dayOfWeek: h,
    };
    final editableHours = List.generate(
      7,
      (i) =>
          hoursMap[i] ??
          OpeningHourModel(dayOfWeek: i, isClosed: true),
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => _HoursEditDialog(
        hours: editableHours,
        dayLabels: _getDayLabels(context),
        onSave: (updated) async {
          final ok = await ref
              .read(companyDashboardProvider.notifier)
              .saveHours(updated);
          if (ctx.mounted) Navigator.of(ctx).pop();
          if (ok && context.mounted) {
            context.showSnackBar(context.l10n.changesSaved);
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hours edit dialog — stateful so toggles & time pickers work
// ---------------------------------------------------------------------------

class _HoursEditDialog extends StatefulWidget {
  final List<OpeningHourModel> hours;
  final List<String> dayLabels;
  final void Function(List<OpeningHourModel>) onSave;

  const _HoursEditDialog({
    required this.hours,
    required this.dayLabels,
    required this.onSave,
  });

  @override
  State<_HoursEditDialog> createState() => _HoursEditDialogState();
}

class _HoursEditDialogState extends State<_HoursEditDialog> {
  late List<OpeningHourModel> _hours;

  @override
  void initState() {
    super.initState();
    // Deep copy so the dialog edits do not mutate the provider state directly.
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
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.openingHours, style: AppTextStyles.h3),
      contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(7, (i) {
              final hour = _hours[i];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
                      activeTrackColor:
                          AppColors.primary.withValues(alpha: 0.40),
                      onChanged: (val) => setState(() {
                        if (val) {
                          // Switching to open — set default hours if null
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
                        child: Text('–',
                            style: TextStyle(color: AppColors.textSecondary)),
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 4),
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
// Shared helpers
// ---------------------------------------------------------------------------

class _ItemActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemActions({required this.onEdit, required this.onDelete});

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

class _EmptySection extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptySection({required this.message, required this.icon});

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

void _showNameDialog({
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
      contentPadding:
          const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      content: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: AppTextField(controller: controller, label: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            ctx.l10n.cancel,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
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

void _showConfirmDialog({
  required BuildContext context,
  required String title,
  required VoidCallback onConfirm,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: AppTextStyles.h3),
      content: Text(
        context.l10n.deleteAccountWarning,
        style: AppTextStyles.body,
      ),
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
// Error view
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

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
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
