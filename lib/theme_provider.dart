import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme
  final String _themePrefKey = 'themeMode';

  ThemeMode get themeMode => _themeMode;

  // Renamed to be more explicit and made public
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themePrefKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners(); // Notify listeners after loading
  }

  void setTheme(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;
    _themeMode = themeMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_themePrefKey, themeMode.index);
  }
}