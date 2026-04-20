import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/salon_location_fields.dart';
import '../../data/models/gallery_photo_model.dart';
import '../../data/models/my_company_model.dart';
import '../providers/company_dashboard_provider.dart';
import 'company_dashboard_screen_desktop.dart';
import 'company_dashboard_screen_mobile.dart';

export 'company_dashboard_screen_mobile.dart'
    show
        DashboardSectionCard,
        DashboardInfoRow,
        DashboardItemActions,
        DashboardEmptySection,
        DashboardCategoryTile,
        DashboardServiceRow,
        DashboardStatusBadge,
        DashboardEmployeeTile,
        DashboardEditEmployeeDialog,
        DashboardOpeningHoursDisplay,
        DashboardGalleryCard,
        dashboardShowNameDialog,
        dashboardShowConfirmDialog;

// ---------------------------------------------------------------------------
// Wrapper — owns all business logic, dialog launchers, initState
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(companyDashboardProvider.notifier).load();
    });
  }

  // ── Company info ─────────────────────────────────────────────────────────

  void showEditCompanyDialog(BuildContext context, MyCompanyModel company) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _CompanyEditDialog(
        company: company,
        onSave: (payload) async {
          final ok = await ref
              .read(companyDashboardProvider.notifier)
              .updateCompanyInfo(payload);
          if (ctx.mounted) Navigator.of(ctx).pop();
          if (ok && context.mounted) {
            _showSnack(context, context.l10n.saveSuccess);
          }
        },
      ),
    );
  }

  // ── Categories ────────────────────────────────────────────────────────────

  void showAddCategoryDialog(BuildContext context) {
    final ctrl = TextEditingController();
    dashboardShowNameDialog(
      context: context,
      title: context.l10n.addCategory,
      label: context.l10n.categoryName,
      controller: ctrl,
      onSave: () async {
        if (ctrl.text.trim().isEmpty) return;
        final ok = await ref
            .read(companyDashboardProvider.notifier)
            .addCategory(ctrl.text.trim().capitalize);
        if (context.mounted) Navigator.of(context).pop();
        if (ok && context.mounted) _showSnack(context, context.l10n.saveSuccess);
      },
    );
  }

  void showEditCategoryDialog(BuildContext context, MyCategoryModel cat) {
    final ctrl = TextEditingController(text: cat.name);
    dashboardShowNameDialog(
      context: context,
      title: context.l10n.editCategoryTitle,
      label: context.l10n.categoryName,
      controller: ctrl,
      onSave: () async {
        if (ctrl.text.trim().isEmpty) return;
        final ok = await ref
            .read(companyDashboardProvider.notifier)
            .editCategory(cat.id, ctrl.text.trim().capitalize);
        if (context.mounted) Navigator.of(context).pop();
        if (ok && context.mounted) _showSnack(context, context.l10n.saveSuccess);
      },
    );
  }

  void confirmDeleteCategory(BuildContext context, MyCategoryModel cat) {
    dashboardShowConfirmDialog(
      context: context,
      title: cat.name,
      onConfirm: () async {
        final ok = await ref
            .read(companyDashboardProvider.notifier)
            .removeCategory(cat.id);
        if (context.mounted) Navigator.of(context).pop();
        if (ok && context.mounted) _showSnack(context, context.l10n.saveSuccess);
      },
    );
  }

  // ── Services ──────────────────────────────────────────────────────────────

  void showAddServiceDialog(BuildContext context, String categoryId) {
    _showServiceDialog(context: context, categoryId: categoryId);
  }

  void showEditServiceDialog(
      BuildContext context, String categoryId, MyServiceModel svc) {
    _showServiceDialog(context: context, categoryId: categoryId, service: svc);
  }

  void confirmDeleteService(
      BuildContext context, String categoryId, MyServiceModel svc) {
    dashboardShowConfirmDialog(
      context: context,
      title: svc.name,
      onConfirm: () async {
        final ok = await ref
            .read(companyDashboardProvider.notifier)
            .removeService(serviceId: svc.id, categoryId: categoryId);
        if (context.mounted) Navigator.of(context).pop();
        if (ok && context.mounted) _showSnack(context, context.l10n.saveSuccess);
      },
    );
  }

  void _showServiceDialog({
    required BuildContext context,
    required String categoryId,
    MyServiceModel? service,
  }) {
    final nameCtrl = TextEditingController(text: service?.name ?? '');
    final durationCtrl = TextEditingController(
        text: service != null ? service.durationMinutes.toString() : '');
    final priceCtrl = TextEditingController(
        text: service != null ? service.price.toStringAsFixed(2) : '');
    final maxCtrl =
        TextEditingController(text: service?.maxConcurrent?.toString() ?? '');
    final isCapacity =
        ref.read(companyDashboardProvider).company?.bookingMode ==
            'capacity_based';

    showDialog<void>(
      context: context,
      builder: (ctx) => _ServiceDialog(
        nameCtrl: nameCtrl,
        durationCtrl: durationCtrl,
        priceCtrl: priceCtrl,
        maxCtrl: maxCtrl,
        isCapacity: isCapacity,
        isEdit: service != null,
        onSave: () async {
          final name = nameCtrl.text.trim().capitalize;
          final duration = int.tryParse(durationCtrl.text.trim()) ?? 0;
          final price =
              double.tryParse(priceCtrl.text.trim().replaceAll(',', '.')) ??
                  0.0;
          final maxConcurrent =
              isCapacity ? int.tryParse(maxCtrl.text.trim()) : null;
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
          if (ok && context.mounted) _showSnack(context, context.l10n.saveSuccess);
        },
      ),
    );
  }

  // ── Employees ─────────────────────────────────────────────────────────────

  void showInviteEmployeeDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => _InviteEmployeeDialog(
        emailCtrl: emailCtrl,
        onSave: () async {
          final email = emailCtrl.text.trim();
          if (email.isEmpty) return;
          final ok = await ref
              .read(companyDashboardProvider.notifier)
              .inviteEmployee(email: email, specialties: const []);
          if (ctx.mounted) Navigator.of(ctx).pop();
          if (ok && context.mounted) _showSnack(context, context.l10n.saveSuccess);
        },
      ),
    );
  }

  void showCreateEmployeeDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => _CreateEmployeeDialog(
        nameCtrl: nameCtrl,
        emailCtrl: emailCtrl,
        onSave: () async {
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
          if (ok && context.mounted) _showSnack(context, context.l10n.saveSuccess);
        },
      ),
    );
  }

  void showEditEmployeeDialog(
    BuildContext context,
    MyEmployeeModel emp,
    List<MyServiceModel> allServices,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => DashboardEditEmployeeDialog(
        employee: emp,
        allServices: allServices,
        onSave: (serviceIds) async {
          final ok = await ref
              .read(companyDashboardProvider.notifier)
              .editEmployee(emp.id, {'service_ids': serviceIds});
          if (ctx.mounted) Navigator.of(ctx).pop();
          if (ok && context.mounted) _showSnack(context, context.l10n.saveSuccess);
        },
      ),
    );
  }

  void confirmRemoveEmployee(BuildContext context, MyEmployeeModel emp) {
    dashboardShowConfirmDialog(
      context: context,
      title: emp.fullName,
      onConfirm: () async {
        final ok =
            await ref.read(companyDashboardProvider.notifier).removeEmployee(emp.id);
        if (context.mounted) Navigator.of(context).pop();
        if (ok && context.mounted) _showSnack(context, context.l10n.saveSuccess);
      },
    );
  }

  // ── Opening hours ─────────────────────────────────────────────────────────

  void showEditHoursDialog(
      BuildContext context, MyCompanyModel company, List<String> dayLabels) {
    final hoursMap = {for (final h in company.openingHours) h.dayOfWeek: h};
    final editableHours = List.generate(
      7,
      (i) => hoursMap[i] ?? OpeningHourModel(dayOfWeek: i, isClosed: true),
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => DashboardHoursEditDialog(
        hours: editableHours,
        dayLabels: dayLabels,
        onSave: (updated) async {
          final ok = await ref
              .read(companyDashboardProvider.notifier)
              .saveHours(updated);
          if (ctx.mounted) Navigator.of(ctx).pop();
          if (ok && context.mounted) _showSnack(context, context.l10n.saveSuccess);
        },
      ),
    );
  }

  // ── Gallery ───────────────────────────────────────────────────────────────

  Future<void> pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null) return;

    // Read bytes — works on both mobile (File-backed) and web (blob-backed).
    final bytes = await picked.readAsBytes();
    final filename = picked.name.isNotEmpty ? picked.name : 'photo.jpg';

    final ok = await ref.read(companyDashboardProvider.notifier).uploadPhoto(
          bytes: bytes,
          filename: filename,
        );
    if (!ok && mounted) {
      _showSnack(context, context.l10n.galleryUploadError);
    }
  }

  Future<void> confirmDeleteGalleryPhoto(GalleryPhotoModel photo) async {
    final ok = await ref
        .read(companyDashboardProvider.notifier)
        .deleteGalleryPhoto(photo.id);
    if (!ok && mounted) {
      _showSnack(context, context.l10n.galleryUploadError);
    }
  }

  Future<void> reorderGalleryPhotos(
      List<GalleryPhotoModel> reordered) async {
    await ref
        .read(companyDashboardProvider.notifier)
        .reorderGalleryPhotos(reordered);
  }

  void _showSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: CompanyDashboardScreenMobile(
        onEditCompany: (company) => showEditCompanyDialog(context, company),
        onAddCategory: () => showAddCategoryDialog(context),
        onEditCategory: (cat) => showEditCategoryDialog(context, cat),
        onDeleteCategory: (cat) => confirmDeleteCategory(context, cat),
        onAddService: (catId) => showAddServiceDialog(context, catId),
        onEditService: (catId, svc) => showEditServiceDialog(context, catId, svc),
        onDeleteService: (catId, svc) =>
            confirmDeleteService(context, catId, svc),
        onInviteEmployee: () => showInviteEmployeeDialog(context),
        onCreateEmployee: () => showCreateEmployeeDialog(context),
        onEditEmployee: (emp, services) =>
            showEditEmployeeDialog(context, emp, services),
        onRemoveEmployee: (emp) => confirmRemoveEmployee(context, emp),
        onEditHours: (company, labels) =>
            showEditHoursDialog(context, company, labels),
        onPickAndUploadPhoto: pickAndUploadPhoto,
        onDeleteGalleryPhoto: confirmDeleteGalleryPhoto,
        onReorderGalleryPhotos: reorderGalleryPhotos,
      ),
      desktop: CompanyDashboardScreenDesktop(
        onEditCompany: (company) => showEditCompanyDialog(context, company),
        onAddCategory: () => showAddCategoryDialog(context),
        onEditCategory: (cat) => showEditCategoryDialog(context, cat),
        onDeleteCategory: (cat) => confirmDeleteCategory(context, cat),
        onAddService: (catId) => showAddServiceDialog(context, catId),
        onEditService: (catId, svc) => showEditServiceDialog(context, catId, svc),
        onDeleteService: (catId, svc) =>
            confirmDeleteService(context, catId, svc),
        onInviteEmployee: () => showInviteEmployeeDialog(context),
        onCreateEmployee: () => showCreateEmployeeDialog(context),
        onEditEmployee: (emp, services) =>
            showEditEmployeeDialog(context, emp, services),
        onRemoveEmployee: (emp) => confirmRemoveEmployee(context, emp),
        onEditHours: (company, labels) =>
            showEditHoursDialog(context, company, labels),
        onPickAndUploadPhoto: pickAndUploadPhoto,
        onDeleteGalleryPhoto: confirmDeleteGalleryPhoto,
        onReorderGalleryPhotos: reorderGalleryPhotos,
      ),
    );
  }
}

// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Shared dialog widgets used by both presentations (via wrapper)
// ---------------------------------------------------------------------------

class _CompanyEditDialog extends StatefulWidget {
  final MyCompanyModel company;
  final void Function(Map<String, dynamic> payload) onSave;

  const _CompanyEditDialog({
    required this.company,
    required this.onSave,
  });

  @override
  State<_CompanyEditDialog> createState() => _CompanyEditDialogState();
}

class _CompanyEditDialogState extends State<_CompanyEditDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _phoneSecondaryCtrl;
  late final TextEditingController _descCtrl;
  late final ValueNotifier<int> _minCancelHours;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    _nameCtrl = TextEditingController(text: c.name);
    _addressCtrl = TextEditingController(text: c.address);
    _cityCtrl = TextEditingController(text: c.city);
    _phoneCtrl = TextEditingController(text: c.phone);
    _phoneSecondaryCtrl = TextEditingController(text: c.phoneSecondary ?? '');
    _descCtrl = TextEditingController(text: c.description ?? '');
    _minCancelHours = ValueNotifier<int>(c.minCancelHours);
    _latitude = c.latitude;
    _longitude = c.longitude;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    _phoneSecondaryCtrl.dispose();
    _descCtrl.dispose();
    _minCancelHours.dispose();
    super.dispose();
  }

  void _save() {
    final secondaryRaw = _phoneSecondaryCtrl.text.trim();
    widget.onSave({
      'name': _nameCtrl.text.trim().titleCase,
      'address': _addressCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'phone_secondary': secondaryRaw.isEmpty ? null : secondaryRaw,
      'description': _descCtrl.text.trim(),
      'min_cancel_hours': _minCancelHours.value,
      // Only include lat/lng when actually set — backend validator requires
      // both-or-neither, and we don't want to wipe existing coords.
      if (_latitude != null && _longitude != null) ...{
        'latitude': _latitude,
        'longitude': _longitude,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.companyInfo),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_nameCtrl, l.salonName, Icons.storefront_outlined),
            // Address + city + GPS — shared component handles Google Places
            // autocomplete, auto-fill of city, and GPS fallback. Manual
            // edits to the city invalidate the captured lat/lng.
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SalonLocationFields(
                addressController: _addressCtrl,
                cityController: _cityCtrl,
                latitude: _latitude,
                longitude: _longitude,
                onLocationCaptured: (lat, lng) => setState(() {
                  _latitude = lat;
                  _longitude = lng;
                }),
                onLocationInvalidated: () => setState(() {
                  _latitude = null;
                  _longitude = null;
                }),
                onPlaceSelected: (details) => setState(() {
                  _latitude = details.latitude;
                  _longitude = details.longitude;
                  if (details.city != null && details.city!.isNotEmpty) {
                    _cityCtrl.text = details.city!;
                  }
                }),
              ),
            ),
            _field(_phoneCtrl, l.phone, Icons.phone_outlined,
                type: TextInputType.phone),
            _field(_phoneSecondaryCtrl, l.phoneSecondary, Icons.phone_outlined,
                type: TextInputType.phone),
            _field(_descCtrl, l.descriptionLabel, Icons.notes_outlined,
                maxLines: 3),
            _MinCancelHoursStepper(notifier: _minCancelHours),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7A2232)),
          onPressed: _save,
          child: Text(l.saveChanges),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? type,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppTextField(
        controller: ctrl,
        label: label,
        prefixIcon: icon,
        keyboardType: type,
        maxLines: maxLines ?? 1,
      ),
    );
  }
}

class _ServiceDialog extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController durationCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController maxCtrl;
  final bool isCapacity;
  final bool isEdit;
  final VoidCallback onSave;

  const _ServiceDialog({
    required this.nameCtrl,
    required this.durationCtrl,
    required this.priceCtrl,
    required this.maxCtrl,
    required this.isCapacity,
    required this.isEdit,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(isEdit ? l.editServiceTitle : l.addService),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(nameCtrl, l.service, Icons.content_cut_rounded),
            _field(durationCtrl, l.durationMinLabel, Icons.timer_outlined,
                type: TextInputType.number),
            _field(priceCtrl, l.priceEurLabel, Icons.euro_outlined,
                type: const TextInputType.numberWithOptions(decimal: true)),
            if (isCapacity)
              _field(maxCtrl, l.maxCapacityLabel, Icons.people_outline_rounded,
                  type: TextInputType.number),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7A2232)),
          onPressed: onSave,
          child: Text(l.saveChanges),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? type,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppTextField(
        controller: ctrl,
        label: label,
        prefixIcon: icon,
        keyboardType: type,
      ),
    );
  }
}

class _InviteEmployeeDialog extends StatelessWidget {
  final TextEditingController emailCtrl;
  final VoidCallback onSave;

  const _InviteEmployeeDialog({
    required this.emailCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.inviteEmployee),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppTextField(
              controller: emailCtrl,
              label: l.email,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7A2232)),
          onPressed: onSave,
          child: Text(l.saveChanges),
        ),
      ],
    );
  }
}

class _CreateEmployeeDialog extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final VoidCallback onSave;

  const _CreateEmployeeDialog({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.createEmployeeTitle),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppTextField(
              controller: nameCtrl,
              label: l.firstName,
              prefixIcon: Icons.person_outline_rounded,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppTextField(
              controller: emailCtrl,
              label: l.email,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7A2232)),
          onPressed: onSave,
          child: Text(l.saveChanges),
        ),
      ],
    );
  }
}

/// Stepper (-/+) éditorial pour le délai minimum d'annulation.
/// Valeurs : 0..24 heures. 0 = pas de contrainte.
class _MinCancelHoursStepper extends StatelessWidget {
  final ValueNotifier<int> notifier;
  const _MinCancelHoursStepper({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ValueListenableBuilder<int>(
        valueListenable: notifier,
        builder: (context, value, _) {
          return Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD9CAB3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_off_outlined,
                    size: 20, color: Color(0xFF716059)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.minCancelHoursLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF716059),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value == 0
                            ? l.minCancelHoursHint
                            : '$value h',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF171311),
                        ),
                      ),
                    ],
                  ),
                ),
                _StepBtn(
                  icon: Icons.remove_rounded,
                  onTap: value > 0 ? () => notifier.value = value - 1 : null,
                ),
                const SizedBox(width: 4),
                _StepBtn(
                  icon: Icons.add_rounded,
                  onTap: value < 24 ? () => notifier.value = value + 1 : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled
          ? const Color(0xFF7A2232).withValues(alpha: 0.08)
          : const Color(0xFFD9CAB3).withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? const Color(0xFF7A2232)
                : const Color(0xFF716059).withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
