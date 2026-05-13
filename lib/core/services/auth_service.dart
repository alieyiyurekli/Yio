import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Firebase Authentication Service - Production Level
///
/// Kurallar:
/// - Pre-check YOK (fetchSignInMethodsForEmail KULLANILMAZ)
/// - Tek doğrulama: createUserWithEmailAndPassword
/// - Tüm hatalar açıkça mapping edilir
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Getters ─────────────────────────────────────────────────────────────

  /// Auth state değişikliklerini dinle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Mevcut kullanıcı
  User? get currentUser => _auth.currentUser;

  /// Mevcut user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Giriş yapmış mı?
  bool get isLoggedIn => _auth.currentUser != null;

  /// Email doğrulanmış mı?
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ── Validation Helpers (Firebase ÖNCESİ) ───────────────────────────────

  /// Email format kontrolü
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return AppConstants.validationEmailRequired;
    }
    final trimmed = email.trim();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmed)) {
      return AppConstants.validationEmailInvalid;
    }
    return null;
  }

  /// Şifre format kontrolü
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return AppConstants.validationPasswordRequired;
    }
    if (password.length < 6) {
      return AppConstants.validationPasswordTooShort;
    }
    return null;
  }

  /// İsim format kontrolü
  static String? validateDisplayName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return AppConstants.validationNameRequired;
    }
    if (name.trim().length < 2) {
      return AppConstants.validationNameTooShort;
    }
    return null;
  }

  /// Boş alan kontrolü
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  // ── Register (TEK DOĞRULAMA NOKTASI) ──────────────────────────────────

  /// Email + Şifre ile kayıt
  ///
  /// ÖNEMLI:
  /// - Pre-check YOK
  /// - Direkt Firebase'e kayıt dener
  /// - Hata varsa FirebaseAuthException fırlatır
  ///
  /// Başarılı olursa UserCredential döner.
  /// Hata olursa FirebaseAuthException üzerinden _mapAuthError mesajı döner.
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // INPUT NORMALIZATION
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedDisplayName = displayName.trim();

    if (kDebugMode) {
      print('[AuthService] 📝 REGISTER ATTEMPT');
      print('[AuthService] Email: $normalizedEmail');
      print('[AuthService] DisplayName: $normalizedDisplayName');
    }

    // FIREBASE VALIDATION GEREKSİZ - UI'da yapıldı
    // Ama yine de kontrol edelim
    final emailValidation = validateEmail(normalizedEmail);
    if (emailValidation != null) {
      throw Exception(_mapAuthError('invalid-email'));
    }

    final passwordValidation = validatePassword(password);
    if (passwordValidation != null) {
      throw Exception(_mapAuthError('weak-password'));
    }

    try {
      // TEK DOĞRULAMA NOKTASI
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      if (credential.user == null) {
        throw Exception(AppConstants.errorRegisterFailed);
      }

      // Display name güncelle
      await credential.user!.updateDisplayName(normalizedDisplayName);

      // Email verification gönder
      await credential.user!.sendEmailVerification();

      if (kDebugMode) {
        print('[AuthService] ✅ REGISTER SUCCESS: ${credential.user!.uid}');
      }

      return credential;

    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('[AuthService] ❌ FIREBASE ERROR: ${e.code}');
        print('[AuthService] ❌ MESSAGE: ${e.message}');
      }
      // Firebase hata kodunu kullanıcı dostu mesaja çevir
      throw Exception(_mapAuthError(e.code));
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────

  /// Email + Şifre ile giriş
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (kDebugMode) {
      print('[AuthService] 🔑 LOGIN ATTEMPT: $normalizedEmail');
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      if (credential.user == null) {
        throw Exception(AppConstants.errorSignInFailed);
      }

      if (kDebugMode) {
        print('[AuthService] ✅ LOGIN SUCCESS: ${credential.user!.uid}');
      }

      return credential;

    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('[AuthService] ❌ LOGIN ERROR: ${e.code}');
      }
      throw Exception(_mapAuthError(e.code));
    }
  }

  // ── Password Reset ─────────────────────────────────────────────────────

  /// Şifre sıfırlama emaili gönder
  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (kDebugMode) {
      print('[AuthService] 📧 PASSWORD RESET: $normalizedEmail');
    }

    try {
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('[AuthService] ❌ PASSWORD RESET ERROR: ${e.code}');
      }
      throw Exception(_mapAuthError(e.code));
    }
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────

  /// Çıkış yap
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Çıkış yapılamadı: ${e.toString()}');
    }
  }

  // ── User Management ─────────────────────────────────────────────────────

  /// Email doğrulama gönder
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(AppConstants.errorNotAuthenticated);
    }
    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Kullanıcı verilerini yeniden yükle
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Display name güncelle
  Future<void> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName.trim());
    } catch (e) {
      throw Exception('Ad güncellenemedi: ${e.toString()}');
    }
  }

  /// Hesabı sil
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      throw Exception('Hesap silinirken hata: ${e.toString()}');
    }
  }

  // ── ERROR MAPPING (NET VE AÇIK) ──────────────────────────────────────

  /// Firebase Auth error code → Kullanıcı dostu mesaj
  ///
  /// ZORUNLU mapping:
  /// - email-already-in-use → "Bu E-Posta Zaten Kayıtlı"
  /// - invalid-email → "Geçersiz e-posta adresi"
  /// - weak-password → "Şifre çok zayıf"
  /// - operation-not-allowed → "Email/Password girişi aktif değil"
  /// - network-request-failed → "İnternet bağlantınızı kontrol edin"
  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return AppConstants.errorEmailInUse;

      case 'invalid-email':
        return AppConstants.errorInvalidEmail;

      case 'weak-password':
        return AppConstants.errorWeakPassword;

      case 'user-not-found':
        return AppConstants.errorUserNotFound;

      case 'wrong-password':
        return AppConstants.errorWrongPassword;

      case 'user-disabled':
        return AppConstants.errorUserDisabled;

      case 'too-many-requests':
        return AppConstants.errorTooManyRequests;

      case 'operation-not-allowed':
        return AppConstants.errorOperationNotAllowed;

      case 'network-request-failed':
        return AppConstants.errorNetworkFailed;

      case 'invalid-credential':
        return 'Geçersiz giriş bilgileri';

      case 'INVALID_CREDENTIAL':
        return 'Geçersiz giriş bilgileri';

      case 'credential-already-in-use':
        return 'Bu hesap başka bir cihazda kullanılıyor';

      case 'requires-recent-login':
        return 'Tekrar giriş yapmanız gerekiyor';

      case 'missing-email':
        return 'E-posta adresi gerekli';

      case 'invalid-verification-code':
        return 'Geçersiz doğrulama kodu';

      case 'invalid-verification-id':
        return 'Geçersiz doğrulama ID';

      default:
        return 'Bir hata oluştu ($code)';
    }
  }
}
