import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blood_request.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addBloodRequest(BloodRequest request) async {
    await _db.collection('blood_requests').doc(request.id).set(request.toJson());
  }

  Stream<List<BloodRequest>> getActiveRequests() {
    return _db.collection('blood_requests')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => BloodRequest.fromJson(doc.data())).toList());
  }

  Future<void> acceptRequest(String requestId, String userId) async {
    await _db.collection('blood_requests').doc(requestId).update({'isActive': false, 'acceptedBy': userId});
  }
}
