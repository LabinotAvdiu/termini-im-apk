import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Wrapper léger autour de [FirebaseCrashlytics].
///
/// - Gating web  : Crashlytics ne supporte pas le web ; tous les appels sont
///   no-op quand [kIsWeb] est true.
/// - Gating debug: la collection est désactivée en mode debug (voir main.dart)
///   mais le wrapper log quand même en console pour faciliter le développement.
class CrashReporter {
  CrashReporter._();

  static final CrashReporter instance = CrashReporter._();

  /// Enregistre une erreur non-fatale (ou fatale si [fatal] est true).
  ///
  /// Utilise [debugPrint] en fallback si Crashlytics est indisponible (web,
  /// ou Firebase non initialisé).
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {
    if (kIsWeb) {
      debugPrint('[CrashReporter] ${fatal ? 'FATAL' : 'error'}: $error\n$stack');
      return;
    }
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: fatal,
        reason: reason,
      );
    } catch (e) {
      debugPrint('[CrashReporter] Impossible d\'enregistrer l\'erreur: $e');
    }
  }

  /// Ajoute un breadcrumb dans le rapport Crashlytics.
  void log(String message) {
    if (kIsWeb) {
      debugPrint('[CrashReporter] breadcrumb: $message');
      return;
    }
    try {
      FirebaseCrashlytics.instance.log(message);
    } catch (_) {
      debugPrint('[CrashReporter] log: $message');
    }
  }

  /// Associe l'utilisateur courant aux futurs rapports de crash.
  Future<void> setUserId(String userId) async {
    if (kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    } catch (_) {}
  }

  /// Efface l'identité utilisateur (appelé au logout).
  Future<void> clearUserId() async {
    if (kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier('');
    } catch (_) {}
  }
}
