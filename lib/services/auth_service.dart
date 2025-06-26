import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserModel?> signUp(String name, String email, String password, String bloodGroup, String phoneNumber) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = userCredential.user;
    if (user != null) {
      // Save user to Firestore (to be implemented)
      return UserModel(
        id: user.uid,
        name: name,
        email: email,
        bloodGroup: bloodGroup,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
      );
    }
    return null;
  }

  Future<UserModel?> login(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = userCredential.user;
    if (user != null) {
      // Fetch user from Firestore (to be implemented)
      return UserModel(
        id: user.uid,
        name: '',
        email: email,
        bloodGroup: '',
        phoneNumber: '',
        createdAt: DateTime.now(),
      );
    }
    return null;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
