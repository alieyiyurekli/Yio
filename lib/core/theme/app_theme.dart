import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Premium theme system with Instagram/Spotify level dark mode
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.lightCardBackground,
        background: AppColors.lightBackground,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
        displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
        displaySmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
        headlineSmall: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
        titleLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
        titleMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.lightTextPrimary),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.lightTextPrimary),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.lightTextSecondary),
        bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.lightTextTertiary),
        labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.lightTextPrimary),
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        titleTextStyle: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: AppColors.lightShadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.lightCardBackground,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.lightTextInverse,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.lightTextTertiary),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightCardBackground,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      ),

      iconTheme: const IconThemeData(color: AppColors.lightTextPrimary, size: 24),

      dividerTheme: const DividerThemeData(color: AppColors.lightDivider, thickness: 1, space: 1),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightBackground,
        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.lightTextPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryDarkMode,
        primary: AppColors.primaryDarkMode,
        secondary: AppColors.primaryDarkModeSoft,
        surface: AppColors.darkCardBackground,
        background: AppColors.darkBackground,
        error: AppColors.error,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,

      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
        displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
        displaySmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
        headlineSmall: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
        titleLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
        titleMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkTextPrimary),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.darkTextPrimary),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.darkTextSecondary),
        bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.darkTextTertiary),
        labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkTextPrimary),
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        titleTextStyle: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDarkMode),
        iconTheme: const IconThemeData(color: AppColors.darkIconActive),
        actionsIconTheme: const IconThemeData(color: AppColors.darkIconActive),
      ),

      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: AppColors.darkShadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.darkCardBackground,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDarkMode,
          foregroundColor: AppColors.lightTextInverse,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDarkMode,
          side: const BorderSide(color: AppColors.primaryDarkMode, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryDarkMode, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.darkTextTertiary),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkBackground,
        selectedItemColor: AppColors.primaryDarkMode,
        unselectedItemColor: AppColors.darkIconInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      ),

      iconTheme: const IconThemeData(color: AppColors.darkIconActive, size: 24),

      dividerTheme: const DividerThemeData(color: AppColors.darkDivider, thickness: 1, space: 1),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface,
        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.darkTextPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryDarkMode;
          }
          return AppColors.darkTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryDarkMode.withValues(alpha: 0.5);
          }
          return AppColors.darkBorder;
        }),
      ),

      // ListTile theme
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.darkIconActive,
        textColor: AppColors.darkTextPrimary,
        tileColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDarkModeSoft,
        foregroundColor: AppColors.lightTextInverse,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
