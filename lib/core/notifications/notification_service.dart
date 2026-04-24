import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import 'models/in_app_notification.dart';

// ---------------------------------------------------------------------------
// Background message handler — DOIT être une fonction top-level (isolate séparé).
// Appelée par FCM quand l'app est terminée ou en arrière-plan.
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // Firebase doit être réinitialisé dans l'isolate background.
  // Web : options explicites obligatoires (firebase_core_web ne lit pas
  // index.html dans un isolate). Mobile : le plugin gradle/cocoapods fournit
  // la config implicitement.
  await Firebase.initializeApp(
    options: kIsWeb ? DefaultFirebaseOptions.web : null,
  );
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
  // Signature : (type, appointmentId, companyId) → void
  // [type] permet de router vers la bonne screen : un owner qui reçoit
  // `walk_in_created` doit atterrir sur Mon Salon / pending-approvals, un
  // client sur `/my-appointments` — pas sur une route `/appointments/:id`
  // qui n'existe pas.
  static void Function(
    String? type,
    String? appointmentId,
    String? companyId,
  )? _onTap;

  // Callback d'affichage in-app injecté depuis main.dart une fois Riverpod prêt.
  // Signature : (InAppNotification) → void
  static void Function(InAppNotification notification)? _onShowInApp;

  /// Injecte le callback de navigation GoRouter (appelé depuis main.dart).
  static void setNavigationCallback(
    void Function(String? type, String? appointmentId, String? companyId)
        callback,
  ) {
    _onTap = callback;
  }

  /// Injecte le callback d'affichage in-app (appelé depuis main.dart).
  ///
  /// Le callback doit appeler `inAppNotificationProvider.notifier.show(n)`.
  /// Tant qu'il n'est pas injecté, les notifs foreground tombent silencieusement
  /// — elles ne remontent pas en notif OS (comportement intentionnel : l'overlay
  /// n'est prêt qu'une fois l'arbre Riverpod monté).
  static void setInAppCallback(
    void Function(InAppNotification notification) callback,
  ) {
    _onShowInApp = callback;
  }

  // ---------------------------------------------------------------------------
  // init — appelé depuis main.dart après WidgetsFlutterBinding.ensureInitialized
  // ---------------------------------------------------------------------------

  static Future<void> init() async {
    try {
      // Web exige des options explicites ; mobile utilise la config gradle/plist.
      await Firebase.initializeApp(
        options: kIsWeb ? DefaultFirebaseOptions.web : null,
      );
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
          // Payload format : `type|appointmentId|companyId`
          final parts = payload.split('|');
          final type = parts.isNotEmpty ? parts[0] : null;
          final appointmentId = parts.length > 1 ? parts[1] : null;
          final companyId = parts.length > 2 ? parts[2] : null;
          _onTap?.call(
            type?.isEmpty ?? true ? null : type,
            appointmentId?.isEmpty ?? true ? null : appointmentId,
            companyId?.isEmpty ?? true ? null : companyId,
          );
        }
      },
    );

    // La permission n'est PLUS demandée à l'init — elle est demandée par
    // AuthNotifier juste après une authentification réussie (cf. `registerToken`).
    // Un visiteur anonyme ne voit donc jamais la popup navigateur / iOS, ce qui
    // respecte les guidelines App Store et réduit le taux de refus sur web.

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

  /// Demande la permission de recevoir des notifications push.
  /// Appelée uniquement après une authentification réussie (cf. [registerToken]).
  /// Retourne `true` si l'utilisateur a accepté (ou déjà accepté).
  static Future<bool> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('[FCM] Statut permission: ${settings.authorizationStatus}');

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (granted) {
      // iOS — afficher les notifications même quand l'app est au premier plan.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return granted;
  }

  // ---------------------------------------------------------------------------
  // Token management
  // ---------------------------------------------------------------------------

  static String? _cachedToken;

  /// Demande la permission, récupère le FCM token et l'envoie au backend via
  /// [registerCallback] — doit appeler POST /api/me/devices.
  ///
  /// Déclenche la popup système (Chrome / iOS / Android 13+) la première fois.
  /// Appelée **uniquement après authentification** par [AuthNotifier] — un
  /// visiteur anonyme ne verra donc jamais la popup.
  static Future<void> registerToken(
    Future<void> Function(String token, String platform) registerCallback,
  ) async {
    if (!_firebaseReady) return;

    try {
      // 1) Permission d'abord. Si refusée, on n'enregistre pas de token
      //    pourri côté backend (il serait inutilisable).
      final granted = await _requestPermission();
      if (!granted) {
        debugPrint('[FCM] Permission refusée — skip register');
        return;
      }

      // 2) Token. Sur web, la VAPID key est obligatoire pour que le Push API
      //    chiffre l'abonnement ; sur mobile elle est ignorée (null).
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb
            ? 'BCiD2i_Z8KNhZIUjhDfsxOfSROBJ7xMZW83ixfDgo5fASyNqA8Ct0dAbehqC-pxsbZGBLndQ_UQbpJPHZyFkebU'
            : null,
      );
      if (token == null) {
        debugPrint('[FCM] Token null malgré permission accordée');
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

  /// Lance un diagnostic complet de la chaîne FCM et retourne le résultat.
  ///
  /// Exposé en settings pour que l'utilisateur (ou le support) puisse voir
  /// immédiatement où la chaîne casse :
  /// Firebase init → permission système → token FCM → POST /me/devices.
  ///
  /// Si [registerCallback] est fourni, tente aussi l'upload backend ; sinon
  /// le champ `backendOk` reste null.
  static Future<FcmDiagnostic> runDiagnostic({
    Future<void> Function(String token, String platform)? registerCallback,
  }) async {
    if (!_firebaseReady) {
      return const FcmDiagnostic(
        firebaseReady: false,
        permissionStatus: 'unknown',
        token: null,
        platform: null,
        backendOk: null,
        backendError: null,
      );
    }

    String permissionStatus = 'unknown';
    String? token;
    bool? backendOk;
    String? backendError;

    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      permissionStatus = settings.authorizationStatus.name;

      // Si pas encore authorisé, on relance la demande (sur iOS/Android 13+
      // ça peut rouvrir la popup ; sinon ça renvoie le statut courant).
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        final refreshed = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        permissionStatus = refreshed.authorizationStatus.name;
      }

      token = await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb
            ? 'BCiD2i_Z8KNhZIUjhDfsxOfSROBJ7xMZW83ixfDgo5fASyNqA8Ct0dAbehqC-pxsbZGBLndQ_UQbpJPHZyFkebU'
            : null,
      );
      if (token != null) {
        _cachedToken = token;
      }

      if (token != null && registerCallback != null) {
        try {
          await registerCallback(token, _detectPlatform());
          backendOk = true;
        } catch (e) {
          backendOk = false;
          backendError = e.toString();
        }
      }
    } catch (e) {
      backendError = e.toString();
    }

    return FcmDiagnostic(
      firebaseReady: _firebaseReady,
      permissionStatus: permissionStatus,
      token: token,
      platform: token != null ? _detectPlatform() : null,
      backendOk: backendOk,
      backendError: backendError,
    );
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
      'notifTitle="${message.notification?.title}" '
      'notifBody="${message.notification?.body}" '
      'data=${message.data}',
    );

    // Web has quirks: when a SW is registered, FCM sometimes ships the
    // foreground `RemoteMessage` without the `notification` block (it's
    // handled by the SW for background, and the data-only side goes to
    // Flutter). Fall back to `message.data['title'] / body` if the backend
    // chose to duplicate them there, and last-resort to a generic placeholder
    // so the card isn't blank.
    final notifTitle = message.notification?.title;
    final notifBody = message.notification?.body;

    final title = (notifTitle != null && notifTitle.isNotEmpty)
        ? notifTitle
        : (message.data['title'] as String?) ?? 'Termini im';
    final body = (notifBody != null && notifBody.isNotEmpty)
        ? notifBody
        : (message.data['body'] as String?) ?? '';

    // If even after fallbacks we have nothing, silently drop — better no toast
    // than an empty one.
    if (title.isEmpty && body.isEmpty) return;

    final type = message.data['type'] as String?;
    final appointmentId = message.data['appointmentId'] as String?;
    final companyId = message.data['companyId'] as String?;

    final (:variant, :icon) = variantForType(type);

    final inApp = InAppNotification(
      title: title,
      body: body,
      variant: variant,
      icon: icon,
      deepLinkAppointmentId: appointmentId,
      deepLinkCompanyId: companyId,
      onTap: () => _onTap?.call(type, appointmentId, companyId),
    );

    if (_onShowInApp != null) {
      // L'overlay in-app est prêt — affichage éditorial, pas de notif OS.
      _onShowInApp!(inApp);
    } else {
      // Fallback : overlay pas encore injecté (edge case au démarrage).
      // On utilise flutter_local_notifications uniquement dans ce cas.
      // Payload format : `type|appointmentId|companyId` — relu ligne 145.
      final payload = '${type ?? ''}|${appointmentId ?? ''}|${companyId ?? ''}';
      await _localNotif.show(
        (message.messageId ??
                '${appointmentId ?? ''}${message.sentTime?.millisecondsSinceEpoch ?? 0}')
            .hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFF7A2232),
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
  }

  // ---------------------------------------------------------------------------
  // Navigation vers le détail du RDV
  // ---------------------------------------------------------------------------

  static void _navigateFromMessage(RemoteMessage message) {
    final type = message.data['type'] as String?;
    final appointmentId = message.data['appointmentId'] as String?;
    final companyId = message.data['companyId'] as String?;
    if (type != null || appointmentId != null || companyId != null) {
      _onTap?.call(type, appointmentId, companyId);
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

/// Résultat du diagnostic FCM — consommé par l'UI diagnostic dans Settings.
class FcmDiagnostic {
  final bool firebaseReady;
  final String permissionStatus; // 'authorized' | 'denied' | 'notDetermined' | 'provisional' | 'unknown'
  final String? token;
  final String? platform;
  /// null = non tenté, true = 204 No Content reçu, false = erreur backend.
  final bool? backendOk;
  final String? backendError;

  const FcmDiagnostic({
    required this.firebaseReady,
    required this.permissionStatus,
    required this.token,
    required this.platform,
    required this.backendOk,
    required this.backendError,
  });

  bool get permissionGranted =>
      permissionStatus == 'authorized' || permissionStatus == 'provisional';
  bool get tokenPresent => token != null && token!.isNotEmpty;
  bool get fullyOperational =>
      firebaseReady && permissionGranted && tokenPresent && backendOk == true;
}
