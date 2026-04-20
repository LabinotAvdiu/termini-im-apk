import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Result of a GPS capture attempt.
class LocationResult {
  final double? latitude;
  final double? longitude;
  final LocationError? error;

  const LocationResult({this.latitude, this.longitude, this.error});

  bool get isSuccess => latitude != null && longitude != null;
}

enum LocationError {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

/// Request location permission and return the current position. Designed to
/// be called from the signup/my-salon forms: cheap UX, one-shot capture.
///
/// Behaviour:
///  * Checks that location services are enabled (user has GPS on)
///  * Requests runtime permission if needed
///  * Returns a [LocationResult] with lat/lng **or** a typed [LocationError]
///    so the caller can show the right copy.
Future<LocationResult> captureCurrentLocation({
  Duration timeout = const Duration(seconds: 12),
}) async {
  try {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return const LocationResult(error: LocationError.serviceDisabled);
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.deniedForever) {
      return const LocationResult(error: LocationError.permissionDeniedForever);
    }
    if (perm == LocationPermission.denied) {
      return const LocationResult(error: LocationError.permissionDenied);
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: timeout,
      ),
    );
    return LocationResult(latitude: pos.latitude, longitude: pos.longitude);
  } on LocationServiceDisabledException {
    return const LocationResult(error: LocationError.serviceDisabled);
  } on PermissionDeniedException {
    return const LocationResult(error: LocationError.permissionDenied);
  } on TimeoutException {
    return const LocationResult(error: LocationError.timeout);
  } catch (_) {
    return const LocationResult(error: LocationError.unknown);
  }
}
