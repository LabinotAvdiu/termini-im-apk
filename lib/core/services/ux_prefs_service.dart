/// UX Preferences — haptic, sons, animations.
///
/// Persiste dans [FlutterSecureStorage].
/// Clés:
///   - haptic_enabled   (default true)
///   - ui_sounds_enabled (default false)
///   - animations_enabled (default true)
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kHapticKey = 'haptic_enabled';
const _kSoundsKey = 'ui_sounds_enabled';
const _kAnimationsKey = 'animations_enabled';

class UxPrefsService {
  const UxPrefsService(this._storage);

  final FlutterSecureStorage _storage;

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<bool> getHapticEnabled() async {
    final v = await _storage.read(key: _kHapticKey);
    return v == null ? true : v == 'true';
  }

  Future<bool> getSoundsEnabled() async {
    final v = await _storage.read(key: _kSoundsKey);
    return v == 'true';
  }

  Future<bool> getAnimationsEnabled() async {
    final v = await _storage.read(key: _kAnimationsKey);
    return v == null ? true : v == 'true';
  }

  // ── Write ────────────────────────────────────────────────────────────────

  Future<void> setHapticEnabled(bool v) =>
      _storage.write(key: _kHapticKey, value: v.toString());

  Future<void> setSoundsEnabled(bool v) =>
      _storage.write(key: _kSoundsKey, value: v.toString());

  Future<void> setAnimationsEnabled(bool v) =>
      _storage.write(key: _kAnimationsKey, value: v.toString());
}
