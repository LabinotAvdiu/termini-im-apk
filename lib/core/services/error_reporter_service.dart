import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/api_constants.dart';
import 'models/error_report.dart';

/// E28 — Remonte les erreurs Flutter au backend Termini Im.
///
/// Architecture :
/// - Buffer en mémoire (max [_flushThreshold] erreurs).
/// - Flush automatique toutes les [_flushInterval] secondes si buffer non vide.
/// - Flush immédiat dès que le buffer atteint [_flushThreshold].
/// - Flush best-effort à l'arrêt de l'app via [onAppLifecycleChange].
///
/// Anti-boucle : les erreurs générées par l'upload lui-même sont ignorées
/// (path `/errors` exclus dans le Dio interceptor).
///
/// Usage :
/// ```dart
/// await ErrorReporterService.instance.init();
/// ErrorReporterService.instance.report(ErrorReport(...));
/// ```
class ErrorReporterService {
  ErrorReporterService._();

  static final ErrorReporterService instance = ErrorReporterService._();

  // ---------------------------------------------------------------------------
  // Config
  // ---------------------------------------------------------------------------

  static const int _flushThreshold = 10;
  static const Duration _flushInterval = Duration(seconds: 30);

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  final List<ErrorReport> _buffer = [];
  Timer? _flushTimer;

  /// Version de l'app (ex: "1.0.0+2"). Populé par [init].
  String appVersion = 'unknown';

  /// Dio dédié sans intercepteur auth pour l'upload des erreurs.
  /// On utilise un Dio séparé pour éviter le circular dependency avec
  /// DioClient (qui dépend à son tour d'ErrorReporterService via le Dio interceptor).
  late final Dio _dio;

  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------

  /// À appeler dans main() après NotificationService.init().
  ///
  /// - Résout la version app via package_info_plus.
  /// - Démarre le timer de flush périodique.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      appVersion = 'unknown';
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _startFlushTimer();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Enfile une erreur dans le buffer.
  ///
  /// Thread-safe en Dart car tout s'exécute sur la même isolate event loop.
  /// Si le buffer atteint [_flushThreshold], un flush immédiat est déclenché.
  void report(ErrorReport report) {
    if (!_initialized) {
      debugPrint('[ErrorReporter] report() appelé avant init() — erreur ignorée');
      return;
    }
    _buffer.add(report);
    if (_buffer.length >= _flushThreshold) {
      _flush();
    }
  }

  /// À appeler depuis le WidgetsBindingObserver quand l'app passe en
  /// background / est fermée — flush best-effort.
  void onAppPaused() {
    if (_buffer.isNotEmpty) {
      _flush();
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) {
      if (_buffer.isNotEmpty) {
        _flush();
      }
    });
  }

  /// Vide le buffer et envoie les erreurs au backend.
  ///
  /// En cas d'échec réseau / 5xx : les erreurs sont abandonnées (pas de re-enqueue).
  /// Raison : éviter un cycle infini où les erreurs d'upload créent plus d'erreurs.
  void _flush() {
    if (_buffer.isEmpty) return;

    // Capture atomique : vide le buffer avant l'appel async pour éviter
    // qu'un report() concurrent double-envoie la même erreur.
    final batch = List<ErrorReport>.from(_buffer);
    _buffer.clear();

    _uploadBatch(batch);
  }

  Future<void> _uploadBatch(List<ErrorReport> batch) async {
    try {
      await _dio.post(
        ApiConstants.clientErrors,
        data: {'errors': batch.map((e) => e.toJson()).toList()},
      );
    } catch (e) {
      // Echec silencieux — on ne re-enqueue jamais pour éviter les boucles.
      debugPrint('[ErrorReporter] Flush échoué (${batch.length} erreurs abandonnées): $e');
    }
  }
}

// ---------------------------------------------------------------------------
// Platform detector helper (utilisé par main.dart + Dio interceptor)
// ---------------------------------------------------------------------------

/// Retourne la plateforme courante au format attendu par le backend.
/// Valeurs possibles : android | ios | web.
String detectPlatform() {
  if (kIsWeb) return 'web';
  try {
    // ignore: do_not_use_environment
    const platform = String.fromEnvironment('FLUTTER_PLATFORM', defaultValue: '');
    if (platform.isNotEmpty) return platform;
  } catch (_) {}

  // Fallback via defaultTargetPlatform (disponible sans dart:io)
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.iOS:
      return 'ios';
    default:
      return 'web';
  }
}
