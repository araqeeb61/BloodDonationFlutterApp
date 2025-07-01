import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;

  final hospitals = [
    {
      'name': 'City Hospital',
      'latitude': 28.6139,
      'longitude': 77.2090,
      'address': 'Connaught Place, New Delhi',
    },
    {
      'name': 'General Hospital',
      'latitude': 28.7041,
      'longitude': 77.1025,
      'address': 'Karol Bagh, New Delhi',
    },
    {
      'name': 'Red Cross',
      'latitude': 28.5355,
      'longitude': 77.3910,
      'address': 'Sector 18, Noida',
    },
    {
      'name': 'Community Clinic',
      'latitude': 28.4595,
      'longitude': 77.0266,
      'address': 'DLF Phase 3, Gurugram',
    },
  ];

  for (final hospital in hospitals) {
    await firestore.collection('hospitals').doc(hospital['name'] as String).set({
      'latitude': hospital['latitude'],
      'longitude': hospital['longitude'],
      'address': hospital['address'],
    });
    print('Added: ${hospital['name']}');
  }
  print('All dummy hospitals added.');
}
