import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((AuthState data) {
      if (data.session != null) {
        _loadUserProfile();
      } else {
        _status = AuthStatus.unauthenticated;
        _user = null;
        notifyListeners();
      }
    });

    // Check initial auth state
    if (_authService.isAuthenticated) {
      _loadUserProfile();
    } else {
      _status = AuthStatus.unauthenticated;
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      _user = await _authService.getUserProfile();
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.user != null) {
        await _loadUserProfile();
        return true;
      }
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile();
        return true;
      }
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final success = await _authService.signInWithGoogle();

      if (success) {
        await _loadUserProfile();
        return true;
      }
      _status = AuthStatus.unauthenticated;
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _status = AuthStatus.unauthenticated;
      _user = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
    }
  }

  Future<bool> checkEmailVerification() async {
    try {
      final isVerified = await _authService.isEmailVerified();
      if (isVerified) {
        await _loadUserProfile();
      }
      return isVerified;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    try {
      _errorMessage = null;
      await _authService.resendVerificationEmail();
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _errorMessage = null;
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  String _parseError(dynamic error) {
    if (error is AuthException) {
      return error.message;
    }
    return error.toString();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
