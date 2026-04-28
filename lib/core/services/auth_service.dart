import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

  /// Check if email already exists in Firebase Auth
  /// Returns true if email is already registered, false otherwise
  ///
  /// Uses MULTI-APPROACH for reliability:
  /// 1. Try fetchSignInMethodsForEmail first
  /// 2. If that returns empty with valid email format, also try signInWithEmailAndPassword
  ///    to definitively check if account exists
  Future<bool> checkEmailExists(String email) async {
    try {
      final trimmedEmail = email.trim();
      
      // Invalid email format = treat as not exists (form validation should catch this)
      if (!_isValidEmailFormat(trimmedEmail)) {
        debugPrint('[AuthService] Invalid email format, returning false');
        return false;
      }
      
      debugPrint('[AuthService] checkEmailExists called with: $trimmedEmail');
      
      // APPROACH 1: fetchSignInMethodsForEmail
      // This is the "correct" API but has edge cases
      try {
        final methods = await _auth.fetchSignInMethodsForEmail(trimmedEmail);
        debugPrint('[AuthService] Approach 1 - fetchSignInMethodsForEmail: ${methods.length} methods');
        
        // If we have sign-in methods, email definitely exists
        if (methods.isNotEmpty) {
          debugPrint('[AuthService] Email exists (has sign-in methods)');
          return true;
        }
      } catch (e) {
        debugPrint('[AuthService] Approach 1 failed: $e');
      }
      
      // APPROACH 2: Try to sign in with wrong password
      // This is DEFINITIVE - if account exists, we get wrong-password error
      // If account doesn't exist, we get user-not-found error
      debugPrint('[AuthService] Trying Approach 2 - signInWithEmailAndPassword');
      try {
        await _auth.signInWithEmailAndPassword(
          email: trimmedEmail,
          password: '__DUMMY_PASSWORD_TO_CHECK_EMAIL_EXISTS__',
        );
        // If we reach here, email exists (very unlikely with wrong password)
        debugPrint('[AuthService] Approach 2 - unexpected success, email exists');
        return true;
      } on FirebaseAuthException catch (e) {
        debugPrint('[AuthService] Approach 2 exception: ${e.code}');
        
        // "email/password" credential exists but wrong password = EMAIL EXISTS
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          debugPrint('[AuthService] Email exists (wrong password)');
          return true;
        }
        
        // "user-not-found" = EMAIL DOES NOT EXIST
        if (e.code == 'user-not-found') {
          debugPrint('[AuthService] Email does not exist (user-not-found)');
          return false;
        }
        
        // Other error: for safety, assume email might exist
        debugPrint('[AuthService] Unknown error, being cautious: assume exists');
        return true;
      }
    } catch (e) {
      debugPrint('[AuthService] checkEmailExists completely failed: $e');
      // On complete failure, return true to be safe (block registration)
      // This forces user to check manually via login
      return true;
    }
  }
  
  /// Helper to validate email format
  bool _isValidEmailFormat(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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
