import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth? _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth;

  // Stream of auth state changes
  Stream<User?> get authStateChanges {
    if (_auth == null) {
      return Stream.value(null);
    }
    return _auth.authStateChanges();
  }

  // Get current user
  User? get currentUser => _auth?.currentUser;

  // Get current User ID (or mock id if offline/demo)
  String get currentUserId => _auth?.currentUser?.uid ?? 'demo_user_id';

  // Sign in anonymously (One-click Guest Mode)
  Future<UserCredential?> signInAnonymously() async {
    try {
      if (_auth == null) return null;
      return await _auth.signInAnonymously();
    } catch (e) {
      debugPrint('AuthService.signInAnonymously error: $e');
      rethrow;
    }
  }

  // Sign in with Email and Password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (_auth == null) return null;
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint('AuthService.signInWithEmailAndPassword error: $e');
      rethrow;
    }
  }

  // Register with Email and Password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (_auth == null) return null;
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint('AuthService.registerWithEmailAndPassword error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('AuthService.signOut error: $e');
      rethrow;
    }
  }
}
