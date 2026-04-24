import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_review/in_app_review.dart';

import 'ux_prefs_service.dart';

// ---------------------------------------------------------------------------
// C18 — App Store / Play Store rating prompt
// ---------------------------------------------------------------------------

/// Gating rules (belt-and-suspenders on top of iOS/Android SDK limits):
///   1. Completed bookings count >= 3.
///   2. Not on web (native dialogs only).
///   3. Max once per year — stored in `ux_prefs_service.dart` via
///      `last_review_prompt_at`.
///
/// The function is safe to call on every post-booking navigation — it is
/// fully idempotent and async-safe.

const _kMinBookingsForReview = 3;
const _kReviewCooldownDays = 365;

// Shared service instance (same storage used across prefs features).
final _reviewPrefsService = UxPrefsService(const FlutterSecureStorage());

/// Call this at natural delight moments after a completed booking:
///   - Post-flow navigation back to home (after share prompt resolves)
///   - AppointmentsScreen first-load after status 'completed' is visible
///
/// [completedCount] may be passed in directly when already known (avoids
/// a redundant storage read). If null, the function reads it from prefs.
Future<void> maybeAskForAppStoreReview(
  WidgetRef ref, {
  int? completedCount,
}) async {
  // Web: native prompts are not available.
  if (kIsWeb) return;

  final service = _reviewPrefsService;

  // Rule 1 — completed bookings threshold.
  final count = completedCount ?? await service.getCompletedBookingsCount();
  if (count < _kMinBookingsForReview) return;

  // Rule 2 — cooldown: skip if we already prompted within the last year.
  final lastPrompt = await service.getLastReviewPromptAt();
  if (lastPrompt != null) {
    final daysSince = DateTime.now().difference(lastPrompt).inDays;
    if (daysSince < _kReviewCooldownDays) return;
  }

  // All gates passed — request the review.
  final inAppReview = InAppReview.instance;
  final isAvailable = await inAppReview.isAvailable();
  if (!isAvailable) return;

  await service.setLastReviewPromptAt(DateTime.now());
  await inAppReview.requestReview();
}
