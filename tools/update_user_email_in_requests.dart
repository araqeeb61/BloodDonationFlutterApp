// Dart script to update old Firestore blood_requests with missing userEmail field
// Run this in a Dart environment with Firebase Admin SDK configured
import 'package:firebase_admin/firebase_admin.dart';
import 'package:firebase_admin/src/credential.dart';

Future<void> main() async {
  final app = FirebaseAdmin.instance.initializeApp(
    AppOptions(credential: ServiceAccountCredential.fromPath('path/to/serviceAccountKey.json')),
  );
  final firestore = app.firestore();

  // Replace with your userId and userEmail
  const userId = 'YOUR_USER_ID';
  const userEmail = 'YOUR_EMAIL@example.com';

  final query = await firestore.collection('blood_requests').where('userId', isEqualTo: userId).get();
  for (final doc in query.docs) {
    final data = doc.data();
    if (data['userEmail'] == null || data['userEmail'] == '') {
      await doc.reference.update({'userEmail': userEmail});
      print('Updated request ${doc.id} with userEmail $userEmail');
    }
  }
  print('Done updating requests.');
}
