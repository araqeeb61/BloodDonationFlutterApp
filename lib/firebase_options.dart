// Replace the values below with your actual Firebase web config from the Firebase Console
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyDlBZ9Cz6PT41JaWakXrOId3j8rkDOvFkc',
        authDomain: 'YOUR_AUTH_DOMAIN',
        projectId: 'bloodbank-a3a5e',
        storageBucket: 'bloodbank-a3a5e.firebasestorage.app',
        messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
        appId: '1:150343034056:android:d4b69f332e4aae11df31fd',
        measurementId: 'YOUR_MEASUREMENT_ID',
      );
    }
    // For mobile, you can leave this empty if using google-services.json and GoogleService-Info.plist
    throw UnsupportedError('DefaultFirebaseOptions are not set for this platform.');
  }
}
