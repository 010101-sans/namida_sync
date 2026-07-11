import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// [1] Provider for managing and persisting the app's theme mode (light, dark, system).
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // [2] Load the theme mode from persistent storage on initialization.
  ThemeProvider() {
    // debugPrint('[ThemeProvider] Initializing and loading theme from storage.');
    _loadThemeFromStorage();
  }

  // [3] Loads the theme mode from SharedPreferences asynchronously.
  Future<void> _loadThemeFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey);
      if (themeIndex != null) {
        _themeMode = ThemeMode.values[themeIndex];
        // debugPrint('[ThemeProvider] Loaded theme mode from storage: $_themeMode');
        notifyListeners();
      } else {
        // debugPrint('[ThemeProvider] No theme mode found in storage, using system default.');
      }
    } catch (e) {
      // If there's an error loading the theme, keep the default system theme
      // debugPrint('[ThemeProvider] Error loading theme from storage: $e');
    }
  }

  // [4] Saves the current theme mode to SharedPreferences asynchronously.
  Future<void> _saveThemeToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, _themeMode.index);
      // debugPrint('[ThemeProvider] Saved theme mode to storage: $_themeMode');
    } catch (e) {
      // debugPrint('[ThemeProvider] Error saving theme to storage: $e');
    }
  }

  // [5] Toggles between light and dark theme modes and persists the change.
  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    // debugPrint('[ThemeProvider] Toggled theme mode to: $_themeMode');
    _saveThemeToStorage();
    notifyListeners();
  }

  // [6] Set the theme mode and persist the change if it is different from the current mode.
  void setTheme(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      // debugPrint('[ThemeProvider] Set theme mode to: $_themeMode');
      _saveThemeToStorage();
      notifyListeners();
    }
  }

  void setLightTheme() => setTheme(ThemeMode.light);
  void setDarkTheme() => setTheme(ThemeMode.dark);
  void setSystemTheme() => setTheme(ThemeMode.system);

  bool get isLight => _themeMode == ThemeMode.light;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isSystem => _themeMode == ThemeMode.system;

  String get themeModeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}
