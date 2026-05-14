import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class AppFirebaseOptions {
  static const bool isConfigured = true;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web não suportado.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Plataforma não suportada no momento.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDD09QA0x33xOf5MgpG8rFd9G6aI_HUMGo',
    appId: '1:466401664877:android:4ad414701c57da3f5c4464',
    messagingSenderId: '466401664877',
    projectId: 'mob2-relogio-do-apocalipse',
    storageBucket: 'mob2-relogio-do-apocalipse.firebasestorage.app',
  );
}
