import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../network/places_datasource.dart';
import '../utils/extensions.dart';
import '../utils/location_helper.dart';
import '../utils/validators.dart';
import 'app_text_field.dart';
import 'place_autocomplete_field.dart';

/// Address autocomplete + city + GPS fallback — shared by the company signup
/// step 2, the post-social-auth company setup screen, and the "fix
/// geocoding" dialog opened from the owner's dashboard banner.
///
/// Behaviour:
///  * Google Places autocomplete on the address field — picks lat/lng + city
///  * If Google doesn't know the address (common for recent addresses in
///    Kosovo), the owner taps "use my GPS" to capture coordinates; the
///    typed address and city are kept untouched.
class SalonLocationFields extends StatefulWidget {
  final TextEditingController addressController;
  final TextEditingController cityController;
  final double? latitude;
  final double? longitude;
  final void Function(double lat, double lng) onLocationCaptured;
  final void Function(PlaceDetails details) onPlaceSelected;
  // Called when the owner manually edits the city field while lat/lng were
  // set — the captured GPS / Google position no longer matches the city, so
  // the parent should clear them and ask the user to re-capture.
  final VoidCallback? onLocationInvalidated;

  const SalonLocationFields({
    super.key,
    required this.addressController,
    required this.cityController,
    required this.latitude,
    required this.longitude,
    required this.onLocationCaptured,
    required this.onPlaceSelected,
    this.onLocationInvalidated,
  });

  @override
  State<SalonLocationFields> createState() => _SalonLocationFieldsState();
}

class _SalonLocationFieldsState extends State<SalonLocationFields> {
  bool _capturing = false;

  /// Last city text we observed — used to detect a *real* user edit.
  /// TextEditingController also fires listeners on selection/cursor moves
  /// (tapping into the field without typing), so we must compare the text
  /// itself rather than just counting notifications.
  String _lastKnownCity = '';

  @override
  void initState() {
    super.initState();
    _lastKnownCity = widget.cityController.text;
    widget.cityController.addListener(_onCityChanged);
  }

  @override
  void dispose() {
    widget.cityController.removeListener(_onCityChanged);
    super.dispose();
  }

  void _onCityChanged() {
    final current = widget.cityController.text;
    if (current == _lastKnownCity) return; // selection move, not a text edit
    _lastKnownCity = current;
    // Only call the parent if something to invalidate — saves rebuilds.
    if (widget.latitude != null || widget.longitude != null) {
      widget.onLocationInvalidated?.call();
    }
  }

  void _handlePlaceSelected(PlaceDetails details) {
    // Google is about to set the city text via the parent's callback.
    // Record the incoming value ahead of time so the listener sees the new
    // text == _lastKnownCity and treats it as programmatic, not user edit.
    if (details.city != null && details.city!.isNotEmpty) {
      _lastKnownCity = details.city!;
    }
    widget.onPlaceSelected(details);
  }

  Future<void> _captureGps() async {
    setState(() => _capturing = true);
    final result = await captureCurrentLocation();
    if (!mounted) return;
    setState(() => _capturing = false);
    if (result.isSuccess) {
      widget.onLocationCaptured(result.latitude!, result.longitude!);
      return;
    }
    final l = context.l10n;
    final message = switch (result.error) {
      LocationError.serviceDisabled => l.gpsErrorServiceDisabled,
      LocationError.permissionDenied => l.gpsErrorPermissionDenied,
      LocationError.permissionDeniedForever =>
          l.gpsErrorPermissionDeniedForever,
      LocationError.timeout => l.gpsErrorTimeout,
      _ => l.gpsErrorUnknown,
    };
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlaceAutocompleteField(
          controller: widget.addressController,
          label: l.address,
          hint: l.addressHintExample,
          onPlaceSelected: _handlePlaceSelected,
          validator: (v) => Validators.required(v, message: l.addressRequired),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: widget.cityController,
          label: l.city,
          hint: l.cityHint,
          prefixIcon: Icons.location_city_outlined,
          validator: (v) => Validators.required(v, message: l.cityRequired),
        ),
        const SizedBox(height: AppSpacing.sm),
        _GpsCaptureBlock(
          capturedLat: widget.latitude,
          capturedLng: widget.longitude,
          loading: _capturing,
          onTap: _capturing ? null : _captureGps,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// GPS capture pill — muted button + inline hint when nothing's captured,
// green checkmark + coord preview once the position is saved.
// ---------------------------------------------------------------------------
class _GpsCaptureBlock extends StatelessWidget {
  final double? capturedLat;
  final double? capturedLng;
  final bool loading;
  final VoidCallback? onTap;

  const _GpsCaptureBlock({
    required this.capturedLat,
    required this.capturedLng,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final captured = capturedLat != null && capturedLng != null;
    final label = captured
        ? context.l10n.gpsLocationCaptured
        : context.l10n.useMyGpsLocation;

    final bg = captured
        ? Colors.green.withValues(alpha: 0.08)
        : AppColors.background;
    final borderColor = captured
        ? Colors.green.withValues(alpha: 0.45)
        : AppColors.border;
    final fg = captured ? Colors.green.shade700 : AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Ink(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                children: [
                  if (loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    Icon(
                      captured
                          ? Icons.check_circle_rounded
                          : Icons.my_location_rounded,
                      size: 18,
                      color: fg,
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ),
                  if (captured)
                    Text(
                      '${capturedLat!.toStringAsFixed(4)}, ${capturedLng!.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (!captured) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: AppColors.textHint,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  context.l10n.gpsHintNoAddressOnGoogle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
