import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({required bool firebaseEnabled}) : _firebaseEnabled = firebaseEnabled;

  final bool _firebaseEnabled;

  bool get isConfigured => _firebaseEnabled;

  User? get currentUser => _firebaseEnabled ? FirebaseAuth.instance.currentUser : null;

  Stream<User?> get authStateChanges {
    if (!_firebaseEnabled) {
      return Stream<User?>.value(null);
    }

    return FirebaseAuth.instance.authStateChanges();
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    _ensureFirebaseConfigured();
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    _ensureFirebaseConfigured();
    return FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    if (!_firebaseEnabled) {
      return;
    }

    await FirebaseAuth.instance.signOut();
  }

  void _ensureFirebaseConfigured() {
    if (_firebaseEnabled) {
      return;
    }

    throw const FirebaseSetupException(
      'O serviço de autenticação não está disponível no ambiente atual.'
    );
  }
}

class FirebaseSetupException implements Exception {
  const FirebaseSetupException(this.message);

  final String message;

  @override
  String toString() => message;
}
