import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Firebase project "lernbik". These values are public identifiers, not secrets.
FirebaseOptions get firebaseOptions => kIsWeb ? _web : _android;

const _web = FirebaseOptions(
  apiKey: 'AIzaSyD7WoWLVItq8IPPmpiIDps3Qrb68vqE-Dw',
  authDomain: 'lernbik.firebaseapp.com',
  projectId: 'lernbik',
  storageBucket: 'lernbik.firebasestorage.app',
  messagingSenderId: '479974594776',
  appId: '1:479974594776:web:3bd2945763f650c247dfad',
);

const _android = FirebaseOptions(
  apiKey: 'AIzaSyCbwV_W5h5JTk28Td-FygpGAW2j9xPxfOw',
  projectId: 'lernbik',
  storageBucket: 'lernbik.firebasestorage.app',
  messagingSenderId: '479974594776',
  appId: '1:479974594776:android:794d766a475a89f647dfad',
);

// Public site (Firebase Hosting) and the APK on GitHub Releases.
const siteUrl = String.fromEnvironment('SITE', defaultValue: 'https://lernbik.web.app');
// Local testing with the Firestore emulator: flutter run --dart-define=EMU=true
const useEmulator = bool.fromEnvironment('EMU');
const apkUrl = 'https://github.com/Laserbiklb/lernbik/releases/latest/download/lernbik.apk';
// Web push key (Firebase console → Cloud Messaging → Web Push certificates).
const vapidKey = 'BNWaQtaBmT1sszipooawTaFSLtC4WDGfW5o75Ya3E3QM9oPrYzVGvYueEnEzH01FVbST4I0F1GRuEX21FfvEs0U';
