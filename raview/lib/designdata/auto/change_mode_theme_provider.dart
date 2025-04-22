import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raview/designdata/theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  static const THEME_KEY = "theme_key";
  late SharedPreferences prefs;
  ThemeData _themeData;
  
  ThemeProvider() : _themeData = AppTheme.LightTheme {
    loadTheme();
  }

  ThemeData get themeData => _themeData;

  // Initialize SharedPreferences
  Future<void> loadTheme() async {
    prefs = await SharedPreferences.getInstance();
    final bool isDark = prefs.getBool(THEME_KEY) ?? false;
    _themeData = isDark ? AppTheme.DarkTheme : AppTheme.LightTheme;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeData == AppTheme.LightTheme) {
      _themeData = AppTheme.DarkTheme;
      await prefs.setBool(THEME_KEY, true);
    } else {
      _themeData = AppTheme.LightTheme;
      await prefs.setBool(THEME_KEY, false);
    }
    notifyListeners();
  }
}