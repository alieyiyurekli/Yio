import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/recipe_service.dart';
import '../../core/services/like_service.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/story_avatar.dart';
import '../../core/constants/colors.dart';
import '../../models/recipe_model.dart';

/// Home Screen — Real recipe feed from Firestore
///
/// Displays recipes from the global `recipes/` collection ordered by
/// createdAt (latest first). Users can like/unlike recipes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipeService = context.watch<RecipeService>();
    final likeService = context.watch<LikeService>();
    final currentUser = context.watch<FirebaseAuth>().currentUser;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            _buildAppBar(),

            // Stories (placeholder for future feature)
            _buildStories(),

            // Tabs
            _buildTabs(),

            // Recipe Feed
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildFeed(recipeService, likeService, currentUser?.uid)
                  : _buildSearchResults(recipeService, likeService, currentUser?.uid),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'YIO',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimary,
                letterSpacing: 2,
              ),
            ),
          ),
          const Spacer(),
          // Notification Icon
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_outlined, color: theme.iconTheme.color),
          ),
          // Message Icon
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.message_outlined, color: theme.iconTheme.color),
          ),
          // AI Assistant Icon
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A2A2A)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                context.push('/ai-assistant');
              },
              icon: Icon(
                Icons.smart_toy,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStories() {
    // TODO: Implement user stories feature
    // For now, showing placeholder avatars
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 5,
        itemBuilder: (context, index) {
          return StoryAvatar(
            name: index == 0 ? 'Sen' : 'Kullanıcı $index',
            avatarUrl: '',
            isYourStory: index == 0,
            onTap: () {
              // Handle story tap
            },
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    final theme = Theme.of(context);
    final tabs = ['Trend', 'Takip', 'Yeni'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => Padding(
            padding: const EdgeInsets.only(right: 24),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tabs[index],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _selectedTab == index
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedTab == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_selectedTab == index)
                    Container(
                      height: 3,
                      width: 30,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the main recipe feed from Firestore
  Widget _buildFeed(
    RecipeService recipeService,
    LikeService likeService,
    String? currentUserId,
  ) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: recipeService.feedStream(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tarifler yüklenemedi',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final recipes = snapshot.data ?? [];

        if (recipes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz tarif yok',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İlk tarifi sen ekle!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
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

  /// Build search results with debounce
  Widget _buildSearchResults(
    RecipeService recipeService,
    LikeService likeService,
    String? currentUserId,
  ) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: recipeService.searchRecipesStream(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final recipes = snapshot.data ?? [];

        if (recipes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '"$_searchQuery" için sonuç bulunamadı',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
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

  /// Build a recipe card with like functionality
  Widget _buildRecipeCard({
    required Recipe recipe,
    required String recipeId,
    required Map<String, dynamic> recipeData,
    required LikeService likeService,
    required String? currentUserId,
  }) {
    if (currentUserId == null) {
      // Not logged in — show card without like functionality
      return RecipeCard(
        recipe: recipe,
        onTap: () {
          context.push('/recipe-detail/$recipeId');
        },
        onLike: () {},
        onSave: () {},
      );
    }

    // Logged in — show card with real-time like status
    return StreamBuilder<bool>(
      stream: likeService.isLikedStream(currentUserId, recipeId),
      builder: (context, snapshot) {
        final isLiked = snapshot.data ?? false;

        return RecipeCard(
          recipe: recipe.copyWith(
            isFavorite: isLiked,
            likes: (recipeData['likesCount'] as num?)?.toInt() ?? recipe.likes,
          ),
          isLiked: isLiked,
          isSaved: false,
          onTap: () {
            context.push('/recipe-detail/$recipeId');
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
          onSave: () {},
        );
      },
    );
  }

  /// Map Firestore recipe data to Recipe model
  Recipe _mapToRecipe(Map<String, dynamic> data) {
    // Create chef from author info
    final chef = Chef(
      id: data['authorId'] as String? ?? '',
      name: data['authorName'] as String? ?? 'Misafir Şef',
      avatar: data['authorPhotoUrl'] as String? ??
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      role: 'Home Cook',
    );

    // Get image URL
    final imagePaths = data['imagePaths'] as List?;
    final imageUrl = (imagePaths != null && imagePaths.isNotEmpty)
        ? imagePaths[0] as String
        : (data['imagePath'] as String? ??
            'https://images.unsplash.com/photo-1495521821757-a1efb6729352?w=800');

    // Convert ingredients
    final ingredients = <Ingredient>[];
    if (data['ingredients'] != null) {
      for (var ing in data['ingredients'] as List) {
        if (ing is Map<String, dynamic>) {
          ingredients.add(Ingredient(
            name: ing['name'] as String? ?? '',
            amount: ing['amount']?.toString(),
            unit: ing['unit'] as String?,
          ));
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
      cookingTime: data['cookingTime'] as int? ?? 30,
      difficulty: _parseDifficulty(data['difficulty'] as String?),
      chef: chef,
      ingredients: ingredients,
      steps: [
        RecipeStep(
          stepNumber: 1,
          description: data['instructions'] as String? ?? '',
        ),
      ],
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
