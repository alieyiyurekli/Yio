import 'dart:io';
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../core/constants/colors.dart';
import '../widgets/recipe_tags.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final VoidCallback? onLike;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image with Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: _buildImage(recipe.image),
                ),
                // Category Badge (top-left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: CategoryBadge(category: recipe.category),
                ),
                // Difficulty Badge (top-right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
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
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chef Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(recipe.chef.avatar),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        recipe.chef.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          recipe.category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Recipe Title
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Recipe Description
                  Text(
                    recipe.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Tags (if available)
                  if (recipe.tags != null && recipe.tags!.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: recipe.tags!.take(2).map((tag) {
                        return TagChip(
                          tag: tag,
                          isSelected: false,
                          isAnimated: false,
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),

                  // Stats Row (Time, Calories)
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.time} min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.calories} kcal',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      _ActionButton(
                        icon: recipe.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: '${recipe.likes}',
                        iconColor: recipe.isFavorite
                            ? Colors.red
                            : AppColors.textLight,
                        onTap: onLike,
                      ),
                      const SizedBox(width: 16),
                      _ActionButton(
                        icon: Icons.comment_outlined,
                        label: '${recipe.comments}',
                        iconColor: AppColors.textLight,
                        onTap: () {},
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.share_outlined,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper method to build image from network URL or local file path
Widget _buildImage(String imagePath) {
  // Check if it's a local file path (starts with /)
  if (imagePath.startsWith('/') || imagePath.startsWith('file://')) {
    final path = imagePath.startsWith('file://') ? imagePath.replaceFirst('file://', '') : imagePath;
    return Image.file(
      File(path),
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 200,
          color: AppColors.background,
          child: const Icon(
            Icons.restaurant,
            size: 60,
            color: AppColors.textLight,
          ),
        );
      },
    );
  } else {
    // Network image
    return Image.network(
      imagePath,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 200,
          color: AppColors.background,
          child: const Icon(
            Icons.restaurant,
            size: 60,
            color: AppColors.textLight,
          ),
        );
      },
    );
  }
}
