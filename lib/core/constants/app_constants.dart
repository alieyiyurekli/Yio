/// Application-wide constants.
///
/// All magic strings, Firestore collection/field names, and
/// reusable configuration values live here.
/// Never hard-code these values inside UI or service files.
class AppConstants {
  AppConstants._();

  // ── Firestore collection names ──────────────────────────────────────────────
  static const String usersCollection = 'users';

  // ── Firestore field names ───────────────────────────────────────────────────
  static const String fieldUid = 'uid';
  static const String fieldEmail = 'email';
  static const String fieldName = 'name';
  static const String fieldUsername = 'username';
  static const String fieldPhotoUrl = 'photoUrl';
  static const String fieldBio = 'bio';
  static const String fieldInterests = 'interests';
  static const String fieldRole = 'role';
  static const String fieldOnboardingCompleted = 'onboardingCompleted';
  static const String fieldCreatedAt = 'createdAt';

  // ── User roles ──────────────────────────────────────────────────────────────
  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';

  // ── Onboarding ──────────────────────────────────────────────────────────────
  static const int onboardingTotalSteps = 3;
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 20;
  static const int bioMaxLength = 150;
  static const int interestsMinCount = 1;
  static const int interestsMaxCount = 5;

  static const List<String> availableInterests = [
    'Türk Mutfağı',
    'İtalyan Mutfağı',
    'Japon Mutfağı',
    'Meksika Mutfağı',
    'Çin Mutfağı',
    'Hint Mutfağı',
    'Akdeniz',
    'Vegan',
    'Vejetaryen',
    'Glütensiz',
    'Tatlılar',
    'Pastacılık',
    'Izgara & BBQ',
    'Kahvaltı',
    'Çorba & Stew',
    'Salata',
    'Deniz Ürünleri',
    'Sokak Yemekleri',
  ];

  // ── Auth error messages (Türkçe) ────────────────────────────────────────────
  static const String errorUserNotFound =
      'Kullanıcı bulunamadı. Lütfen kayıt olun.';
  static const String errorWrongPassword =
      'Hatalı şifre. Lütfen tekrar deneyin.';
  static const String errorEmailInUse =
      'Bu e-posta adresi zaten kullanımda.';
  static const String errorInvalidEmail = 'Geçersiz e-posta adresi.';
  static const String errorWeakPassword =
      'Şifre çok zayıf. En az 6 karakter kullanın.';
  static const String errorUserDisabled = 'Bu hesap devre dışı bırakılmış.';
  static const String errorTooManyRequests =
      'Çok fazla deneme. Lütfen daha sonra tekrar deneyin.';
  static const String errorNetworkFailed =
      'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
  static const String errorOperationNotAllowed =
      'Bu işlem şu anda izin verilmiyor.';
  static const String errorGeneric = 'Bir hata oluştu. Lütfen tekrar deneyin.';
  static const String errorRegisterFailed =
      'Kayıt işlemi başarısız: Kullanıcı oluşturulamadı.';
  static const String errorSignInFailed =
      'Giriş başarısız: Kullanıcı bilgileri alınamadı.';
  static const String errorNotAuthenticated = 'Kullanıcı oturumu bulunamadı.';
  static const String errorUsernameTaken =
      'Bu kullanıcı adı zaten kullanımda.';
  static const String errorUsernameInvalid =
      'Kullanıcı adı yalnızca harf, rakam ve alt çizgi içerebilir.';

  // ── Validation messages ─────────────────────────────────────────────────────
  static const String validationEmailRequired = 'E-posta adresi gerekli';
  static const String validationEmailInvalid =
      'Geçerli bir e-posta adresi girin';
  static const String validationPasswordRequired = 'Şifre gerekli';
  static const String validationPasswordTooShort =
      'Şifre en az 6 karakter olmalı';
  static const String validationPasswordMismatch = 'Şifreler eşleşmiyor';
  static const String validationNameRequired = 'Ad soyad gerekli';
  static const String validationNameTooShort = 'Ad soyad en az 2 karakter olmalı';
  static const String validationUsernameRequired = 'Kullanıcı adı gerekli';
  static const String validationUsernameTooShort =
      'Kullanıcı adı en az 3 karakter olmalı';
  static const String validationUsernameFormat =
      'Kullanıcı adı yalnızca harf, rakam ve _ içerebilir';
  static const String validationInterestsRequired =
      'Lütfen en az 1 ilgi alanı seçin';

  // ── UI strings ──────────────────────────────────────────────────────────────
  static const String appName = 'YIO';
  static const String appSlogan = 'Mutfağın Sosyal Ağı';
}
