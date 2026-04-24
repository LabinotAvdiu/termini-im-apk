import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Clés Remote Config utilisées dans l'app.
abstract class RCKeys {
  static const forceUpdateRequired    = 'force_update_required';
  static const maintenanceMode        = 'maintenance_mode';
  static const marketingNotifsEnabled = 'marketing_notifs_enabled';
  static const diasporaBanner         = 'diaspora_banner';
  static const newOnboardingVariant   = 'new_onboarding_variant';
  static const shareIncentiveEnabled  = 'share_incentive_enabled';
}

/// Valeurs par défaut appliquées localement quand Firebase est inaccessible.
/// Ces valeurs DOIVENT correspondre exactement à celles créées dans la
/// Firebase Console → Remote Config (voir section Console dans le rapport).
const Map<String, dynamic> _defaults = {
  RCKeys.forceUpdateRequired:    false,
  RCKeys.maintenanceMode:        false,
  RCKeys.marketingNotifsEnabled: true,
  RCKeys.diasporaBanner:         false,
  RCKeys.newOnboardingVariant:   'control',
  RCKeys.shareIncentiveEnabled:  false,
};

class RemoteConfigService {
  RemoteConfigService._();

  static final RemoteConfigService instance = RemoteConfigService._();

  FirebaseRemoteConfig get _rc => FirebaseRemoteConfig.instance;

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------

  /// À appeler dans main() AVANT runApp().
  ///
  /// fetchInterval : 1 h en prod, 0 en debug (durée minimale Firebase = 60 s,
  /// mais le mode debug lève la limite via [fetchAndActivate]).
  Future<void> init() async {
    try {
      await _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 1),
      ));
      await _rc.setDefaults(_defaults);
      await _rc.fetchAndActivate();
    } catch (e) {
      // En cas d'échec (offline, quota), les valeurs par défaut restent actives.
      debugPrint('[RemoteConfig] init échoué — valeurs par défaut actives: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Getters typés
  // ---------------------------------------------------------------------------

  bool get forceUpdateRequired =>
      _rc.getBool(RCKeys.forceUpdateRequired);

  bool get maintenanceMode =>
      _rc.getBool(RCKeys.maintenanceMode);

  bool get marketingNotifsEnabled =>
      _rc.getBool(RCKeys.marketingNotifsEnabled);

  bool get diasporaBanner =>
      _rc.getBool(RCKeys.diasporaBanner);

  /// Valeurs possibles : 'control' | 'variant_a' | 'variant_b'
  String get newOnboardingVariant =>
      _rc.getString(RCKeys.newOnboardingVariant);

  bool get shareIncentiveEnabled =>
      _rc.getBool(RCKeys.shareIncentiveEnabled);
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final remoteConfigProvider = Provider<RemoteConfigService>(
  (_) => RemoteConfigService.instance,
);
