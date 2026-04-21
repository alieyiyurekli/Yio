import 'package:flutter/material.dart';

/// Premium color system with light/dark mode support
/// Instagram/Spotify level dark mode implementation
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY BRAND COLORS
  // ============================================
  /// Light mode - Bright orange
  static const Color primary = Color(0xFFFF7A45);
  static const Color primaryLight = Color(0xFFFF9B6E);
  static const Color primaryDark = Color(0xFFE56A35);
  
  /// Dark mode - Slightly desaturated for premium feel
  static const Color primaryDarkMode = Color(0xFFFF8A50);
  static const Color primaryDarkModeSoft = Color(0xFFFF7A45);
  
  static const Color primaryContainerLight = Color(0xFFFFE8DC);
  static const Color primaryContainerDark = Color(0xFF8C3A1A);

  // ============================================
  // LIGHT THEME COLORS
  // ============================================
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  
  static const Color lightTextPrimary = Color(0xFF2D2D2D);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightTextTertiary = Color(0xFF999999);
  static const Color lightTextInverse = Color(0xFFFFFFFF);

  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightDivider = Color(0xFFEEEEEE);
  static const Color lightShadow = Color(0x1A000000);
  static const Color lightShadowLight = Color(0x0D000000);

  // ============================================
  // DARK THEME COLORS (Premium)
  // ============================================
  /// Main background - Deepest dark
  static const Color darkBackground = Color(0xFF121212);
  
  /// Secondary background - For sections
  static const Color darkSurface = Color(0xFF1A1A1A);
  
  /// Card background - Slightly lighter
  static const Color darkCardBackground = Color(0xFF1E1E1E);
  
  /// Border color - Subtle separation
  static const Color darkBorder = Color(0xFF2A2A2A);
  
  /// Divider color
  static const Color darkDivider = Color(0xFF2A2A2A);
  
  /// Text colors - Premium hierarchy
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextTertiary = Color(0xFF888888);
  static const Color darkTextInverse = Color(0xFF2D2D2D);
  
  /// Icon colors
  static const Color darkIconActive = Color(0xFFE0E0E0);
  static const Color darkIconInactive = Color(0xFF888888);
  
  /// Shadow colors - Subtle depth
  static const Color darkShadow = Color(0x1A000000);
  static const Color darkShadowLight = Color(0x0D000000);
  
  /// Story avatar background
  static const Color darkStoryBackground = Color(0xFF2A2A2A);
  static const Color darkStoryBorder = Color(0xFFFF8A50);

  // ============================================
  // SEMANTIC COLORS (Theme-agnostic)
  // ============================================
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);
  
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFD54F);
  static const Color warningDark = Color(0xFFFFA000);
  
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorDark = Color(0xFFD32F2F);
  
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF42A5F5);
  static const Color infoDark = Color(0xFF1976D2);

  // ============================================
  // DIFFICULTY COLORS
  // ============================================
  static const Color easy = Color(0xFF4CAF50);
  static const Color easyLight = Color(0xFF81C784);
  static const Color easyDark = Color(0xFF388E3C);
  
  static const Color medium = Color(0xFFFFA726);
  static const Color mediumLight = Color(0xFFFFB74D);
  static const Color mediumDark = Color(0xFFFF9800);
  
  static const Color hard = Color(0xFFEF5350);
  static const Color hardLight = Color(0xFFE57373);
  static const Color hardDark = Color(0xFFE53935);

  // ============================================
  // SOCIAL COLORS
  // ============================================
  static const Color like = Color(0xFFE91E63);
  static const Color likeLight = Color(0xFFF06292);
  static const Color save = Color(0xFF2196F3);
  static const Color saveLight = Color(0xFF64B5F6);

  // ============================================
  // OVERLAY COLORS
  // ============================================
  static const Color overlayLight = Color(0x0A000000);
  static const Color overlayMedium = Color(0x14000000);
  static const Color overlayDark = Color(0x1F000000);

  // ============================================
  // HELPER METHODS
  // ============================================
  /// Get background color based on brightness
  static Color background(Brightness brightness) {
    return brightness == Brightness.dark 
        ? darkBackground 
        : lightBackground;
  }

  /// Get surface color based on brightness
  static Color surface(Brightness brightness) {
    return brightness == Brightness.dark 
        ? darkSurface 
        : lightSurface;
  }

  /// Get card background color based on brightness
  static Color cardBackground(Brightness brightness) {
    return brightness == Brightness.dark 
        ? darkCardBackground 
        : lightCardBackground;
  }

  /// Get text primary color based on brightness
  static Color textPrimary(Brightness brightness) {
    return brightness == Brightness.dark 
        ? darkTextPrimary 
        : lightTextPrimary;
  }

  /// Get text secondary color based on brightness
  static Color textSecondary(Brightness brightness) {
    return brightness == Brightness.dark 
        ? darkTextSecondary 
        : lightTextSecondary;
  }

  /// Get text tertiary color based on brightness
  static Color textTertiary(Brightness brightness) {
    return brightness == Brightness.dark 
        ? darkTextTertiary 
        : lightTextTertiary;
  }

  /// Get border color based on brightness
  static Color border(Brightness brightness) {
    return brightness == Brightness.dark 
        ? darkBorder 
        : lightBorder;
  }

  /// Get shadow color based on brightness
  static Color shadow(Brightness brightness) {
    return brightness == Brightness.dark 
        ? darkShadow 
        : lightShadow;
  }

  /// Get primary container color based on brightness
  static Color primaryContainer(Brightness brightness) {
    return brightness == Brightness.dark 
        ? primaryContainerDark 
        : primaryContainerLight;
  }

  /// Get primary color based on brightness (slightly desaturated in dark mode)
  static Color primaryColor(Brightness brightness) {
    return brightness == Brightness.dark 
        ? primaryDarkMode 
        : primary;
  }

  /// Get icon active color based on brightness
  static Color iconActive(Brightness brightness) {
    return brightness == Brightness.dark 
        ? darkIconActive 
        : lightTextPrimary;
  }

  /// Get icon inactive color based on brightness
  static Color iconInactive(Brightness brightness) {
    return brightness == Brightness.dark 
        ? darkIconInactive 
        : lightTextTertiary;
  }

  /// Get difficulty color based on difficulty level
  static Color difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
      case 'kolay':
        return easy;
      case 'medium':
      case 'orta':
        return medium;
      case 'hard':
      case 'zor':
        return hard;
      default:
        return medium;
    }
  }
}
