import 'package:crisis_bridge/models/responder.dart';
import 'package:crisis_bridge/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _fs = FirestoreService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register({
    required String email,
    required String password,
    required String displayName,
    required String propertyId,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(displayName);

    final responder = Responder(
      uid: cred.user!.uid,
      email: email,
      displayName: displayName,
      role: 'staff',
      propertyId: propertyId,
      createdAt: DateTime.now(),
    );
    await _fs.saveResponder(responder);
    return cred;
  }

  Future<void> signOut() => _auth.signOut();
}