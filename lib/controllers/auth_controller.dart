import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController({required AuthService authService}) : _authService = authService;

  final AuthService _authService;
  StreamSubscription<User?>? _subscription;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;
  bool get isFirebaseReady => _authService.isConfigured;

  void initialize() {
    _currentUser = _authService.currentUser;
    _subscription?.cancel();
    _subscription = _authService.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    return _runAuthAction(() async {
      await _authService.signIn(email: email.trim(), password: password.trim());
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    return _runAuthAction(() async {
      await _authService.signUp(email: email.trim(), password: password.trim());
    });
  }

  Future<void> signOut() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.signOut();
    } catch (error) {
      _errorMessage = _normalizeError(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await action();
      return true;
    } catch (error) {
      _errorMessage = _normalizeError(error);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String _normalizeError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'E-mail inválido.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Credenciais inválidas.';
        case 'email-already-in-use':
          return 'Este e-mail já está em uso.';
        case 'weak-password':
          return 'A senha precisa ter pelo menos 6 caracteres.';
        default:
          return error.message ?? 'Falha na autenticação.';
      }
    }

    return error.toString();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
