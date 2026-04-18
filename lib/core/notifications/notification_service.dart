import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ---------------------------------------------------------------------------
// Background message handler — DOIT être une fonction top-level (isolate séparé).
// Appelée par FCM quand l'app est terminée ou en arrière-plan.
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // Firebase doit être réinitialisé dans l'isolate background.
  await Firebase.initializeApp();
  debugPrint(
    '[FCM background] type=${message.data['type']} '
    'appointmentId=${message.data['appointmentId']}',
  );
}

// ---------------------------------------------------------------------------
// NotificationService
// ---------------------------------------------------------------------------

/// Gère l'ensemble du cycle de vie des notifications push :
/// - Initialisation Firebase + flutter_local_notifications
/// - Demande de permission (iOS, Android 13+, Web)
/// - Récupération et envoi du FCM token au backend
/// - Gestion foreground (notification locale) / background / terminated
/// - Désenregistrement propre au logout
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  /// `true` si Firebase est correctement initialisé.
  /// Si `false`, le service est désactivé mais l'app ne crashe pas.
  static bool _firebaseReady = false;
  static bool get isReady => _firebaseReady;

  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  // Canal Android haute priorité — bordeaux éditorial Termini
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'termini_appointments',
    'Termini im — Rendez-vous',
    description: 'Confirmations, rappels et notifications de rendez-vous.',
    importance: Importance.high,
    ledColor: Color(0xFF7A2232),
    playSound: true,
  );

  // Callback de navigation injecté depuis main.dart une fois le router prêt.
  // Signature : (appointmentId, companyId) → void
  static void Function(String? appointmentId, String? companyId)? _onTap;

  /// Injecte le callback de navigation GoRouter (appelé depuis main.dart).
  static void setNavigationCallback(
    void Function(String? appointmentId, String? companyId) callback,
  ) {
    _onTap = callback;
  }

  // ---------------------------------------------------------------------------
  // init — appelé depuis main.dart après WidgetsFlutterBinding.ensureInitialized
  // ---------------------------------------------------------------------------

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (e) {
      // L'app continue sans push si Firebase n'est pas configuré
      // (placeholders en dev, ou config manquante).
      debugPrint(
        '[NotificationService] Firebase non configuré — '
        'notifications push désactivées. Détail: $e',
      );
      return;
    }

    // Handler background (top-level function, isolate séparé).
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Canal local notifications Android.
    if (!kIsWeb) {
      final androidPlugin = _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_channel);
    }

    // Initialise flutter_local_notifications + callback de tap.
    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          final parts = payload.split('|');
          final appointmentId = parts.isNotEmpty ? parts[0] : null;
          final companyId = parts.length > 1 ? parts[1] : null;
          _onTap?.call(
            appointmentId?.isEmpty ?? true ? null : appointmentId,
            companyId?.isEmpty ?? true ? null : companyId,
          );
        }
      },
    );

    // Demande la permission et configure les options foreground iOS.
    await _requestPermissionAndRegister();

    // Messages reçus quand l'app est au premier plan.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Tap sur notification FCM — app en background (pas terminée).
    FirebaseMessaging.onMessageOpenedApp.listen(_navigateFromMessage);

    // App lancée depuis une notification (état terminé).
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // Différé pour laisser GoRouter s'initialiser avant la navigation.
      Future.delayed(const Duration(milliseconds: 600), () {
        _navigateFromMessage(initial);
      });
    }

    // Rafraîchissement automatique du token FCM.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _cachedToken = newToken;
      debugPrint('[FCM] Token rafraîchi');
      // Le re-register vers le backend sera déclenché par AuthNotifier
      // via registerToken() qui lit _cachedToken s'il est déjà connu.
    });
  }

  // ---------------------------------------------------------------------------
  // Permission
  // ---------------------------------------------------------------------------

  static Future<void> _requestPermissionAndRegister() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('[FCM] Statut permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // iOS — afficher les notifications même quand l'app est au premier plan.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Token management
  // ---------------------------------------------------------------------------

  static String? _cachedToken;

  /// Récupère le FCM token et appelle [registerCallback] avec (token, platform).
  /// [registerCallback] doit appeler POST /api/me/devices.
  static Future<void> registerToken(
    Future<void> Function(String token, String platform) registerCallback,
  ) async {
    if (!_firebaseReady) return;

    try {
      final token = await FirebaseMessaging.instance.getToken(
        // TODO: remplacer 'PLACEHOLDER_VAPID_KEY' par la vraie clé VAPID
        // depuis Firebase Console → Cloud Messaging → Certificats push web.
        vapidKey: kIsWeb ? 'PLACEHOLDER_VAPID_KEY' : null,
      );
      if (token == null) {
        debugPrint('[FCM] Token null — permission refusée ?');
        return;
      }

      _cachedToken = token;
      final platform = _detectPlatform();
      await registerCallback(token, platform);
      debugPrint('[FCM] Token enregistré ($platform)');
    } catch (e) {
      debugPrint('[FCM] Erreur registerToken: $e');
    }
  }

  /// Supprime le token côté backend et invalide le FCM token local.
  /// Doit être appelé AVANT de vider le JWT en mémoire (logout).
  static Future<void> unregisterToken(
    Future<void> Function(String token) unregisterCallback,
  ) async {
    if (!_firebaseReady) return;

    try {
      final token =
          _cachedToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await unregisterCallback(token);
        await FirebaseMessaging.instance.deleteToken();
        _cachedToken = null;
        debugPrint('[FCM] Token supprimé');
      }
    } catch (e) {
      debugPrint('[FCM] Erreur unregisterToken: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Foreground message handler
  // ---------------------------------------------------------------------------

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint(
      '[FCM foreground] type=${message.data['type']} '
      'appointmentId=${message.data['appointmentId']}',
    );

    final notification = message.notification;
    if (notification == null) return;

    final appointmentId = message.data['appointmentId'] as String?;
    final companyId = message.data['companyId'] as String?;
    final payload = '${appointmentId ?? ''}|${companyId ?? ''}';

    await _localNotif.show(
      // Génère un ID stable (pas de doublon mais écrase si même notification).
      (message.messageId ?? '${appointmentId ?? ''}${message.sentTime?.millisecondsSinceEpoch ?? 0}').hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF7A2232),
          // Pas d'icône custom pour l'instant — utilise le launcher.
          // Pour ajouter une icône dédiée : crée res/drawable/ic_notification.xml
          // et remplace null par '@drawable/ic_notification'.
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation vers le détail du RDV
  // ---------------------------------------------------------------------------

  static void _navigateFromMessage(RemoteMessage message) {
    final appointmentId = message.data['appointmentId'] as String?;
    final companyId = message.data['companyId'] as String?;
    if (appointmentId != null || companyId != null) {
      _onTap?.call(appointmentId, companyId);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _detectPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }
}
