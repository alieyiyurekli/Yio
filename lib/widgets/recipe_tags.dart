import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/recipe_constants.dart';

/// Animated tag chip for recipe tags
class TagChip extends StatefulWidget {
  final String tag;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isAnimated;

  const TagChip({
    super.key,
    required this.tag,
    this.isSelected = false,
    this.onTap,
    this.isAnimated = true,
  });

  @override
  State<TagChip> createState() => _TagChipState();
}

class _TagChipState extends State<TagChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.isAnimated) {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ),
      );
      if (widget.isSelected) {
        _controller.forward();
      }
    }
  }

  @override
  void didUpdateWidget(TagChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimated) {
      if (widget.isSelected != oldWidget.isSelected) {
        if (widget.isSelected) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      }
    }
  }

  @override
  void dispose() {
    if (widget.isAnimated) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chip = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: widget.isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          widget.tag,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: widget.isSelected ? AppColors.textWhite : AppColors.textSecondary,
          ),
        ),
      ),
    );

    if (widget.isAnimated) {
      return AnimatedScale(
        scale: _scaleAnimation.value,
        duration: const Duration(milliseconds: 200),
        child: chip,
      );
    }
    return chip;
  }
}

/// Category badge for recipe cards
class CategoryBadge extends StatelessWidget {
  final String category;

  const CategoryBadge({
    super.key,
    required this.category,
  });

  Color _getCategoryColor() {
    final colorCode = RecipeConstants.categoryColors[category];
    if (colorCode != null) {
      return Color(colorCode);
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getCategoryColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: AppColors.textWhite,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Info row widget for displaying recipe metadata
class RecipeInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const RecipeInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textLight,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
