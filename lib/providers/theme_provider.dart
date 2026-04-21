import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ThemeMode options for the app
enum ThemeModeOption {
  light('Aydınlık', Icons.light_mode_outlined, Icons.light_mode, Brightness.light),
  dark('Karanlık', Icons.dark_mode_outlined, Icons.dark_mode, Brightness.dark),
  system('Sistem', Icons.brightness_auto_outlined, Icons.brightness_auto, null);

  final String label;
  final IconData iconOutlined;
  final IconData iconFilled;
  final Brightness? brightness;

  const ThemeModeOption(this.label, this.iconOutlined, this.iconFilled, this.brightness);
}

/// ThemeProvider manages app theme mode with persistence
/// 
/// Uses SharedPreferences to store user's theme preference
/// Supports Light, Dark, and System modes
class ThemeProvider extends ChangeNotifier {
  ThemeModeOption _themeModeOption = ThemeModeOption.system;
  SharedPreferences? _prefs;

  ThemeModeOption get themeModeOption => _themeModeOption;
  
  /// Get current ThemeMode based on selection
  ThemeMode get themeMode {
    switch (_themeModeOption) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }

  /// Get current brightness (for immediate use without ThemeMode)
  Brightness getBrightness(BuildContext context) {
    switch (_themeModeOption) {
      case ThemeModeOption.light:
        return Brightness.light;
      case ThemeModeOption.dark:
        return Brightness.dark;
      case ThemeModeOption.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }

  /// Check if system mode is currently active
  bool get isSystemMode => _themeModeOption == ThemeModeOption.system;

  /// Initialize provider and load saved preference
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadThemeMode();
  }

  /// Load theme mode from SharedPreferences
  void _loadThemeMode() {
    if (_prefs == null) return;
    
    final savedMode = _prefs!.getString('theme_mode') ?? 'system';
    _themeModeOption = ThemeModeOption.values.firstWhere(
      (mode) => mode.name == savedMode,
      orElse: () => ThemeModeOption.system,
    );
    notifyListeners();
  }

  /// Set theme mode and persist to SharedPreferences
  Future<void> setThemeMode(ThemeModeOption option) async {
    _themeModeOption = option;
    
    // Persist to SharedPreferences
    if (_prefs != null) {
      await _prefs!.setString('theme_mode', option.name);
    }
    
    notifyListeners();
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme(BuildContext context) async {
    final currentBrightness = getBrightness(context);
    final newOption = currentBrightness == Brightness.light
        ? ThemeModeOption.dark
        : ThemeModeOption.light;
    await setThemeMode(newOption);
  }

  /// Check if current mode is dark
  bool isDarkMode(BuildContext context) {
    return getBrightness(context) == Brightness.dark;
  }
}
