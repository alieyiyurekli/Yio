import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';

/// Firebase Authentication Service
///
/// Handles all Firebase Auth operations including:
/// - Email/Password registration and login
/// - Password reset
/// - Session management
/// - User-friendly error handling
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Current user ID or null
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Get current user ID or throw exception
  String get requireUserId {
    final uid = currentUserId;
    if (uid == null) {
      throw Exception(AppConstants.errorNotAuthenticated);
    }
    return uid;
  }

  /// Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Register with email and password
  ///
  /// Creates a new user account and sends email verification.
  /// Throws user-friendly error messages.
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw Exception(AppConstants.errorRegisterFailed);
      }

      // Update display name in Firebase Auth
      await credential.user!.updateDisplayName(displayName.trim());

      // Send email verification
      await credential.user!.sendEmailVerification();

      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw Exception(AppConstants.errorSignInFailed);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Çıkış yapılamadı: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  /// Send email verification to current user
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(AppConstants.errorNotAuthenticated);
    }
    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Reload current user data from Firebase
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Update user display name in Firebase Auth
  Future<void> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName.trim());
    } catch (e) {
      throw Exception('Ad güncellenemedi: ${e.toString()}');
    }
  }

  /// Update user photo URL in Firebase Auth
  Future<void> updatePhotoUrl(String photoUrl) async {
    try {
      await _auth.currentUser?.updatePhotoURL(photoUrl.trim());
    } catch (e) {
      throw Exception('Fotoğraf güncellenemedi: ${e.toString()}');
    }
  }

  /// Update user email in Firebase Auth (requires re-authentication)
  Future<void> updateUserEmail(String newEmail) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail.trim());
    } catch (e) {
      throw Exception('E-posta güncellenemedi: ${e.toString()}');
    }
  }

  /// Update user password (requires re-authentication)
  Future<void> updateUserPassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Şifre güncellenemedi: ${e.toString()}');
    }
  }

  /// Delete user account (requires re-authentication)
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      throw Exception('Hesap silinirken hata: ${e.toString()}');
    }
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AppConstants.errorUserNotFound;
      case 'wrong-password':
        return AppConstants.errorWrongPassword;
      case 'email-already-in-use':
        return AppConstants.errorEmailInUse;
      case 'invalid-email':
        return AppConstants.errorInvalidEmail;
      case 'weak-password':
        return AppConstants.errorWeakPassword;
      case 'user-disabled':
        return AppConstants.errorUserDisabled;
      case 'too-many-requests':
        return AppConstants.errorTooManyRequests;
      case 'operation-not-allowed':
        return AppConstants.errorOperationNotAllowed;
      case 'network-request-failed':
        return AppConstants.errorNetworkFailed;
      default:
        return '${AppConstants.errorGeneric} (${e.code})';
    }
  }
}
