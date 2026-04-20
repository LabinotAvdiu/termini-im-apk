/// Interface sounds — off par défaut.
///
/// Nécessite le package audioplayers ^6.0.0 et les assets suivants :
///   assets/sounds/success.wav
///   assets/sounds/error.wav
///   assets/sounds/tap.wav
///
/// TODO: Ajouter les fichiers WAV dans assets/sounds/ et déclarer le
/// répertoire dans pubspec.yaml :
///   assets:
///     - assets/sounds/
///
/// TODO: Ajouter audioplayers: ^6.0.0 dans pubspec.yaml dependencies.
///
/// En attendant les assets, les appels à play() échouent silencieusement
/// et n'impactent pas l'UX.
library;

// ignore: depend_on_referenced_packages
// import 'package:audioplayers/audioplayers.dart';

/// Service de sons d'interface.
///
/// Toutes les méthodes sont des no-op si les sons sont désactivés dans
/// [UxPrefsState.soundsEnabled]. Respecte aussi
/// [MediaQueryData.disableAnimations] (qui couvre la réduction des effets
/// sensoriels sur iOS/Android).
class SoundService {
  SoundService._();

  // static final AudioPlayer _player = AudioPlayer();

  /// Son de succès — ding court, joué après confirmation booking.
  static Future<void> playSuccess({bool enabled = false}) async {
    if (!enabled) return;
    // TODO: décommenter une fois audioplayers ajouté + assets présents.
    // await _player.play(AssetSource('sounds/success.wav'));
  }

  /// Son d'erreur — buzz court, joué sur erreur formulaire.
  static Future<void> playError({bool enabled = false}) async {
    if (!enabled) return;
    // await _player.play(AssetSource('sounds/error.wav'));
  }

  /// Son de tap subtil — désactivé par défaut même si sounds=true.
  static Future<void> playTap({bool enabled = false}) async {
    if (!enabled) return;
    // await _player.play(AssetSource('sounds/tap.wav'));
  }
}
