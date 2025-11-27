import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  
  // Varsayılan: Okyanus Mavisi
  LinearGradient _currentGradient = const LinearGradient(
    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  ThemeMode get themeMode => _themeMode;
  LinearGradient get currentGradient => _currentGradient;

  Color get primaryColor => _currentGradient.colors.first;
  Color get secondaryColor => _currentGradient.colors.last;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  // EKSİK OLAN FONKSİYON BU:
  void setGradient(LinearGradient gradient) async {
    _currentGradient = gradient;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('gradientStart', gradient.colors.first.value);
    await prefs.setInt('gradientEnd', gradient.colors.last.value);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    final start = prefs.getInt('gradientStart');
    final end = prefs.getInt('gradientEnd');
    if (start != null && end != null) {
      _currentGradient = LinearGradient(
        colors: [Color(start), Color(end)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    notifyListeners();
  }
}