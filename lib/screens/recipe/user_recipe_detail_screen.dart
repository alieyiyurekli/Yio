import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/recipe_model.dart';
import '../../models/user_recipe_model.dart';
import '../../models/gallery_media_model.dart';
import '../../widgets/ingredient_item.dart';
import '../../widgets/recipe_media_carousel.dart';
import '../../core/constants/colors.dart';

class UserRecipeDetailScreen extends StatefulWidget {
  const UserRecipeDetailScreen({super.key});

  @override
  State<UserRecipeDetailScreen> createState() => _UserRecipeDetailScreenState();
}

class _UserRecipeDetailScreenState extends State<UserRecipeDetailScreen> {
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

  /// Build media gallery from user recipe images
  Widget _buildMediaGallery(UserRecipeModel userRecipe) {
    final mediaItems = <GalleryMediaModel>[];

    // Add images from imagePaths
    for (final imagePath in userRecipe.imagePaths) {
      mediaItems.add(GalleryMediaModel.fromFile(imagePath, MediaType.image));
    }

    // Fallback to legacy imagePath
    if (mediaItems.isEmpty && userRecipe.imagePath != null) {
      mediaItems.add(GalleryMediaModel.fromFile(
        userRecipe.imagePath!,
        MediaType.image,
      ));
    }

    // Placeholder if no images
    if (mediaItems.isEmpty) {
      final recipe = userRecipe.toRecipe();
      mediaItems.add(GalleryMediaModel.image(recipe.image));
    }

    // Add video if available
    if (userRecipe.videoPath != null) {
      mediaItems.add(GalleryMediaModel.fromFile(
        userRecipe.videoPath!,
        MediaType.video,
      ));
    }

    return RecipeMediaCarousel(
      mediaItems: mediaItems,
      height: 300,
      showIndicator: mediaItems.length > 1,
      autoPlayVideo: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRecipe =
        ModalRoute.of(context)?.settings.arguments as UserRecipeModel?;

    if (userRecipe == null) {
      return const Scaffold(
        body: Center(child: Text('Recipe not found')),
      );
    }

    final recipe = userRecipe.toRecipe();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // Media Gallery
          SliverToBoxAdapter(
            child: SizedBox(
              height: 300,
              child: Stack(
                children: [
                  // Full-size media carousel
                  Positioned.fill(
                    child: _buildMediaGallery(userRecipe),
                  ),
                  // Gradient overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Back button
                  Positioned(
                    top: 40,
                    left: 16,
                    child: Container(
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
                  ),
                  // Action buttons
                  Positioned(
                    top: 40,
                    right: 16,
                    child: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(4),
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
                        Container(
                          margin: const EdgeInsets.all(4),
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
                      ],
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

                    // Chef Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(recipe.chef.avatar),
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
                          icon: Icons.restaurant,
                          label: 'Seviye',
                          value: recipe.difficulty.displayName,
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
                      'Yapılış',
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
                                borderRadius: BorderRadius.circular(16),
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
                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
