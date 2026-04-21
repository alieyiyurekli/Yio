import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../constants/colors.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/home/home_page.dart';
import '../../features/home/admin_home_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/recipe/add_recipe_page.dart';
import '../../features/recipe/recipe_detail_page.dart';
import '../../screens/ai/ai_assistant_screen.dart' show AIAssistantScreen;

// ─────────────────────────────────────────────────────────────────────────────
// Route path sabitleri
// Uygulama genelinde tüm route path'leri bu sınıfta tanımlanır.
// Magic string kullanımını önler ve type-safe navigation sağlar.
// ─────────────────────────────────────────────────────────────────────────────

/// Uygulama genelinde kullanılan route path sabitleri.
///
/// Tüm navigasyon işlemlerinde `context.go(AppRoutes.xxx)` veya
/// `context.push(AppRoutes.xxx)` şeklinde kullanılır.
class AppRoutes {
  AppRoutes._();

  /// Başlangıç ekranı — auth durumu yüklenirken gösterilir
  static const splash = '/';

  /// Giriş sayfası — oturum açmamış kullanıcılar için
  static const login = '/login';

  /// Kayıt ve profil kurulum sayfası — 4 adımlı akış
  static const register = '/register';

  /// Onboarding sayfası — auth var ama profil tamamlanmamış kullanıcılar için
  static const onboarding = '/onboarding';

  /// Ana sayfa — normal kullanıcılar için
  static const home = '/home';

  /// Admin ana sayfası — admin rolündeki kullanıcılar için
  static const adminHome = '/admin-home';

  /// Tarif ekleme sayfası
  static const addRecipe = '/add-recipe';

  /// Tarif detay sayfası — recipeId parametresi gerekli
  static const recipeDetail = '/recipe-detail';

  /// AI asistan sayfası
  static const aiAssistant = '/ai-assistant';
}

// ─────────────────────────────────────────────────────────────────────────────
// RouterNotifier
// GoRouter'ın refreshListenable'ı için ChangeNotifier implementasyonu.
// AuthService ve UserService stream'lerini dinleyerek state değişikliklerini
// GoRouter'a bildirir.
// ─────────────────────────────────────────────────────────────────────────────

/// GoRouter redirect mekanizması için auth ve profil state'ini yöneten notifier.
///
/// İki stream'i paralel olarak dinler:
/// 1. [AuthService.authStateChanges] — Firebase Auth oturum durumu
/// 2. [UserService.userProfileStream] — Firestore kullanıcı profil durumu
///
/// Herhangi bir state değişikliğinde [notifyListeners] çağrılır ve
/// GoRouter redirect callback'ini yeniden tetikler.
class RouterNotifier extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;

  /// Firebase Auth kullanıcısı — null ise oturum açılmamış
  User? _authUser;

  /// Firestore kullanıcı profili — null ise profil yok veya yükleniyor
  AppUser? _appUser;

  /// Auth state ilk kez yüklenene kadar true — splash ekranında bekletir
  bool _isLoading = true;

  /// Auth stream subscription — dispose'da iptal edilir
  StreamSubscription<User?>? _authSubscription;

  /// Profil stream subscription — auth user değişince yeniden kurulur
  StreamSubscription<AppUser?>? _profileSubscription;

  RouterNotifier({
    required AuthService authService,
    required UserService userService,
  })  : _authService = authService,
        _userService = userService {
    _initAuthListener();
  }

  // ── Public getters ────────────────────────────────────────────────────────

  /// Auth state yükleniyorsa true
  bool get isLoading => _isLoading;

  /// Mevcut Firebase Auth kullanıcısı
  User? get authUser => _authUser;

  /// Mevcut Firestore kullanıcı profili
  AppUser? get appUser => _appUser;

  // ── Stream başlatma ────────────────────────────────────────────────────────

  /// Auth state stream'ini başlatır.
  ///
  /// Auth durumu değiştiğinde:
  /// 1. _authUser güncellenir
  /// 2. Profil stream'i yeniden kurulur (yeni kullanıcı için) veya iptal edilir
  /// 3. notifyListeners çağrılarak GoRouter redirect tetiklenir
  void _initAuthListener() {
    debugPrint('[RouterNotifier] Auth stream başlatılıyor');

    _authSubscription = _authService.authStateChanges.listen(
      (User? user) {
        debugPrint('[RouterNotifier] Auth state değişti: ${user?.uid ?? "null"}');

        _authUser = user;

        if (user == null) {
          // Oturum kapatıldı — profil stream'ini iptal et ve profili temizle
          debugPrint('[RouterNotifier] Oturum kapatıldı → profil stream iptal ediliyor');
          _cancelProfileSubscription();
          _appUser = null;
          _isLoading = false;
          notifyListeners();
        } else {
          // Yeni kullanıcı oturumu — profil stream'ini (yeniden) kur
          debugPrint('[RouterNotifier] Oturum açıldı (${user.uid}) → profil stream kuruluyor');
          _listenToUserProfile(user.uid);
        }
      },
      onError: (Object error, StackTrace stack) {
        // Auth stream hatası — loading durumunu kapat, login'e yönlendir
        debugPrint('[RouterNotifier] Auth stream hatası: $error');
        _authUser = null;
        _appUser = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Belirtilen uid için Firestore profil stream'ini dinlemeye başlar.
  ///
  /// Önceki profil subscription varsa iptal edilir (uid değişimi durumu).
  /// Stream her yeni snapshot'ta profili günceller ve GoRouter'ı tetikler.
  void _listenToUserProfile(String uid) {
    // Önceki profil stream'ini kapat — tek bir subscription olmasını garantiler
    _cancelProfileSubscription();

    // Profil yüklenene kadar loading state aktif
    _isLoading = true;
    notifyListeners();

    _profileSubscription = _userService.userProfileStream(uid).listen(
      (AppUser? profile) {
        debugPrint(
          '[RouterNotifier] Profil stream güncellendi: '
          'uid=$uid, '
          'onboardingCompleted=${profile?.onboardingCompleted}, '
          'role=${profile?.role}',
        );

        _appUser = profile;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        // Profil stream hatası — profili null yap, loading kapat
        debugPrint('[RouterNotifier] Profil stream hatası: $error');
        _appUser = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Aktif profil stream subscription'ını iptal eder.
  void _cancelProfileSubscription() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
  }

  // ── ChangeNotifier lifecycle ───────────────────────────────────────────────

  @override
  void dispose() {
    debugPrint('[RouterNotifier] dispose çağrıldı — subscription\'lar iptal ediliyor');
    _authSubscription?.cancel();
    _cancelProfileSubscription();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GoRouter konfigürasyonu
// ─────────────────────────────────────────────────────────────────────────────

/// GoRouter instance'ı oluşturur ve konfigüre eder.
///
/// [authService] ve [userService] dependency injection ile alınır;
/// bu sayede test edilebilirlik sağlanır.
///
/// Redirect mantığı [AppRouter]'daki StreamBuilder akışını birebir taklit eder:
/// ```
/// isLoading        → '/' (splash)
/// authUser == null → '/login'
/// appUser == null  → '/register' (auth var, profil yok)
/// !onboardingCompleted → '/onboarding'
/// role == 'admin'  → '/admin-home'
/// default          → '/home'
/// ```
GoRouter createGoRouter({
  required AuthService authService,
  required UserService userService,
}) {
  // RouterNotifier instance'ı — router'ın yaşam döngüsüyle aynı
  final notifier = RouterNotifier(
    authService: authService,
    userService: userService,
  );

  return GoRouter(
    // Başlangıç konumu — splash ekranı
    initialLocation: AppRoutes.splash,

    // Debug modda route log'larını aktifleştir
    debugLogDiagnostics: kDebugMode,

    // RouterNotifier'ı refreshListenable olarak bağla.
    // notifyListeners() çağrıldığında GoRouter redirect'i otomatik tetikler.
    refreshListenable: notifier,

    // ── Redirect logic ──────────────────────────────────────────────────────
    // Mevcut AppRouter StreamBuilder mantığını birebir uygular.
    // null döndürmek "yönlendirme yok, mevcut route'da kal" anlamına gelir.
    redirect: (BuildContext context, GoRouterState state) {
      final currentPath = state.matchedLocation;

      debugPrint('[GoRouter] redirect tetiklendi: path=$currentPath, '
          'isLoading=${notifier.isLoading}, '
          'authUser=${notifier.authUser?.uid ?? "null"}, '
          'appUser=${notifier.appUser?.uid ?? "null"}, '
          'onboardingCompleted=${notifier.appUser?.onboardingCompleted}');

      // ── 1. Auth state yükleniyorsa splash'de bekle ──────────────────────
      if (notifier.isLoading) {
        debugPrint('[GoRouter] Yükleniyor → splash\'de bekleniyor');
        // Zaten splash'deyse yönlendirme yapma
        if (currentPath == AppRoutes.splash) return null;
        return AppRoutes.splash;
      }

      // ── 2. Oturum açılmamış → login sayfasına yönlendir ──────────────────
      if (notifier.authUser == null) {
        debugPrint('[GoRouter] Auth yok → login sayfasına yönlendiriliyor');
        // Zaten login veya register sayfasındaysa yönlendirme yapma
        if (currentPath == AppRoutes.login ||
            currentPath == AppRoutes.register) {
          return null;
        }
        return AppRoutes.login;
      }

      // Bu noktadan sonra kullanıcı oturum açmış durumda

      // ── 3. Profil eksik → register sayfasına yönlendir ───────────────────
      // Auth başarılı ama Firestore dokümanı yok (kayıt yarıda kesilmiş olabilir)
      if (notifier.appUser == null) {
        debugPrint('[GoRouter] Profil eksik → register sayfasına yönlendiriliyor');
        if (currentPath == AppRoutes.register) return null;
        return AppRoutes.register;
      }

      final appUser = notifier.appUser!;

      // ── 4. Onboarding tamamlanmamış → onboarding sayfasına yönlendir ─────
      if (!appUser.onboardingCompleted) {
        debugPrint('[GoRouter] Onboarding tamamlanmamış → onboarding sayfasına yönlendiriliyor');
        if (currentPath == AppRoutes.onboarding) return null;
        return AppRoutes.onboarding;
      }

      // ── 5. Onboarding tamamlandı — auth sayfalarından çıkar ──────────────
      // Kullanıcı authenticated + onboarding tamamlamış iken login/register/
      // onboarding sayfalarında kalmamalı
      final isOnAuthPage = currentPath == AppRoutes.login ||
          currentPath == AppRoutes.register ||
          currentPath == AppRoutes.onboarding ||
          currentPath == AppRoutes.splash;

      if (isOnAuthPage) {
        // Role'e göre doğru home sayfasına yönlendir
        if (appUser.role == AppConstants.roleAdmin) {
          debugPrint('[GoRouter] Admin kullanıcı + auth sayfasında → admin-home\'a yönlendiriliyor');
          return AppRoutes.adminHome;
        }
        debugPrint('[GoRouter] Normal kullanıcı + auth sayfasında → home\'a yönlendiriliyor');
        return AppRoutes.home;
      }

      // ── 6. Admin route guard ──────────────────────────────────────────────
      // Normal kullanıcı admin sayfasına erişmeye çalışıyorsa engelle
      if (currentPath == AppRoutes.adminHome &&
          appUser.role != AppConstants.roleAdmin) {
        debugPrint('[GoRouter] Normal kullanıcı admin sayfasına erişmeye çalışıyor → home\'a yönlendiriliyor');
        return AppRoutes.home;
      }

      // ── 7. Varsayılan — yönlendirme yok ──────────────────────────────────
      debugPrint('[GoRouter] Yönlendirme yok — mevcut path\'de kalınıyor: $currentPath');
      return null;
    },

    // ── Route tanımları ─────────────────────────────────────────────────────
    routes: [
      // Splash — auth durumu yüklenirken gösterilir
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const _SplashScreen(),
      ),

      // Login — oturum açmamış kullanıcılar
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // Register — 4 adımlı kayıt + onboarding akışı
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Onboarding — auth var ama profil tamamlanmamış kullanıcılar.
      // OnboardingPage required uid parametresi alıyor;
      // redirect garantisi sayesinde bu route'a sadece authUser != null
      // durumunda erişilir, bu yüzden authService.currentUserId güvenle kullanılır.
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) {
          // Redirect logic auth user'ın var olduğunu garanti eder.
          // Savunmacı programlama için fallback: login'e yönlendir.
          final uid = authService.currentUserId;
          if (uid == null) {
            debugPrint('[GoRouter] Onboarding route: uid null — login\'e yönlendiriliyor');
            // GoRouter'ın bir sonraki redirect döngüsünde düzeltmesi için
            // boş bir widget döndür; redirect zaten login'e götürecek
            return const _SplashScreen();
          }
          return OnboardingPage(uid: uid);
        },
      ),

      // Home — normal kullanıcılar
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // Admin Home — admin rolündeki kullanıcılar
      GoRoute(
        path: AppRoutes.adminHome,
        name: 'adminHome',
        builder: (context, state) => const AdminHomePage(),
      ),

      // Add Recipe — tarif ekleme sayfası
      GoRoute(
        path: AppRoutes.addRecipe,
        name: 'addRecipe',
        builder: (context, state) => const AddRecipePage(),
      ),

      // Recipe Detail — tarif detay sayfası
      // recipeId path parametresi: /recipe-detail/:recipeId
      GoRoute(
        path: '${AppRoutes.recipeDetail}/:recipeId',
        name: 'recipeDetail',
        builder: (context, state) {
          final recipeId = state.pathParameters['recipeId'] ?? '';
          return RecipeDetailPage(recipeId: recipeId);
        },
      ),

      // AI Assistant — placeholder
      GoRoute(
        path: AppRoutes.aiAssistant,
        name: 'aiAssistant',
        builder: (context, state) => const AIAssistantScreen(),
      ),
    ],

    // ── Error builder ───────────────────────────────────────────────────────
    // Bilinmeyen route veya hata durumunda gösterilir
    errorBuilder: (context, state) {
      debugPrint('[GoRouter] Route hatası: ${state.error}');
      return _ErrorScreen(
        message: state.error?.message ?? 'Bilinmeyen bir sayfa hatası oluştu',
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Yardımcı Widget'lar
// AppRouter'daki _SplashScreen ve _ErrorScreen ile tutarlı tasarım
// ─────────────────────────────────────────────────────────────────────────────

/// Auth state ve profil yüklenirken gösterilen splash ekranı.
///
/// [AppRouter]'daki `_SplashScreen` ile aynı tasarım — tutarlılık için.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Uygulama logosu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Yükleme göstergesi
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bilinmeyen route veya navigasyon hatası durumunda gösterilen ekran.
///
/// GoRouter'ın `errorBuilder` callback'inden çağrılır.
class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hata ikonu
              const Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              // Hata mesajı
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              // Login sayfasına dön butonu
              ElevatedButton(
                onPressed: () {
                  // GoRouter context extension ile login'e git
                  if (context.mounted) {
                    GoRouter.of(context).go(AppRoutes.login);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Ana Sayfaya Dön',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
