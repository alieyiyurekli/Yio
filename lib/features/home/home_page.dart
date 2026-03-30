import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/colors.dart';
import '../../core/services/recipe_service.dart';
import '../../core/services/like_service.dart';
import '../../navigation/bottom_navbar.dart';
import '../../widgets/recipe_card.dart';
import '../../models/recipe_model.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/profile_screen.dart';

/// Home Page — main bottom navigation shell for authenticated normal users.
///
/// This is the entry point after successful auth + onboarding.
/// It wraps the existing [HomeScreen], [SearchTab], [LikesTab], and [ProfileScreen].
/// Navigation to this widget is handled entirely by [AppRouter] — no manual
/// Navigator calls are used here.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      const HomeScreen(),
      const SearchTab(),
      const LikesTab(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

// ── Search Tab ─────────────────────────────────────────────────────────────────

class SearchTab extends StatefulWidget {
  const SearchTab();

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipeService = context.watch<RecipeService>();
    final likeService = context.watch<LikeService>();
    final currentUser = context.watch<FirebaseAuth>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Tarif ara...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _query = value.trim());
                },
              ),
            ),

            // Results
            Expanded(
              child: _query.isEmpty
                  ? _buildEmptyState()
                  : _buildResults(recipeService, likeService, currentUser?.uid),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: AppColors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tarif Ara',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yemek tarifi bulun',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(
    RecipeService recipeService,
    LikeService likeService,
    String? currentUserId,
  ) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: recipeService.searchRecipesStream(_query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final recipes = snapshot.data ?? [];

        if (recipes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_off,
                  size: 48,
                  color: AppColors.textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  '"$_query" için sonuç bulunamadı',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipeData = recipes[index];
            final recipe = _mapToRecipe(recipeData);

            return _buildRecipeCard(
              recipe: recipe,
              recipeId: recipeData['id'] as String,
              recipeData: recipeData,
              likeService: likeService,
              currentUserId: currentUserId,
            );
          },
        );
      },
    );
  }

  Widget _buildRecipeCard({
    required Recipe recipe,
    required String recipeId,
    required Map<String, dynamic> recipeData,
    required LikeService likeService,
    required String? currentUserId,
  }) {
    if (currentUserId == null) {
      return RecipeCard(
        recipe: recipe,
        onTap: () {
          Navigator.pushNamed(
            context,
            '/recipeDetail',
            arguments: recipe,
          );
        },
        onLike: null,
      );
    }

    return StreamBuilder<bool>(
      stream: likeService.isLikedStream(currentUserId, recipeId),
      builder: (context, snapshot) {
        final isLiked = snapshot.data ?? false;

        return RecipeCard(
          recipe: recipe.copyWith(
            isFavorite: isLiked,
            likes: (recipeData['likesCount'] as num?)?.toInt() ?? recipe.likes,
          ),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/recipeDetail',
              arguments: recipe,
            );
          },
          onLike: () async {
            try {
              await likeService.toggleLike(currentUserId, recipeId);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('İşlem başarısız: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  Recipe _mapToRecipe(Map<String, dynamic> data) {
    final chef = Chef(
      name: data['authorName'] as String? ?? 'Misafir Şef',
      avatar: data['authorPhotoUrl'] as String? ??
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      role: 'Home Cook',
    );

    final imagePaths = data['imagePaths'] as List?;
    final imageUrl = (imagePaths != null && imagePaths.isNotEmpty)
        ? imagePaths[0] as String
        : (data['imagePath'] as String? ??
            'https://images.unsplash.com/photo-1495521821757-a1efb6729352?w=800');

    final ingredients = <String>[];
    if (data['ingredients'] != null) {
      for (var ing in data['ingredients'] as List) {
        if (ing is Map<String, dynamic>) {
          final name = ing['name'] as String? ?? '';
          final amount = ing['amount']?.toString() ?? '';
          final unit = ing['unit'] as String? ?? '';
          ingredients.add('$amount $unit $name'.trim());
        }
      }
    }

    return Recipe(
      id: data['id'] as String,
      title: data['title'] as String,
      image: imageUrl,
      category: data['category'] as String? ?? 'Ana Yemek',
      description: data['instructions'] as String? ?? '',
      calories: (data['totalCalories'] as num?)?.toInt() ?? 0,
      time: data['cookingTime'] as int? ?? 30,
      difficulty: _parseDifficulty(data['difficulty'] as String?),
      chef: chef,
      ingredients: ingredients,
      steps: [data['instructions'] as String? ?? ''],
      likes: (data['likesCount'] as num?)?.toInt() ?? 0,
      comments: 0,
      isFavorite: false,
    );
  }

  Difficulty _parseDifficulty(String? value) {
    switch (value?.toLowerCase()) {
      case 'easy':
      case 'kolay':
        return Difficulty.easy;
      case 'hard':
      case 'zor':
        return Difficulty.hard;
      default:
        return Difficulty.medium;
    }
  }
}

// ── Likes Tab ──────────────────────────────────────────────────────────────────

class LikesTab extends StatelessWidget {
  const LikesTab();

  @override
  Widget build(BuildContext context) {
    final likeService = context.watch<LikeService>();
    final currentUser = context.watch<FirebaseAuth>().currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text('Giriş yapmalısınız'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: likeService.getUserFavoritesStream(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Beğendikleriniz yüklenemedi',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            final recipes = snapshot.data ?? [];

            if (recipes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: AppColors.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Henüz beğendiğin tarif yok',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Beğendiğin tarifler burada görünecek',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipeData = recipes[index];
                final recipe = _mapToRecipe(recipeData);

                return RecipeCard(
                  recipe: recipe.copyWith(isFavorite: true),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/recipeDetail',
                      arguments: recipe,
                    );
                  },
                  onLike: () async {
                    try {
                      await likeService.toggleLike(currentUser.uid, recipe.id);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('İşlem başarısız: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Recipe _mapToRecipe(Map<String, dynamic> data) {
    final chef = Chef(
      name: data['authorName'] as String? ?? 'Misafir Şef',
      avatar: data['authorPhotoUrl'] as String? ??
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      role: 'Home Cook',
    );

    final imagePaths = data['imagePaths'] as List?;
    final imageUrl = (imagePaths != null && imagePaths.isNotEmpty)
        ? imagePaths[0] as String
        : (data['imagePath'] as String? ??
            'https://images.unsplash.com/photo-1495521821757-a1efb6729352?w=800');

    final ingredients = <String>[];
    if (data['ingredients'] != null) {
      for (var ing in data['ingredients'] as List) {
        if (ing is Map<String, dynamic>) {
          final name = ing['name'] as String? ?? '';
          final amount = ing['amount']?.toString() ?? '';
          final unit = ing['unit'] as String? ?? '';
          ingredients.add('$amount $unit $name'.trim());
        }
      }
    }

    return Recipe(
      id: data['id'] as String,
      title: data['title'] as String,
      image: imageUrl,
      category: data['category'] as String? ?? 'Ana Yemek',
      description: data['instructions'] as String? ?? '',
      calories: (data['totalCalories'] as num?)?.toInt() ?? 0,
      time: data['cookingTime'] as int? ?? 30,
      difficulty: _parseDifficulty(data['difficulty'] as String?),
      chef: chef,
      ingredients: ingredients,
      steps: [data['instructions'] as String? ?? ''],
      likes: (data['likesCount'] as num?)?.toInt() ?? 0,
      comments: 0,
      isFavorite: false,
    );
  }

  Difficulty _parseDifficulty(String? value) {
    switch (value?.toLowerCase()) {
      case 'easy':
      case 'kolay':
        return Difficulty.easy;
      case 'hard':
      case 'zor':
        return Difficulty.hard;
      default:
        return Difficulty.medium;
    }
  }
}
