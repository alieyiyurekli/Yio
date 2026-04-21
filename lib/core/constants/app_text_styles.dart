import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Unified text style system for the entire application
/// Uses Material 3 type scale as base
class AppTextStyles {
  AppTextStyles._();

  // ============================================
  // DISPLAY
  // ============================================
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  // ============================================
  // HEADLINE
  // ============================================
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );

  // ============================================
  // TITLE
  // ============================================
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.50,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ============================================
  // LABEL
  // ============================================
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // ============================================
  // BODY
  // ============================================
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // ============================================
  // RECIPE CARD SPECIFIC
  // ============================================
  static const TextStyle recipeTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle recipeDescription = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.4,
  );

  static const TextStyle recipeMeta = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    height: 1.2,
  );

  static const TextStyle chefName = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.2,
  );

  static const TextStyle pillLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static const TextStyle actionCount = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.2,
  );

  // ============================================
  // THEMED VARIANTS (with color)
  // ============================================
  static TextStyle recipeTitleLight = recipeTitle.copyWith(
    color: AppColors.lightTextPrimary,
  );

  static TextStyle recipeTitleDark = recipeTitle.copyWith(
    color: AppColors.darkTextPrimary,
  );

  static TextStyle recipeDescriptionLight = recipeDescription.copyWith(
    color: AppColors.lightTextSecondary,
  );

  static TextStyle recipeDescriptionDark = recipeDescription.copyWith(
    color: AppColors.darkTextSecondary,
  );

  static TextStyle recipeMetaLight = recipeMeta.copyWith(
    color: AppColors.lightTextTertiary,
  );

  static TextStyle recipeMetaDark = recipeMeta.copyWith(
    color: AppColors.darkTextTertiary,
  );

  static TextStyle chefNameLight = chefName.copyWith(
    color: AppColors.lightTextSecondary,
  );

  static TextStyle chefNameDark = chefName.copyWith(
    color: AppColors.darkTextSecondary,
  );

  static const TextStyle pillLabelWhite = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
    color: AppColors.lightTextInverse,
  );

  static TextStyle pillLabelPrimary = pillLabel.copyWith(
    color: AppColors.primary,
  );

  // ============================================
  // HELPER: Theme-aware text style
  // ============================================
  static TextStyle themed(TextStyle base, Brightness brightness) {
    final color = brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    return base.copyWith(color: color);
  }
}
