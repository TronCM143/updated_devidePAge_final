// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAWq5lg3Ds8pNX4sVbFx16bKg-d_nJCe0U',
    appId: '1:797058645482:web:c43a1f59a59727c05a0693',
    messagingSenderId: '797058645482',
    projectId: 'real-final-project-3234e',
    authDomain: 'real-final-project-3234e.firebaseapp.com',
    storageBucket: 'real-final-project-3234e.appspot.com',
    measurementId: 'G-6P7TD7LLM8',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDYEAj349WXVjLarCqRKlnhS5YlQazroLQ',
    appId: '1:797058645482:android:9b0d5e1490be6c6c5a0693',
    messagingSenderId: '797058645482',
    projectId: 'real-final-project-3234e',
    storageBucket: 'real-final-project-3234e.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDO72yXtyQh03IzK0pzTcmtWl3HeYXUX9k',
    appId: '1:797058645482:ios:e5848c44e0f50fc65a0693',
    messagingSenderId: '797058645482',
    projectId: 'real-final-project-3234e',
    storageBucket: 'real-final-project-3234e.appspot.com',
    iosBundleId: 'com.example.trial',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDO72yXtyQh03IzK0pzTcmtWl3HeYXUX9k',
    appId: '1:797058645482:ios:e5848c44e0f50fc65a0693',
    messagingSenderId: '797058645482',
    projectId: 'real-final-project-3234e',
    storageBucket: 'real-final-project-3234e.appspot.com',
    iosBundleId: 'com.example.trial',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAWq5lg3Ds8pNX4sVbFx16bKg-d_nJCe0U',
    appId: '1:797058645482:web:feb1990069aafb4b5a0693',
    messagingSenderId: '797058645482',
    projectId: 'real-final-project-3234e',
    authDomain: 'real-final-project-3234e.firebaseapp.com',
    storageBucket: 'real-final-project-3234e.appspot.com',
    measurementId: 'G-90C1T6CFH2',
  );
}
