import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyCyRnf44MHppXvjvF2zg8SO4dBEG8qrwkk',
    appId: '1:70134830508:web:621e65bb99cccf96da5609',
    messagingSenderId: '70134830508',
    projectId: 'travel-wisata-lokal-18305',
    authDomain: 'travel-wisata-lokal-18305.firebaseapp.com',
    databaseURL: 'https://travel-wisata-lokal-18305.firebaseio.com',
    storageBucket: 'travel-wisata-lokal-18305.firebasestorage.app',
    measurementId: 'G-ABCDEFGHIJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCyRnf44MHppXvjvF2zg8SO4dBEG8qrwkk',
    appId: '1:70134830508:android:621e65bb99cccf96da5609',
    messagingSenderId: '70134830508',
    projectId: 'travel-wisata-lokal-18305',
    databaseURL: 'https://travel-wisata-lokal-18305.firebaseio.com',
    storageBucket: 'travel-wisata-lokal-18305.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCyRnf44MHppXvjvF2zg8SO4dBEG8qrwkk',
    appId: '1:70134830508:ios:621e65bb99cccf96da5609',
    messagingSenderId: '70134830508',
    projectId: 'travel-wisata-lokal-18305',
    databaseURL: 'https://travel-wisata-lokal-18305.firebaseio.com',
    storageBucket: 'travel-wisata-lokal-18305.firebasestorage.app',
    iosBundleId: 'com.example.travelWisataLokal',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCyRnf44MHppXvjvF2zg8SO4dBEG8qrwkk',
    appId: '1:70134830508:macos:621e65bb99cccf96da5609',
    messagingSenderId: '70134830508',
    projectId: 'travel-wisata-lokal-18305',
    databaseURL: 'https://travel-wisata-lokal-18305.firebaseio.com',
    storageBucket: 'travel-wisata-lokal-18305.firebasestorage.app',
    iosBundleId: 'com.example.travelWisataLokal',
  );
}
