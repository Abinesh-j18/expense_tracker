import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  bool _isDemoAuthenticated = false;
  String _demoEmail = '';
  String _demoUserId = 'demo_user_id';
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({required AuthService authService}) : _authService = authService {
    _init();
  }

  User? get user => _user;
  bool get isAuthenticated => (_user != null) || _isDemoAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get userId => _user?.uid ?? (_isDemoAuthenticated ? _demoUserId : 'guest_user');
  String get displayEmail => _user?.email ?? (_isDemoAuthenticated ? _demoEmail : 'Guest User');

  void _init() {
    _authSubscription = _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signInAnonymously() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_authService.isFirebaseConfigured) {
        await Future.delayed(const Duration(milliseconds: 300));
        _isDemoAuthenticated = true;
        _demoEmail = 'Guest User';
        _demoUserId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
        _isLoading = false;
        notifyListeners();
        return true;
      }
      await _authService.signInAnonymously();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_authService.isFirebaseConfigured) {
        await Future.delayed(const Duration(milliseconds: 400));
        _isDemoAuthenticated = true;
        _demoEmail = email;
        _demoUserId = 'user_${email.hashCode.abs()}';
        _isLoading = false;
        notifyListeners();
        return true;
      }
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _cleanErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_authService.isFirebaseConfigured) {
        await Future.delayed(const Duration(milliseconds: 400));
        _isDemoAuthenticated = true;
        _demoEmail = email;
        _demoUserId = 'user_${email.hashCode.abs()}';
        _isLoading = false;
        notifyListeners();
        return true;
      }
      await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _cleanErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_authService.isFirebaseConfigured) {
        await _authService.signOut();
      }
      _isDemoAuthenticated = false;
      _user = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _cleanErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'The account already exists for that email.';
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'invalid-email':
          return 'The email address is badly formatted.';
        default:
          return error.message ?? 'Authentication error occurred.';
      }
    }
    return error.toString();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
