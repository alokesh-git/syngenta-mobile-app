// ⚠️ SETUP REQUIRED: Run `flutterfire configure` to generate this file.
// Install FlutterFire CLI: dart pub global activate flutterfire_cli
// Then run: flutterfire configure
//
// For the hackathon demo, Firebase features will show mock data if not configured.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCA-vyKOzFw8_MfxTA7fxCo-8n5BigaZd4',
    appId: '1:968331958656:android:e1a60d964e2d061a7f8965',
    messagingSenderId: '968331958656',
    projectId: 'local-farmers-20500',
    storageBucket: 'local-farmers-20500.firebasestorage.app',
  );

  // Replace with your actual Firebase config values

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBvAXSYfxgh3DQpeO9jeLrLrX-Jw4rquqE',
    appId: '1:968331958656:ios:afef5545f8cf5dc87f8965',
    messagingSenderId: '968331958656',
    projectId: 'local-farmers-20500',
    storageBucket: 'local-farmers-20500.firebasestorage.app',
    iosBundleId: 'syngenta.farmerconnect',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  );
}