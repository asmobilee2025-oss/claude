import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/providers.dart';

/// `flutter run --dart-define=USE_EMULATOR=true` runs against the local emulators.
const _useEmulator = bool.fromEnvironment('USE_EMULATOR');
const _emulatorHost = String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // clean URLs on web: /listing/abc instead of /#/listing/abc
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (_useEmulator) {
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android && _emulatorHost == 'localhost'
        ? '10.0.2.2'
        : _emulatorHost;
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  }

  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    retry: _retry,
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: const SouqnaApp(),
  ));
}

/// Never retry security / not-found errors (they won't fix themselves and would
/// leave the UI loading forever); retry transient errors a few times.
Duration? _retry(int count, Object error) {
  if (error is FirebaseException &&
      const {'permission-denied', 'not-found', 'unauthenticated', 'invalid-argument', 'failed-precondition'}.contains(error.code)) {
    return null;
  }
  if (count >= 3) return null;
  return Duration(milliseconds: 400 * (1 << count));
}
