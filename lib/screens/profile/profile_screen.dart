import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/models/app_user.dart';
import '../../core/services/recipe_service.dart';
import '../../core/services/like_service.dart';
import '../../core/services/user_service.dart';
import '../../providers/theme_provider.dart';
import '../../models/recipe_model.dart';
import '../../widgets/recipe_card.dart';
import 'edit_profile_screen.dart';
import '../settings/settings_screen.dart';

/// Modern Profile Screen — Firestore backed, minimalist design
///
/// Features:
/// - Real-time user profile from Firestore
/// - User's recipes from global recipes collection
/// - User's favorites from LikeService
/// - Clean, spacious layout with soft shadows
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<FirebaseAuth>().currentUser;
    
    debugPrint('[ProfileScreen] build() called - currentUser: ${currentUser?.uid}');
    
    if (currentUser == null) {
      debugPrint('[ProfileScreen] currentUser is null, showing login prompt');
      return const Scaffold(
        body: Center(child: Text('Giriş yapmalısınız')),
      );
    }
    
    debugPrint('[ProfileScreen] currentUser.uid: ${currentUser.uid}');

    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
            color: theme.iconTheme.color,
          ),
          IconButton(
            onPressed: () async {
              await context.read<FirebaseAuth>().signOut();
            },
            icon: const Icon(Icons.logout_outlined),
            color: theme.iconTheme.color,
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Profile Header ────────────────────────────────────────────────
                  StreamBuilder<AppUser?>(
                    stream: context.read<UserService>().userProfileStream(currentUser.uid),
                    builder: (context, snapshot) {
                      debugPrint('[ProfileScreen] StreamBuilder state: ${snapshot.connectionState}, hasError: ${snapshot.hasError}, hasData: ${snapshot.hasData}');
                      
                      if (snapshot.hasError) {
                        debugPrint('[ProfileScreen] StreamBuilder ERROR: ${snapshot.error}');
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                              const SizedBox(height: 16),
                              const Text(
                                'Profil yüklenemedi',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Hata: ${snapshot.error}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        debugPrint('[ProfileScreen] StreamBuilder waiting...');
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final user = snapshot.data;
                      debugPrint('[ProfileScreen] StreamBuilder data: ${user?.name}');
                      
                      if (user == null) {
                        debugPrint('[ProfileScreen] StreamBuilder data is NULL - user document may not exist');
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              const Icon(Icons.person_off, size: 48, color: AppColors.textLight),
                              const SizedBox(height: 16),
                              const Text(
                                'Profil bulunamadı',
                                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'UID: ${currentUser.uid}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                              ),
                            ],
                          ),
                        );
                      }

                      return _ProfileHeader(user: user);
                    },
                  ),

                  // ── Stats Row ──────────────────────────────────────────────────────
                  _StatsRow(userId: currentUser.uid),

                  const SizedBox(height: 24),

                  // ── Tabs ───────────────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabItem(
                            label: 'Tariflerim',
                            isSelected: _selectedTab == 0,
                            onTap: () => setState(() => _selectedTab = 0),
                          ),
                        ),
                        Expanded(
                          child: _TabItem(
                            label: 'Kaydedilenler',
                            isSelected: _selectedTab == 1,
                            onTap: () => setState(() => _selectedTab = 1),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Content ────────────────────────────────────────────────────────
                  if (_selectedTab == 0)
                    _UserRecipesTab(userId: currentUser.uid)
                  else
                    _UserFavoritesTab(userId: currentUser.uid),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final AppUser user;

  const _ProfileHeader({required this.user});

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = user.name.isNotEmpty ? user.name : 'Kullanıcı';
    final handle = user.username != null ? '@${user.username}' : null;
    final bio = user.bio?.trim().isNotEmpty == true ? user.bio : 'Yemek sevgili | Pişirme tutkunu';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  const Color(0xFFFFB088),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? Text(
                      _getInitials(displayName),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            displayName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Handle
          if (handle != null) ...[
            Text(
              handle,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Bio
          Text(
            bio ?? 'Yemek sevgili | Pişirme tutkunu',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Edit Profile Button
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(user: user),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Profili Düzenle'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final String userId;

  const _StatsRow({required this.userId});

  @override
  Widget build(BuildContext context) {
    final recipeService = context.watch<RecipeService>();
    final likeService = context.watch<LikeService>();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: recipeService.recipesByAuthorStream(userId),
      builder: (context, snapshot) {
        final recipeCount = snapshot.data?.length ?? 0;

        return StreamBuilder<int>(
          stream: likeService.getUserFavoritesCountStream(userId),
          builder: (context, favSnapshot) {
            final favoriteCount = favSnapshot.data ?? 0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(label: 'Tarifler', value: '$recipeCount'),
                  _StatItem(label: 'Favoriler', value: '$favoriteCount'),
                  const _StatItem(label: 'Takipçi', value: '0'),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Bar Delegate
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const _ProfileTabBarDelegate({
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _TabItem(
              label: 'Tariflerim',
              isSelected: selectedTab == 0,
              onTap: () => onTabChanged(0),
            ),
          ),
          Expanded(
            child: _TabItem(
              label: 'Kaydedilenler',
              isSelected: selectedTab == 1,
              onTap: () => onTabChanged(1),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 50;

  @override
  double get minExtent => 50;

  @override
  bool shouldRebuild(covariant _ProfileTabBarDelegate oldDelegate) {
    return oldDelegate.selectedTab != selectedTab;
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: 24,
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Recipes Tab
// ─────────────────────────────────────────────────────────────────────────────

class _UserRecipesTab extends StatelessWidget {
  final String userId;

  const _UserRecipesTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final recipeService = context.watch<RecipeService>();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: recipeService.recipesByAuthorStream(userId),
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
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Tarifler yüklenemedi',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                  Icon(Icons.restaurant_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz tarifiniz yok',
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İlk tarifinizi eklemek için + butonuna basın',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipeData = recipes[index];
              final recipe = _mapToRecipe(recipeData);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RecipeCard(
                  recipe: recipe,
                  onTap: () {
                    context.push('/recipe-detail/${recipeData['id']}');
                  },
                  onLike: () {}, // Disable like for own recipes
                  onSave: () {},
                ),
              );
            },
          ),
        );
      },
    );
  }

  Recipe _mapToRecipe(Map<String, dynamic> data) {
    final chef = Chef(
      id: data['authorId'] as String? ?? '',
      name: data['authorName'] as String? ?? 'Misafir Şef',
      avatar: data['authorPhotoUrl'] as String? ??
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      role: 'Home Cook',
    );

    final imagePaths = data['imagePaths'] as List?;
    final imageUrl = (imagePaths != null && imagePaths.isNotEmpty)
        ? (imagePaths[0] as String? ?? '')
        : (data['imagePath'] as String? ??
            data['imageUrl'] as String? ??
            'https://images.unsplash.com/photo-1495521821757-a1efb6729352?w=800');

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
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? 'Başlıksız Tarif',
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

// ─────────────────────────────────────────────────────────────────────────────
// User Favorites Tab
// ─────────────────────────────────────────────────────────────────────────────

class _UserFavoritesTab extends StatelessWidget {
  final String userId;

  const _UserFavoritesTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final likeService = context.watch<LikeService>();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: likeService.getUserFavoritesStream(userId),
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
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Favoriler yüklenemedi',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                  Icon(Icons.favorite_border, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz favori tarifiniz yok',
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Beğendiğiniz tarifler burada görünecek',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipeData = recipes[index];
              final recipe = _mapToRecipe(recipeData);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RecipeCard(
                  recipe: recipe.copyWith(isFavorite: true),
                  isLiked: true,
                  isSaved: true,
                  onTap: () {
                    context.push('/recipe-detail/${recipeData['id']}');
                  },
                  onLike: () async {
                    await likeService.toggleLike(userId, recipe.id);
                  },
                  onSave: () {},
                ),
              );
            },
          ),
        );
      },
    );
  }

  Recipe _mapToRecipe(Map<String, dynamic> data) {
    final chef = Chef(
      id: data['authorId'] as String? ?? '',
      name: data['authorName'] as String? ?? 'Misafir Şef',
      avatar: data['authorPhotoUrl'] as String? ??
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      role: 'Home Cook',
    );

    final imagePaths = data['imagePaths'] as List?;
    final imageUrl = (imagePaths != null && imagePaths.isNotEmpty)
        ? (imagePaths[0] as String? ?? '')
        : (data['imagePath'] as String? ??
            data['imageUrl'] as String? ??
            'https://images.unsplash.com/photo-1495521821757-a1efb6729352?w=800');

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
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? 'Başlıksız Tarif',
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
