import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/config/firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/go_router_config.dart';
import 'core/services/recipe_service.dart';
import 'core/services/like_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/user_service.dart';
import 'repositories/local_recipe_repository.dart';
import 'repositories/recipe_repository.dart';
import 'repositories/firestore_recipe_repository.dart';
import 'providers/add_recipe_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'services/firebase_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const YioRecipeApp());
}

class YioRecipeApp extends StatelessWidget {
  const YioRecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme provider — manages light/dark mode with persistence
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider()..init(),
        ),

        // Single source of truth: FirebaseAuth instance
        Provider<FirebaseAuth>(
          create: (_) => FirebaseAuth.instance,
        ),

        // AuthService — Firebase Auth wrapper for GoRouter
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),

        // UserService — Firestore user profile operations for GoRouter
        Provider<UserService>(
          create: (_) => UserService(),
        ),

        // Global recipe service — reads/writes the top-level `recipes/` collection
        Provider<RecipeService>(
          create: (_) => RecipeService(),
        ),

        // Like service — manages user favorites
        Provider<LikeService>(
          create: (_) => LikeService(),
        ),

        // Recipe repository — user-scoped, switches local ↔ Firestore based on auth
        ProxyProvider<FirebaseAuth, RecipeRepository>(
          update: (_, auth, previous) {
            final user = auth.currentUser;
            if (user != null) {
              return FirestoreRecipeRepository(userId: user.uid);
            }
            return LocalRecipeRepository();
          },
        ),

        // Add recipe provider — inject Firebase Storage + RecipeService when logged in
        ProxyProvider3<FirebaseAuth, RecipeRepository, RecipeService,
            AddRecipeProvider>(
          update: (_, auth, recipeRepository, recipeService, previous) {
            final user = auth.currentUser;
            final storageService = user != null
                ? FirebaseStorageService(userId: user.uid)
                : null;
            return AddRecipeProvider(
              repository: recipeRepository,
              storageService: storageService,
              recipeService: recipeService,
              currentUserId: user?.uid,
            );
          },
        ),

        // Settings provider — manages app settings and preferences
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider()..init(),
        ),
      ],
      child: Builder(
        builder: (context) {
          // GoRouter için gerekli servisleri Provider'dan al
          final authService = context.read<AuthService>();
          final userService = context.read<UserService>();
          final themeProvider = context.watch<ThemeProvider>();

          return MaterialApp.router(
            title: 'YIO Recipe App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: createGoRouter(
              authService: authService,
              userService: userService,
            ),
          );
        },
      ),
    );
  }
}
