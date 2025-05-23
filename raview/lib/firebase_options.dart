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
    apiKey: 'AIzaSyDw2p_ORiuxeBZguQYI0whqWOfqq5oypjY',
    appId: '1:381993077269:web:073e80fec077ae5fad5c1c',
    messagingSenderId: '381993077269',
    projectId: 'notes-3b779',
    authDomain: 'notes-3b779.firebaseapp.com',
    storageBucket: 'notes-3b779.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDDQzF-ulEfSZfkkGAL43YunH0WKZjLq0k',
    appId: '1:381993077269:android:8d1eb85d14721940ad5c1c',
    messagingSenderId: '381993077269',
    projectId: 'notes-3b779',
    storageBucket: 'notes-3b779.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCojooF3xRQxYLmce4vwS5Dn7Ntq6b5-70',
    appId: '1:381993077269:ios:82201ec7f077a841ad5c1c',
    messagingSenderId: '381993077269',
    projectId: 'notes-3b779',
    storageBucket: 'notes-3b779.appspot.com',
    iosBundleId: 'com.example.raview',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCojooF3xRQxYLmce4vwS5Dn7Ntq6b5-70',
    appId: '1:381993077269:ios:82201ec7f077a841ad5c1c',
    messagingSenderId: '381993077269',
    projectId: 'notes-3b779',
    storageBucket: 'notes-3b779.appspot.com',
    iosBundleId: 'com.example.raview',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB4J4qIQHX4LtSZd6bVCju1tm-mfwvPVH8',
    appId: '1:381993077269:web:f4335c5d57113004ad5c1c',
    messagingSenderId: '381993077269',
    projectId: 'notes-3b779',
    authDomain: 'notes-3b779.firebaseapp.com',
    storageBucket: 'notes-3b779.appspot.com',
  );
}
