import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../constants/colors.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/home/home_page.dart';
import '../../features/home/admin_home_page.dart';

/// Premium Gate System Router
///
/// This router implements the "Premium Gate" pattern:
/// 1. StreamBuilder listens to Firebase Auth state changes
/// 2. FutureBuilder fetches user profile from Firestore
/// 3. Routes based on auth state + onboarding status + role
///
/// No manual navigation is needed in auth/onboarding flows.
/// The router automatically re-evaluates when state changes.
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        // Auth state loading
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          debugPrint('[AppRouter] Auth state: waiting');
          return const _SplashScreen();
        }

        // Auth error
        if (authSnapshot.hasError) {
          debugPrint('[AppRouter] Auth error: ${authSnapshot.error}');
          return const _ErrorScreen(message: 'Auth error occurred');
        }

        // Not logged in → LoginPage
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          debugPrint('[AppRouter] Not logged in → LoginPage');
          return const LoginPage();
        }

        // Logged in → listen to profile changes via stream
        final uid = authSnapshot.data!.uid;
        debugPrint('[AppRouter] Logged in as $uid, listening to profile stream');

        return StreamBuilder<AppUser?>(
          stream: _userService.userProfileStream(uid),
          builder: (context, profileSnapshot) {
            // Profile loading
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              debugPrint('[AppRouter] Profile stream: waiting');
              return const _SplashScreen();
            }

            // Profile error
            if (profileSnapshot.hasError) {
              debugPrint('[AppRouter] Profile error: ${profileSnapshot.error}');
              return const _ErrorScreen(message: 'Profile error occurred');
            }

            // Profile missing → user registered but didn't complete setup
            // This is the edge case where Auth succeeded but Firestore doc is missing
            if (!profileSnapshot.hasData || profileSnapshot.data == null) {
              debugPrint('[AppRouter] Profile missing → RegisterPage (resume onboarding)');
              return const RegisterPage();
            }

            final appUser = profileSnapshot.data!;
            debugPrint('[AppRouter] Profile loaded: onboardingCompleted=${appUser.onboardingCompleted}, role=${appUser.role}');

            // Onboarding not completed → back to RegisterPage step 2+
            if (!appUser.onboardingCompleted) {
              debugPrint('[AppRouter] Onboarding not completed → RegisterPage');
              return const RegisterPage();
            }

            // Onboarding completed → check role
            if (appUser.role == AppConstants.roleAdmin) {
              debugPrint('[AppRouter] Admin user → AdminHomePage');
              return const AdminHomePage();
            }

            // Normal user → HomePage
            debugPrint('[AppRouter] Normal user → HomePage');
            return const HomePage();
          },
        );
      },
    );
  }
}

/// Error screen shown when auth or profile stream errors occur.
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
              const Icon(Icons.error_outline, size: 56, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Yeniden Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Splash screen shown during auth state and profile loading
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
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
