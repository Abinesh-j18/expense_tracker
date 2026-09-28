import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  static const String _accountsKey = 'local_user_accounts';
  static const String _sessionEmailKey = 'session_email';
  static const String _sessionNameKey = 'session_name';
  static const String _sessionUserIdKey = 'session_user_id';

  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  bool _isDemoAuthenticated = false;
  String _demoEmail = '';
  String _demoName = '';
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
  String get displayName {
    if (_user?.displayName != null && _user!.displayName!.isNotEmpty) {
      return _user!.displayName!;
    }
    if (_isDemoAuthenticated) {
      if (_demoName.isNotEmpty) return _demoName;
      if (_demoEmail.isNotEmpty && _demoEmail.contains('@')) {
        final prefix = _demoEmail.split('@').first;
        return prefix[0].toUpperCase() + prefix.substring(1);
      }
      return _demoEmail;
    }
    return 'Guest User';
  }

  void _init() {
    // If Firebase Auth is available, listen to changes
    _authSubscription = _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });

    // Check for saved local session
    _restoreLocalSession();
  }

  Future<void> _restoreLocalSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Ensure seed demo user exists
      await _ensureSeedAccount(prefs);

      // Restore active session if not using real Firebase
      if (!_authService.isFirebaseConfigured) {
        final savedEmail = prefs.getString(_sessionEmailKey);
        final savedName = prefs.getString(_sessionNameKey) ?? '';
        final savedUserId = prefs.getString(_sessionUserIdKey);

        if (savedEmail != null && savedUserId != null) {
          _demoEmail = savedEmail;
          _demoName = savedName;
          _demoUserId = savedUserId;
          _isDemoAuthenticated = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error restoring local session: $e');
    }
  }

  Future<void> _ensureSeedAccount(SharedPreferences prefs) async {
    final rawAccounts = prefs.getString(_accountsKey);
    Map<String, dynamic> accounts = {};
    if (rawAccounts != null) {
      try {
        accounts = jsonDecode(rawAccounts) as Map<String, dynamic>;
      } catch (_) {}
    }

    // Pre-seed demo account
    if (!accounts.containsKey('demo@example.com')) {
      accounts['demo@example.com'] = {
        'name': 'Demo User',
        'email': 'demo@example.com',
        'password': 'password123',
        'userId': 'demo_user_id',
        'createdAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_accountsKey, jsonEncode(accounts));
    }
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
        _demoName = 'Guest';
        _demoUserId = 'guest_user';
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_sessionEmailKey, _demoEmail);
        await prefs.setString(_sessionNameKey, _demoName);
        await prefs.setString(_sessionUserIdKey, _demoUserId);

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

    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    try {
      if (!_authService.isFirebaseConfigured) {
        await Future.delayed(const Duration(milliseconds: 350));
        final prefs = await SharedPreferences.getInstance();
        await _ensureSeedAccount(prefs);

        final rawAccounts = prefs.getString(_accountsKey);
        Map<String, dynamic> accounts = {};
        if (rawAccounts != null) {
          try {
            accounts = jsonDecode(rawAccounts) as Map<String, dynamic>;
          } catch (_) {}
        }

        if (!accounts.containsKey(cleanEmail)) {
          _isLoading = false;
          _errorMessage = 'No account found with $cleanEmail. Please create an account first.';
          notifyListeners();
          return false;
        }

        final userData = accounts[cleanEmail] as Map<String, dynamic>;
        if (userData['password'] != cleanPassword) {
          _isLoading = false;
          _errorMessage = 'Incorrect password. Please verify and try again.';
          notifyListeners();
          return false;
        }

        _isDemoAuthenticated = true;
        _demoEmail = cleanEmail;
        _demoName = (userData['name'] as String?) ?? '';
        _demoUserId = (userData['userId'] as String?) ?? 'user_${cleanEmail.hashCode.abs()}';

        await prefs.setString(_sessionEmailKey, _demoEmail);
        await prefs.setString(_sessionNameKey, _demoName);
        await prefs.setString(_sessionUserIdKey, _demoUserId);

        _isLoading = false;
        notifyListeners();
        return true;
      }

      await _authService.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
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

  Future<bool> registerWithEmail(
    String email,
    String password, {
    String? name,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    final cleanName = name?.trim() ?? '';

    try {
      if (!_authService.isFirebaseConfigured) {
        await Future.delayed(const Duration(milliseconds: 350));
        final prefs = await SharedPreferences.getInstance();
        await _ensureSeedAccount(prefs);

        final rawAccounts = prefs.getString(_accountsKey);
        Map<String, dynamic> accounts = {};
        if (rawAccounts != null) {
          try {
            accounts = jsonDecode(rawAccounts) as Map<String, dynamic>;
          } catch (_) {}
        }

        if (accounts.containsKey(cleanEmail)) {
          _isLoading = false;
          _errorMessage = 'An account with $cleanEmail already exists. Please sign in instead.';
          notifyListeners();
          return false;
        }

        final newUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        accounts[cleanEmail] = {
          'name': cleanName.isNotEmpty ? cleanName : cleanEmail.split('@').first,
          'email': cleanEmail,
          'password': cleanPassword,
          'userId': newUserId,
          'createdAt': DateTime.now().toIso8601String(),
        };

        await prefs.setString(_accountsKey, jsonEncode(accounts));

        _isDemoAuthenticated = true;
        _demoEmail = cleanEmail;
        _demoName = cleanName.isNotEmpty ? cleanName : cleanEmail.split('@').first;
        _demoUserId = newUserId;

        await prefs.setString(_sessionEmailKey, _demoEmail);
        await prefs.setString(_sessionNameKey, _demoName);
        await prefs.setString(_sessionUserIdKey, _demoUserId);

        _isLoading = false;
        notifyListeners();
        return true;
      }

      final cred = await _authService.registerWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      if (cleanName.isNotEmpty && cred?.user != null) {
        await cred!.user!.updateDisplayName(cleanName);
      }

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
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionEmailKey);
      await prefs.remove(_sessionNameKey);
      await prefs.remove(_sessionUserIdKey);

      _isDemoAuthenticated = false;
      _demoEmail = '';
      _demoName = '';
      _demoUserId = 'demo_user_id';
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
          return 'The password provided is too weak (minimum 6 characters).';
        case 'invalid-email':
          return 'The email address is invalid.';
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
