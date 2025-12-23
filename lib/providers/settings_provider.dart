import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to manage app settings (language, theme, network preferences).
class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    _loadSettings();
  }

  // Settings keys for SharedPreferences
  static const String _languageKey = 'app_language';
  static const String _themeModeKey = 'theme_mode';
  static const String _allowMobileDataKey = 'allow_mobile_data';

  // Default values
  String _language = 'en'; // 'en' or 'he'
  ThemeMode _themeMode = ThemeMode.system;
  bool _allowMobileData = true;

  // Getters
  String get language => _language;
  ThemeMode get themeMode => _themeMode;
  bool get allowMobileData => _allowMobileData;

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load language (default to system locale or 'en')
      _language = prefs.getString(_languageKey) ?? 'en';

      // Load theme mode (default to system)
      final themeModeString = prefs.getString(_themeModeKey);
      _themeMode = _parseThemeMode(themeModeString);

      // Load mobile data preference (default to true)
      _allowMobileData = prefs.getBool(_allowMobileDataKey) ?? true;

      notifyListeners();
    } on Exception {
      // If loading fails, keep default values
    }
  }

  /// Parse theme mode from string
  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Convert theme mode to string for storage
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Set language and persist to SharedPreferences
  Future<void> setLanguage(String newLanguage) async {
    if (_language == newLanguage) return;

    _language = newLanguage;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, newLanguage);
    } on Exception {
      // Silently fail if saving fails
    }
  }

  /// Set theme mode and persist to SharedPreferences
  Future<void> setThemeMode(ThemeMode newThemeMode) async {
    if (_themeMode == newThemeMode) return;

    _themeMode = newThemeMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, _themeModeToString(newThemeMode));
    } on Exception {
      // Silently fail if saving fails
    }
  }

  /// Set mobile data usage preference and persist to SharedPreferences
  Future<void> setAllowMobileData(bool allow) async {
    if (_allowMobileData == allow) return;

    _allowMobileData = allow;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_allowMobileDataKey, allow);
    } on Exception {
      // Silently fail if saving fails
    }
  }
}
