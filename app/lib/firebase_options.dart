// Placeholder Firebase options for compile-time; replace with flutterfire configure output.
// TODO: run `flutterfire configure` and regenerate this file with real values.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC4csH-LBRiikaAMyD5EQewcINLVrmXQbs',
    appId: '1:97120825720:web:71fa701dd5d4561f8bd88d',
    messagingSenderId: '97120825720',
    projectId: 'studio-3328096157-e3f79',
    authDomain: 'studio-3328096157-e3f79.firebaseapp.com',
    storageBucket: 'studio-3328096157-e3f79.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCM26X4EXiP3c4uqmLiF1yqXSnRlnWRePY',
    appId: '1:97120825720:android:da981368d25ebd338bd88d',
    messagingSenderId: '97120825720',
    projectId: 'studio-3328096157-e3f79',
    storageBucket: 'studio-3328096157-e3f79.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDPClAxcvuy3hddlXjwgTGxXpL7YJOMqVM',
    appId: '1:97120825720:ios:8bf1aacba9762af78bd88d',
    messagingSenderId: '97120825720',
    projectId: 'studio-3328096157-e3f79',
    storageBucket: 'studio-3328096157-e3f79.firebasestorage.app',
    iosBundleId: 'com.scholesa.app',
  );

}