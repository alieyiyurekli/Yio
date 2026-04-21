import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/recipe_service.dart';
import '../../core/services/like_service.dart';
import '../../core/constants/colors.dart';
import '../../models/recipe_model.dart';
import '../../widgets/ingredient_item.dart';

class RecipeDetailPage extends StatefulWidget {
  final String recipeId;

  const RecipeDetailPage({
    super.key,
    required this.recipeId,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  bool isCookingMode = false;

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  void _toggleCookingMode() {
    setState(() {
      isCookingMode = !isCookingMode;
    });

    if (isCookingMode) {
      WakelockPlus.enable();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yemek yapma modu aktif! Ekran kapanmayacak.'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      WakelockPlus.disable();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yemek yapma modu kapatıldı.'),
            backgroundColor: AppColors.textSecondary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeService = context.read<RecipeService>();
    final likeService = context.read<LikeService>();
    final firebaseAuth = context.watch<FirebaseAuth>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: recipeService.getRecipeStream(widget.recipeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final recipeData = snapshot.data;
          if (recipeData == null) {
            return const Scaffold(
              body: Center(child: Text('Tarif bulunamadı')),
            );
          }

          // Convert map to Recipe model
          final recipe = _mapToRecipe(recipeData, widget.recipeId);

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Hero Image
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    backgroundColor: AppColors.cardBackground,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.cardBackground,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                    actions: [
                      // Screen Lock Toggle
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCookingMode
                              ? AppColors.primary
                              : AppColors.cardBackground,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _toggleCookingMode,
                          icon: Icon(
                            isCookingMode
                                ? Icons.screen_lock_portrait
                                : Icons.screen_lock_portrait_outlined,
                            color: isCookingMode
                                ? AppColors.textWhite
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      // Share Button
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.cardBackground,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.share),
                        ),
                      ),
                      // Like Button
                      _buildLikeButton(likeService, firebaseAuth),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            recipe.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.background,
                                child: const Icon(
                                  Icons.restaurant,
                                  size: 80,
                                  color: AppColors.textLight,
                                ),
                              );
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              recipe.title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Author Info
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: recipe.chef.avatar.isNotEmpty
                                      ? NetworkImage(recipe.chef.avatar)
                                      : null,
                                  child: recipe.chef.avatar.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recipe.chef.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      recipe.chef.role,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: recipe.difficulty.color,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    recipe.difficulty.displayName,
                                    style: const TextStyle(
                                      color: AppColors.textWhite,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Stats Cards
                            Row(
                              children: [
                                _StatCard(
                                  icon: Icons.access_time,
                                  label: 'Süre',
                                  value: '${recipe.time} dk',
                                ),
                                const SizedBox(width: 12),
                                _StatCard(
                                  icon: Icons.local_fire_department,
                                  label: 'Kalori',
                                  value: '${recipe.calories} kcal',
                                ),
                                const SizedBox(width: 12),
                                _StatCard(
                                  icon: Icons.favorite,
                                  label: 'Beğeni',
                                  value: '${recipeData['likesCount'] ?? 0}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Ingredients Section
                            const Text(
                              'Malzemeler',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...recipe.ingredients.map((ingredient) {
                              return IngredientItem(
                                name: ingredient.displayText,
                                onChanged: (isChecked) {},
                              );
                            }),
                            const SizedBox(height: 32),

                            // Preparation Steps
                            const Text(
                              'Hazırlama Adımları',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...recipe.steps.asMap().entries.map((entry) {
                              final index = entry.key;
                              final step = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${step.stepNumber}',
                                          style: const TextStyle(
                                            color: AppColors.textWhite,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        step.description,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 32),

                            // Like Button (Full Width)
                            _buildLikeButtonFullWidth(
                              likeService,
                              firebaseAuth,
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLikeButton(LikeService likeService, FirebaseAuth firebaseAuth) {
    final currentUser = firebaseAuth.currentUser;
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
          ),
        ],
      ),
      child: StreamBuilder<bool>(
        stream: likeService.isLikedStream(currentUser.uid, widget.recipeId),
        builder: (context, snapshot) {
          final isLiked = snapshot.data ?? false;
          return IconButton(
            onPressed: () async {
              await likeService.toggleLike(
                currentUser.uid,
                widget.recipeId,
              );
            },
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : AppColors.textPrimary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLikeButtonFullWidth(
    LikeService likeService,
    FirebaseAuth firebaseAuth,
  ) {
    final currentUser = firebaseAuth.currentUser;
    if (currentUser == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lütfen giriş yapın'),
                backgroundColor: AppColors.primary,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primary,
          ),
          child: const Text(
            'Favorilere Ekle',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return StreamBuilder<bool>(
      stream: likeService.isLikedStream(currentUser.uid, widget.recipeId),
      builder: (context, snapshot) {
        final isLiked = snapshot.data ?? false;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await likeService.toggleLike(
                currentUser.uid,
                widget.recipeId,
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: isLiked
                  ? AppColors.textSecondary
                  : AppColors.primary,
            ),
            child: Text(
              isLiked
                  ? 'Favorilerden Çıkar'
                  : 'Favorilere Ekle',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Recipe _mapToRecipe(Map<String, dynamic> data, String recipeId) {
    // Handle different image field names
    String imageUrl = '';
    if (data['imageUrl'] != null) {
      imageUrl = data['imageUrl'] as String;
    } else if (data['imagePath'] != null) {
      imageUrl = data['imagePath'] as String;
    } else if (data['imagePaths'] != null && (data['imagePaths'] as List).isNotEmpty) {
      imageUrl = (data['imagePaths'] as List).first as String;
    }

    // Handle different author avatar field names
    String authorAvatar = '';
    if (data['authorAvatar'] != null) {
      authorAvatar = data['authorAvatar'] as String;
    } else if (data['authorPhotoUrl'] != null) {
      authorAvatar = data['authorPhotoUrl'] as String;
    }

    // Handle different description/instruction field names
    String description = '';
    if (data['description'] != null) {
      description = data['description'] as String;
    } else if (data['instructions'] != null) {
      description = data['instructions'] as String;
    }

    // Handle ingredients - could be List<String> or List<Map>
    List<Ingredient> ingredients = [];
    if (data['ingredients'] != null) {
      for (var ing in data['ingredients'] as List) {
        if (ing is String) {
          ingredients.add(Ingredient(name: ing));
        } else if (ing is Map<String, dynamic>) {
          ingredients.add(Ingredient(
            name: ing['name'] as String? ?? '',
            amount: ing['amount']?.toString(),
            unit: ing['unit'] as String?,
          ));
        }
      }
    }

    // Handle steps - could be List<String> or single instruction
    List<RecipeStep> steps = [];
    if (data['steps'] != null) {
      final stepList = data['steps'] as List;
      for (int i = 0; i < stepList.length; i++) {
        final s = stepList[i];
        steps.add(RecipeStep(
          stepNumber: i + 1,
          description: s is Map<String, dynamic>
              ? s['description'] as String? ?? ''
              : s.toString(),
        ));
      }
    } else if (data['instructions'] != null) {
      steps = [
        RecipeStep(
          stepNumber: 1,
          description: data['instructions'] as String,
        ),
      ];
    }

    return Recipe(
      id: recipeId,
      title: data['title'] ?? 'Başlıksız Tarif',
      description: description,
      image: imageUrl,
      cookingTime: (data['cookingTime'] ?? 0) as int,
      calories: (data['calories'] ?? data['totalCalories'] ?? 0) as int,
      category: data['category'] ?? 'Diğer',
      difficulty: _parseDifficulty(data['difficulty'] ?? 'Easy'),
      ingredients: ingredients,
      steps: steps,
      chef: Chef(
        id: data['authorId'] as String? ?? '',
        name: data['authorName'] ?? 'Anonim',
        role: 'Tarif Sahibi',
        avatar: authorAvatar,
      ),
      isFavorite: false,
    );
  }

  Difficulty _parseDifficulty(String value) {
    switch (value.toLowerCase()) {
      case 'easy':
        return Difficulty.easy;
      case 'medium':
        return Difficulty.medium;
      case 'hard':
        return Difficulty.hard;
      default:
        return Difficulty.easy;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
