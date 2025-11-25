import 'package:flutter/material.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  
  // Varsayılan Başlangıç Rengi (Senin Orijinal Pembe/Turuncu)
  Color _primaryColor = const Color(0xFFFE806F); 
  Color _secondaryColor = const Color(0xFFF07294); 

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;

  // Ana ekrandaki gradienti oluşturan zeka
  LinearGradient get currentGradient {
    // Eğer karanlık moddaysak, kullanıcının seçtiği rengin 
    // daha koyu/ağır bir versiyonunu oluşturuyoruz.
    if (_themeMode == ThemeMode.dark) {
       return LinearGradient(
         colors: [
           // Seçilen rengi karartarak kullanıyoruz, böylece dark moda uyuyor
           HSVColor.fromColor(_primaryColor).withValue(0.4).toColor(),
           HSVColor.fromColor(_secondaryColor).withValue(0.4).toColor(),
         ],
         begin: Alignment.topLeft,
         end: Alignment.bottomRight,
       );
    }
    // Aydınlık modda canlı rengi göster
    return LinearGradient(
      colors: [_primaryColor, _secondaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  ThemeProvider() {
    _loadFromPrefs();
  }

  // Temayı Değiştir (Koyu/Açık)
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _saveThemeToPrefs();
    notifyListeners();
  }

  // Rengi Değiştir
  void updateColor(Color start, Color end) {
    _primaryColor = start;
    _secondaryColor = end;
    _saveColorToPrefs();
    notifyListeners();
  }

  // --- HAFIZA İŞLEMLERİ (Kapatıp açınca hatırlasın diye) ---

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    final startColorVal = prefs.getInt('startColor');
    final endColorVal = prefs.getInt('endColor');

    if (startColorVal != null && endColorVal != null) {
      _primaryColor = Color(startColorVal);
      _secondaryColor = Color(endColorVal);
    }
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDark', _themeMode == ThemeMode.dark);
  }

  Future<void> _saveColorToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('startColor', _primaryColor.value);
    prefs.setInt('endColor', _secondaryColor.value);
  }
}