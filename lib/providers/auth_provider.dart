import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_user_service.dart';

/// Authentication Provider
///
/// Manages authentication state and user data
/// Combines Firebase Auth with Firestore user data
class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();

  // State variables
  User? _firebaseUser;
  UserModel? _userModel;
  FirestoreUserService? _userService;
  bool _isInitializing = true; // Only true during app startup auth check
  bool _isAuthenticating = false; // True during login/register operations
  String? _errorMessage;

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _userModel;
  bool get isLoggedIn => _firebaseUser != null;
  // isInitializing — splash screen için
  bool get isInitializing => _isInitializing;
  // isLoading — butonları deaktif etmek için
  bool get isLoading => _isInitializing || _isAuthenticating;
  bool get isAuthenticating => _isAuthenticating;
  String? get errorMessage => _errorMessage;
  FirestoreUserService? get userService => _userService;

  /// Initialize auth provider — sets up authStateChanges stream listener
  void initialize() {
    _authService.authStateChanges.listen((user) async {
      _firebaseUser = user;
      
      if (user != null) {
        _userService = FirestoreUserService(userId: user.uid);
        try {
          _userModel = await _userService!.getCurrentUser();
        } catch (e) {
          debugPrint('[AuthProvider] Firestore fetch error: $e');
          _userModel = null;
        }
        _userModel ??= UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoUrl: user.photoURL,
        );
      } else {
        _userModel = null;
        _userService = null;
      }
      
      _isInitializing = false;
      notifyListeners();
    }, onError: (error) {
      debugPrint('[AuthProvider] authStateChanges error: $error');
      _isInitializing = false;
      notifyListeners();
    });
  }

  /// Register with email and password — production-ready with try/catch/finally
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isAuthenticating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (credential.user == null) {
        _errorMessage = 'Kayıt işlemi başarısız: Kullanıcı oluşturulamadı.';
        return false;
      }

      // Try to create Firestore user doc — failure must NOT block auth
      try {
        final userService = FirestoreUserService(userId: credential.user!.uid);
        final userModel = UserModel(
          id: credential.user!.uid,
          email: email,
          displayName: displayName,
        );
        await userService.createUser(userModel);
        debugPrint('[AuthProvider] Firestore user doc created for ${credential.user!.uid}');
      } catch (firestoreError) {
        // Firestore hatası register'ı engellemez, sadece loglanır
        debugPrint('[AuthProvider] Firestore user doc creation failed (non-fatal): $firestoreError');
        _errorMessage = null; // clear any stale error
      }

      // authStateChanges listener will fire and update _firebaseUser + _userModel
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[AuthProvider] Register error: $e');
      return false;
    } finally {
      // always clear authenticating flag
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password — production-ready with try/catch/finally
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isAuthenticating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        _errorMessage = 'Giriş başarısız: Kullanıcı bilgileri alınamadı.';
        return false;
      }

      // authStateChanges listener will update _firebaseUser + _userModel automatically
      debugPrint('[AuthProvider] Sign in successful for ${credential.user!.uid}');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[AuthProvider] Sign in error: $e');
      return false;
    } finally {
      // always clear authenticating flag
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Sign in anonymously (for testing)
  Future<bool> signInAnonymously() async {
    _isAuthenticating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signInAnonymously();
      if (credential.user != null) {
        _firebaseUser = credential.user;
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isAuthenticating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signOut();
      _firebaseUser = null;
      _userModel = null;
      _userService = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _isAuthenticating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
    String? bio,
  }) async {
    if (_userService == null || _userModel == null) {
      _errorMessage = 'User not logged in';
      return false;
    }

    _isAuthenticating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var updatedUser = _userModel!;

      if (displayName != null && displayName.isNotEmpty) {
        await _authService.updateDisplayName(displayName);
        updatedUser = updatedUser.copyWith(displayName: displayName);
      }

      if (photoUrl != null && photoUrl.isNotEmpty) {
        await _authService.updatePhotoUrl(photoUrl);
        updatedUser = updatedUser.copyWith(photoUrl: photoUrl);
      }

      if (bio != null) {
        updatedUser = updatedUser.copyWith(bio: bio);
      }

      final success = await _userService!.updateUser(updatedUser);
      if (success) {
        _userModel = updatedUser;
      }

      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    if (_userService == null) {
      _errorMessage = 'User not logged in';
      return false;
    }

    _isAuthenticating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final firestoreSuccess = await _userService!.deleteUser();
      if (!firestoreSuccess) {
        throw Exception('Failed to delete user from Firestore');
      }

      await _authService.deleteAccount();

      _firebaseUser = null;
      _userModel = null;
      _userService = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

}
