// Config Firebase générée pour le projet `termini-im-cd5ff`.
//
// Sur **Android / iOS**, `Firebase.initializeApp()` sans options marche grâce
// au plugin `google-services` / `GoogleService-Info.plist`. Sur **Web** en
// revanche, `firebase_core_web` exige des options explicites — le fichier
// `web/index.html` a beau contenir `initializeApp(firebaseConfig)`, le binding
// Dart a son propre contexte et demande ses propres options.
//
// Pour éviter deux sources de vérité, on déclare la config ici et on la
// fournit conditionnellement à `Firebase.initializeApp` dans `main.dart` /
// `notification_service.dart` via `kIsWeb ? DefaultFirebaseOptions.web : null`.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCofTfimS6Rw1JPUTOuQYwlGYoYMpzox4k',
    appId: '1:759517993388:web:f57c6cd9ce6f7c688d8209',
    messagingSenderId: '759517993388',
    projectId: 'termini-im-cd5ff',
    authDomain: 'termini-im-cd5ff.firebaseapp.com',
    storageBucket: 'termini-im-cd5ff.firebasestorage.app',
    measurementId: 'G-BWV621VQYZ',
  );
}
