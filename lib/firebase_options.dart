import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// ============================================================
// firebase_options.dart
// Auto-generated configuration for Firebase project:
//   test-admin-database
// ============================================================

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS is not configured for this project.');
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS is not configured for this project.');
      case TargetPlatform.windows:
        throw UnsupportedError('Windows is not configured for this project.');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux is not configured for this project.');
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  // ── Web ───────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCSZweLOLxBL0YdDs0GavJZ_qafRIanrWY',
    appId: '1:423048407162:web:e34982aaadfe5798aff3c3',
    messagingSenderId: '423048407162',
    projectId: 'test-admin-database',
    authDomain: 'test-admin-database.firebaseapp.com',
    databaseURL: 'https://test-admin-database-default-rtdb.firebaseio.com',
    storageBucket: 'test-admin-database.firebasestorage.app',
  );

  // ── Android ───────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCiLz3fjBqptq4189BNBki6TJaNeW5Ntgk',
    appId: '1:423048407162:android:4f08b0b553af1eecaff3c3',
    messagingSenderId: '423048407162',
    projectId: 'test-admin-database',
    databaseURL: 'https://test-admin-database-default-rtdb.firebaseio.com',
    storageBucket: 'test-admin-database.firebasestorage.app',
  );
}
