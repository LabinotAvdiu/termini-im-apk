import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/salon_location_fields.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/company_dashboard_provider.dart';

/// Red warning surfaced to owners on `/home` and on the "Mon Salon" dashboard
/// when their salon has no geocoding (no Google address + no GPS).
///
/// Without coordinates the salon can't be ranked in location-based searches,
/// which is a big deal for discovery in a small country like Kosovo where
/// users filter by proximity first.
///
/// Tap opens a bottom sheet with the shared [SalonLocationFields]: the owner
/// can either pick a Google-validated address or capture GPS, then save.
class SalonGeocodingBanner extends ConsumerStatefulWidget {
  const SalonGeocodingBanner({super.key});

  @override
  ConsumerState<SalonGeocodingBanner> createState() =>
      _SalonGeocodingBannerState();
}

class _SalonGeocodingBannerState extends ConsumerState<SalonGeocodingBanner> {
  bool _bootstrapped = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    // Only owners care about geocoding — employees can't fix it, clients
    // shouldn't see it. Bail early before touching company state.
    if (!auth.isOwner) return const SizedBox.shrink();

    final company = ref.watch(companyDashboardProvider).company;

    // Lazy-load the owner's salon the first time the banner renders on /home
    // — the full dashboard payload is only fetched when the user opens the
    // "Mon Salon" tab, but we need the basic geocoding flag here.
    if (!_bootstrapped && company == null) {
      _bootstrapped = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(companyDashboardProvider.notifier).loadCompanyOnly();
      });
    }

    if (company == null || company.hasGeocoding) {
      return const SizedBox.shrink();
    }

    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openFixDialog(context, ref),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.55),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 20,
                  color: AppColors.error,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.salonGeocodingBannerTitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.salonGeocodingBannerBody,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openFixDialog(BuildContext context, WidgetRef ref) async {
  final company = ref.read(companyDashboardProvider).company;
  if (company == null) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _GeocodingFixSheet(
      initialAddress: company.address,
      initialCity: company.city,
    ),
  );
}

class _GeocodingFixSheet extends ConsumerStatefulWidget {
  final String initialAddress;
  final String initialCity;

  const _GeocodingFixSheet({
    required this.initialAddress,
    required this.initialCity,
  });

  @override
  ConsumerState<_GeocodingFixSheet> createState() => _GeocodingFixSheetState();
}

class _GeocodingFixSheetState extends ConsumerState<_GeocodingFixSheet> {
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  double? _latitude;
  double? _longitude;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initialAddress);
    _cityController = TextEditingController(text: widget.initialCity);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Need either valid Google address (lat/lng from Places) or GPS capture.
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.salonGeocodingDialogSubtitle)),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await ref
        .read(companyDashboardProvider.notifier)
        .updateCompanyInfo({
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.salonGeocodingSuccessToast)),
      );
    } else {
      final err = ref.read(companyDashboardProvider).error;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.md + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Grab handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            l.salonGeocodingDialogTitle,
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 4),
          Text(
            l.salonGeocodingDialogSubtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SalonLocationFields(
            addressController: _addressController,
            cityController: _cityController,
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
                _cityController.text = details.city!;
              }
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: l.salonGeocodingSaveCta,
            onPressed: _saving ? null : _save,
            isLoading: _saving,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}
