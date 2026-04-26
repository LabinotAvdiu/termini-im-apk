import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Sons d'interface — joués via audioplayers depuis assets/sounds/.
///
/// Trois sons éditoriaux courts (générés en synthèse, ~150-350ms) :
///   - success.wav : arpeggio C-E-G ascendant — confirmation RDV, avis envoyé
///   - error.wav   : buzz grave 220-180Hz — erreurs formulaires (réservé)
///   - notif.wav   : chime 660-880Hz — push reçu en foreground
///
/// Le toggle utilisateur `UxPrefsState.soundsEnabled` gate les sons UI
/// (success/error). Le son `notif` ignore le toggle car un push raté = info
/// perdue, et joue à volume modéré indépendamment.
class SoundService {
  SoundService._();

  // Lecteur dédié, partagé entre tous les sons. Mode `lowLatency` pour que
  // le déclenchement soit instantané (pas de buffering au premier appel).
  static final AudioPlayer _player = AudioPlayer()
    ..setPlayerMode(PlayerMode.lowLatency)
    ..setReleaseMode(ReleaseMode.stop);

  static bool _initialized = false;

  /// Pré-charge les sons en mémoire pour qu'aucun son n'ait de latence au
  /// premier appel. Appelé depuis `main.dart` après l'init Flutter.
  static Future<void> warmup() async {
    if (_initialized || kIsWeb) return;
    try {
      await _player.setSource(AssetSource('sounds/success.wav'));
      _initialized = true;
    } catch (e) {
      debugPrint('[SoundService] warmup échoué: $e');
    }
  }

  static Future<void> _play(String asset, {double volume = 0.6}) async {
    if (kIsWeb) return;
    try {
      await _player.stop();
      await _player.setVolume(volume);
      await _player.play(AssetSource('sounds/$asset'));
    } catch (e) {
      debugPrint('[SoundService] play "$asset" échoué: $e');
    }
  }

  /// Son de succès — joué après confirmation booking ou submit avis.
  /// Gated par `enabled` (toggle Settings → "Sons de l'interface").
  static Future<void> playSuccess({required bool enabled}) async {
    if (!enabled) return;
    await _play('success.wav', volume: 0.55);
  }

  /// Son d'erreur — buzz court, joué sur erreur formulaire critique.
  /// Gated par `enabled`.
  static Future<void> playError({required bool enabled}) async {
    if (!enabled) return;
    await _play('error.wav', volume: 0.5);
  }

  /// Son de notification reçue en foreground — joué TOUJOURS, indépendamment
  /// du toggle UI. Justification : sur mobile, l'OS supprime la bannière de
  /// notification quand l'app est ouverte ; sans son, l'utilisateur peut rater
  /// un walk-in ou un avis qui arrive pendant qu'il regarde une autre page.
  static Future<void> playNotif() async {
    await _play('notif.wav', volume: 0.7);
  }
}
