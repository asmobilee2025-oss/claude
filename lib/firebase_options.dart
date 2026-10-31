// PLACEHOLDER — replace by running:  flutterfire configure
//
// These "demo-" values let the app run fully against the local Firebase
// Emulator Suite (flutter run --dart-define=USE_EMULATOR=true) without a real
// Firebase project. They are NOT secrets; Firebase client config is public by
// design and access is controlled by firestore.rules / storage.rules.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const web = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-souqna',
    authDomain: 'demo-souqna.firebaseapp.com',
    storageBucket: 'demo-souqna.appspot.com',
  );

  static const android = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-souqna',
    storageBucket: 'demo-souqna.appspot.com',
  );

  static const ios = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-souqna',
    storageBucket: 'demo-souqna.appspot.com',
    iosBundleId: 'com.souqna.souqna',
  );
}
