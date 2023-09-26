// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyDbTGj7w-PZQI0__CM36cfXBy5ioimSjQE',
    appId: '1:658973573585:web:cf34b67eee9f9a2e9920f0',
    messagingSenderId: '658973573585',
    projectId: 'prescore-a782f',
    authDomain: 'prescore-a782f.firebaseapp.com',
    storageBucket: 'prescore-a782f.appspot.com',
    measurementId: 'G-DGLEXX535T',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCDoFq7Yk7IznP4TP62D5Uq4W4BjxReyIA',
    appId: '1:658973573585:android:f1e9b650962f627c9920f0',
    messagingSenderId: '658973573585',
    projectId: 'prescore-a782f',
    storageBucket: 'prescore-a782f.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDB2wcVFf-tM6dgsiQrmxQrhjeWbVdftes',
    appId: '1:658973573585:ios:32a5e1a698d3f6259920f0',
    messagingSenderId: '658973573585',
    projectId: 'prescore-a782f',
    storageBucket: 'prescore-a782f.appspot.com',
    iosBundleId: 'com.bjbybbs.prescoreFlutter',
  );
}
