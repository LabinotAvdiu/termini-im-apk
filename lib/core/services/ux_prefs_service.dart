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

// C17 / C18 — booking flow engagement counters
const _kCompletedBookingsKey = 'completed_bookings_count';
const _kSharePromptShownKey = 'share_prompt_shown';
const _kLastReviewPromptAtKey = 'last_review_prompt_at';

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

  // ── C17 / C18 — Booking engagement counters ──────────────────────────────

  Future<int> getCompletedBookingsCount() async {
    final v = await _storage.read(key: _kCompletedBookingsKey);
    return int.tryParse(v ?? '0') ?? 0;
  }

  Future<void> incrementCompletedBookings() async {
    final current = await getCompletedBookingsCount();
    await _storage.write(
        key: _kCompletedBookingsKey, value: (current + 1).toString());
  }

  Future<bool> isSharePromptShown() async {
    final v = await _storage.read(key: _kSharePromptShownKey);
    return v == 'true';
  }

  Future<void> setSharePromptShown() =>
      _storage.write(key: _kSharePromptShownKey, value: 'true');

  Future<DateTime?> getLastReviewPromptAt() async {
    final v = await _storage.read(key: _kLastReviewPromptAtKey);
    if (v == null) return null;
    return DateTime.tryParse(v);
  }

  Future<void> setLastReviewPromptAt(DateTime dt) =>
      _storage.write(key: _kLastReviewPromptAtKey, value: dt.toIso8601String());
}
