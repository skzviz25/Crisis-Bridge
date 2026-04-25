import 'package:crisis_bridge/models/responder.dart';
import 'package:crisis_bridge/services/auth_service.dart';
import 'package:crisis_bridge/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _fs = FirestoreService();

  User? _user;
  Responder? _responder;
  String? _error;
  bool _loading = false;

  User? get user => _user;
  Responder? get responder => _responder;
  String? get error => _error;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    _user = user;
    if (user != null) {
      _responder = await _fs.getResponder(user.uid);
    } else {
      _responder = null;
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.signIn(email, password);
      _loading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    required String propertyId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
        propertyId: propertyId,
      );
      _loading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}