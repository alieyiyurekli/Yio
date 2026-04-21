import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_text_styles.dart';
import '../models/recipe_model.dart';

/// Production-ready recipe card widget
/// 
/// A reusable, stateless card component that displays recipe information
/// with Firebase-ready state management from parent.
/// 
/// No direct Firestore calls. All state passed from parent.
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isLiked;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback? onShare;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.isLiked = false,
    this.isSaved = false,
    required this.onTap,
    required this.onLike,
    required this.onSave,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(brightness),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow(brightness),
                blurRadius: AppSpacing.cardElevationHigh,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGE WITH BADGES
                _buildImageSection(context, isDark),

                // CONTENT
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITLE
                      _buildTitle(isDark),
                      const SizedBox(height: AppSpacing.md),

                      // META ROW
                      _buildMetaRow(isDark),
                      const SizedBox(height: AppSpacing.lg),

                      // AUTHOR ROW
                      _buildAuthorRow(isDark),
                      const SizedBox(height: AppSpacing.lg),

                      // ACTION ROW
                      _buildActionRow(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Image section with category and difficulty badges
  Widget _buildImageSection(BuildContext context, bool isDark) {
    return Stack(
      children: [
        // HERO IMAGE
        Hero(
          tag: recipe.id,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLarge),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: recipe.image,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.background(context.mounted
                      ? Theme.of(context).brightness
                      : Brightness.light),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.background(context.mounted
                      ? Theme.of(context).brightness
                      : Brightness.light),
                  child: Icon(
                    Icons.restaurant,
                    size: 48,
                    color: AppColors.textTertiary(Theme.of(context).brightness),
                  ),
                ),
              ),
            ),
          ),
        ),

        // CATEGORY PILL (TOP-LEFT)
        Positioned(
          top: AppSpacing.md,
          left: AppSpacing.md,
          child: _buildCategoryBadge(isDark),
        ),

        // DIFFICULTY PILL (TOP-RIGHT)
        Positioned(
          top: AppSpacing.md,
          right: AppSpacing.md,
          child: _buildDifficultyBadge(isDark),
        ),
      ],
    );
  }

  /// Category badge widget
  Widget _buildCategoryBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
      ),
      child: Text(
        recipe.category,
        style: AppTextStyles.pillLabelWhite,
      ),
    );
  }

  /// Difficulty badge widget
  Widget _buildDifficultyBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: recipe.difficulty.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
      ),
      child: Text(
        recipe.difficulty.displayName,
        style: AppTextStyles.pillLabelWhite,
      ),
    );
  }

  /// Title widget
  Widget _buildTitle(bool isDark) {
    return Text(
      recipe.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: isDark
          ? AppTextStyles.recipeTitleDark
          : AppTextStyles.recipeTitleLight,
    );
  }

  /// Meta row: time, calories, difficulty
  Widget _buildMetaRow(bool isDark) {
    return Row(
      children: [
        // TIME
        Icon(
          Icons.access_time,
          size: AppSpacing.iconMedium,
          color: AppColors.textTertiary(Brightness.light),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${recipe.cookingTime} min',
          style: isDark
              ? AppTextStyles.recipeMetaDark
              : AppTextStyles.recipeMetaLight,
        ),

        const SizedBox(width: AppSpacing.lg),

        // CALORIES
        const Icon(
          Icons.local_fire_department,
          size: AppSpacing.iconMedium,
          color: AppColors.warning,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${recipe.calories} kcal',
          style: isDark
              ? AppTextStyles.recipeMetaDark
              : AppTextStyles.recipeMetaLight,
        ),
      ],
    );
  }

  /// Author row with avatar and name
  Widget _buildAuthorRow(bool isDark) {
    return Row(
      children: [
        // AVATAR
        CircleAvatar(
          radius: AppSpacing.avatarSmall / 2,
          backgroundColor: AppColors.primary.withOpacity(0.15),
          backgroundImage: recipe.chef.avatar.isNotEmpty
              ? CachedNetworkImageProvider(recipe.chef.avatar)
              : null,
          child: recipe.chef.avatar.isEmpty
              ? const Icon(
                  Icons.person,
                  size: AppSpacing.iconSmall,
                  color: AppColors.primary,
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.md),

        // NAME AND ROLE
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.chef.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: isDark
                    ? AppTextStyles.chefNameDark
                    : AppTextStyles.chefNameLight,
              ),
              Text(
                recipe.chef.role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: isDark
                    ? AppTextStyles.recipeMeta.copyWith(
                        color: AppColors.darkTextTertiary,
                      )
                    : AppTextStyles.recipeMeta.copyWith(
                        color: AppColors.lightTextTertiary,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Action buttons row
  Widget _buildActionRow(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Row(
      children: [
        // LIKE BUTTON
        _ActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(recipe.likes),
          iconColor: isLiked ? AppColors.like : AppColors.textTertiary(brightness),
          onTap: () {
            HapticFeedback.lightImpact();
            onLike();
          },
        ),

        const SizedBox(width: AppSpacing.lg),

        // SAVE BUTTON
        _ActionButton(
          icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
          label: _formatCount(recipe.saves),
          iconColor: isSaved ? AppColors.save : AppColors.textTertiary(brightness),
          onTap: () {
            HapticFeedback.lightImpact();
            onSave();
          },
        ),

        const Spacer(),

        // SHARE BUTTON
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onShare ?? () {},
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Icon(
                Icons.share_outlined,
                size: AppSpacing.iconMedium,
                color: AppColors.textTertiary(brightness),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Format count to K, M format (e.g., 1200 -> 1.2K)
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Individual action button component
class _ActionButton extends StatefulWidget {
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
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _animateTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: AppSpacing.iconMedium,
                  color: widget.iconColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  widget.label,
                  style: AppTextStyles.actionCount.copyWith(
                    color: AppColors.textSecondary(brightness),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
