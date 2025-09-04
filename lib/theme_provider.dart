import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  light,
  dark,
  auto, // <-- custom time-based theme mode
}

class ThemeProvider extends ChangeNotifier {
  AppThemeMode appThemeMode = AppThemeMode.auto;

  ThemeMode get currentThemeMode {
    switch (appThemeMode) {
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.auto:
        return _isNightTime() ? ThemeMode.dark : ThemeMode.light;
    }
  }

  bool get isDarkMode => currentThemeMode == ThemeMode.dark;

  Future<void> setThemeMode(AppThemeMode mode) async {
    appThemeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    await setThemeMode(isDark ? AppThemeMode.dark : AppThemeMode.light);
  }

  Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('themeMode');

    if (saved != null) {
      appThemeMode = AppThemeMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => AppThemeMode.auto,
      );
    } else {
      appThemeMode = AppThemeMode.auto;
    }

    notifyListeners();
  }

  bool _isNightTime() {
    final hour = DateTime.now().hour;
    return hour >= 19 || hour < 7;
  }

  Future<void> updateBasedOnTime() async {
    if (appThemeMode == AppThemeMode.auto) {
      notifyListeners(); // trigger theme change if time changed
    }
  }
}
