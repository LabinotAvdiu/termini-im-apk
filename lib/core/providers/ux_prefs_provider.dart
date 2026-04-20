/// Riverpod providers for UX preferences.
///
/// [uxPrefsProvider] expose l'état complet des préférences UX.
/// Utilisation:
///   - ref.watch(uxPrefsProvider) → [UxPrefsState]
///   - ref.read(uxPrefsProvider.notifier).setHaptic(false)
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/ux_prefs_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class UxPrefsState {
  final bool hapticEnabled;
  final bool soundsEnabled;
  final bool animationsEnabled;
  final bool isLoaded;

  const UxPrefsState({
    this.hapticEnabled = true,
    this.soundsEnabled = false,
    this.animationsEnabled = true,
    this.isLoaded = false,
  });

  UxPrefsState copyWith({
    bool? hapticEnabled,
    bool? soundsEnabled,
    bool? animationsEnabled,
    bool? isLoaded,
  }) =>
      UxPrefsState(
        hapticEnabled: hapticEnabled ?? this.hapticEnabled,
        soundsEnabled: soundsEnabled ?? this.soundsEnabled,
        animationsEnabled: animationsEnabled ?? this.animationsEnabled,
        isLoaded: isLoaded ?? this.isLoaded,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UxPrefsNotifier extends StateNotifier<UxPrefsState> {
  UxPrefsNotifier(this._service) : super(const UxPrefsState()) {
    _load();
  }

  final UxPrefsService _service;

  Future<void> _load() async {
    final haptic = await _service.getHapticEnabled();
    final sounds = await _service.getSoundsEnabled();
    final animations = await _service.getAnimationsEnabled();
    if (!mounted) return;
    state = UxPrefsState(
      hapticEnabled: haptic,
      soundsEnabled: sounds,
      animationsEnabled: animations,
      isLoaded: true,
    );
  }

  Future<void> setHaptic(bool v) async {
    await _service.setHapticEnabled(v);
    if (!mounted) return;
    state = state.copyWith(hapticEnabled: v);
  }

  Future<void> setSounds(bool v) async {
    await _service.setSoundsEnabled(v);
    if (!mounted) return;
    state = state.copyWith(soundsEnabled: v);
  }

  Future<void> setAnimations(bool v) async {
    await _service.setAnimationsEnabled(v);
    if (!mounted) return;
    state = state.copyWith(animationsEnabled: v);
  }

  // ── Haptic helpers ───────────────────────────────────────────────────────

  void selectionClick() {
    if (!kIsWeb && state.hapticEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void lightImpact() {
    if (!kIsWeb && state.hapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void mediumImpact() {
    if (!kIsWeb && state.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _uxPrefsServiceProvider = Provider<UxPrefsService>((ref) {
  return const UxPrefsService(FlutterSecureStorage());
});

final uxPrefsProvider =
    StateNotifierProvider<UxPrefsNotifier, UxPrefsState>((ref) {
  return UxPrefsNotifier(ref.watch(_uxPrefsServiceProvider));
});
