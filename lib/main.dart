import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/config/firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'repositories/local_recipe_repository.dart';
import 'repositories/recipe_repository.dart';
import 'repositories/firestore_recipe_repository.dart';
import 'providers/add_recipe_provider.dart';
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
        // Single source of truth: FirebaseAuth instance
        Provider<FirebaseAuth>(
          create: (_) => FirebaseAuth.instance,
        ),

        // Recipe repository — switches between local and Firestore based on auth state
        ProxyProvider<FirebaseAuth, RecipeRepository>(
          update: (_, auth, previous) {
            final user = auth.currentUser;
            if (user != null) {
              return FirestoreRecipeRepository(userId: user.uid);
            }
            return LocalRecipeRepository();
          },
        ),

        // Add recipe provider — inject Firebase Storage when logged in
        ProxyProvider2<FirebaseAuth, RecipeRepository, AddRecipeProvider>(
          update: (_, auth, recipeRepository, previous) {
            final user = auth.currentUser;
            final storageService = user != null
                ? FirebaseStorageService(userId: user.uid)
                : null;
            return AddRecipeProvider(
              repository: recipeRepository,
              storageService: storageService,
            );
          },
        ),
      ],
      child: MaterialApp(
        title: 'YIO Recipe App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppRouter(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/recipeDetail':
              return MaterialPageRoute(
                builder: (_) => const _PlaceholderScreen(name: 'Recipe Detail'),
                settings: settings,
              );
            case '/add-recipe':
              return MaterialPageRoute(
                builder: (_) => const _PlaceholderScreen(name: 'Add Recipe'),
                settings: settings,
              );
            case '/aiAssistant':
              return MaterialPageRoute(
                builder: (_) => const _PlaceholderScreen(name: 'AI Assistant'),
                settings: settings,
              );
            case '/profile':
              return MaterialPageRoute(
                builder: (_) => const _PlaceholderScreen(name: 'Profile'),
                settings: settings,
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const _PlaceholderScreen(name: 'Unknown Route'),
                settings: settings,
              );
          }
        },
      ),
    );
  }
}

/// Placeholder for routes that are now handled by AppRouter
/// This prevents crashes if old navigation code is still present
class _PlaceholderScreen extends StatelessWidget {
  final String name;

  const _PlaceholderScreen({required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Center(
        child: Text('$name is now handled by AppRouter'),
      ),
    );
  }
}
