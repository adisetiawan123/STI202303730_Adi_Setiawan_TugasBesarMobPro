// Contoh Firebase Configuration untuk Production
// Ganti dengan kredensial Firebase Anda yang sebenarnya

class FirebaseConfig {
  // Project ID
  static const String projectId = 'travel-wisata-lokal';

  // Android Configuration
  static const String androidApiKey = 'YOUR_ANDROID_API_KEY';
  static const String androidClientId =
      'YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com';

  // iOS Configuration
  static const String iosApiKey = 'YOUR_IOS_API_KEY';
  static const String iosBundleId = 'com.example.travel_wisata_lokal';

  // Google Sign In Configuration
  static const String googleWebClientId =
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

  // Facebook Configuration
  static const String facebookAppId = 'YOUR_FACEBOOK_APP_ID';
  static const String facebookClientToken = 'YOUR_FACEBOOK_CLIENT_TOKEN';
}

// Cara setup:
// 1. Buat Firebase project di https://console.firebase.google.com
// 2. Setup Google Sign In di Firebase Console
// 3. Setup Facebook Login di Facebook Developers
// 4. Replace konstanta di atas dengan kredensial sebenarnya
// 5. Update google-services.json (Android) dan GoogleService-Info.plist (iOS)
