import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Firebase Authentication Service
/// 
/// Handles all authentication operations including:
/// - Email/Password registration and login
/// - Google Sign-In (ready to implement)
/// - Password reset
/// - Email verification
/// - User session management
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Current user
  User? get currentUser => _auth.currentUser;
  
  /// Current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Get current user ID or throw exception
  String get requireUserId {
    final uid = currentUserId;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    return uid;
  }

  /// Stream of user model with auth state changes
  /// This combines Firebase Auth user with Firestore user data
  Stream<User?> get userStream => _auth.authStateChanges();

  /// Get current Firebase Auth user
  User? get currentFirebaseUser => _auth.currentUser;

  /// Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Register with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create user with email and password
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      // Send email verification
      await credential.user?.sendEmailVerification();

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in anonymously (for testing)
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Reload user data
  Future<void> reload() async {
    await _auth.currentUser?.reload();
  }

  /// Update user display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
    } catch (e) {
      throw Exception('Failed to update display name: ${e.toString()}');
    }
  }

  /// Update user photo URL
  Future<void> updatePhotoUrl(String photoUrl) async {
    try {
      await _auth.currentUser?.updatePhotoURL(photoUrl);
    } catch (e) {
      throw Exception('Failed to update photo URL: ${e.toString()}');
    }
  }

  /// Update user email
  Future<void> updateUserEmail(String email) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(email);
    } catch (e) {
      throw Exception('Failed to update email: ${e.toString()}');
    }
  }

  /// Update user password
  Future<void> updateUserPassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Failed to update password: ${e.toString()}');
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Kullanıcı bulunamadı. Lütfen kayıt olun.';
      case 'wrong-password':
        return 'Hatalı şifre. Lütfen tekrar deneyin.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda允许 değil.';
      case 'network-request-failed':
        return 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }

  /// Convert Firebase User to UserModel
  /// Note: This only creates a basic UserModel from Auth data
  /// For full user data, fetch from Firestore
  UserModel firebaseUserToModel(User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
    );
  }
}
