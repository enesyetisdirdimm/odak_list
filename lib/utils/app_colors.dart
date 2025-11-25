import 'package:flutter/material.dart';

class AppColors {
  // --- AÇIK TEMA (Light) ---
  static const Color backgroundLight = Color(0xFFF2F5FF);
  static const Color cardLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF333333);
  static const Color textSecondaryLight = Color(0xFF888888);

  // --- KOYU TEMA (Dark) ---
  static const Color backgroundDark = Color(0xFF121212); 
  static const Color cardDark = Color(0xFF1E1E1E);       
  static const Color textPrimaryDark = Color(0xFFE0E0E0); 
  static const Color textSecondaryDark = Color(0xFFA0A0A0);

  // --- GRADIENTLER ---
  
  // 1. Aydınlık Mod Gradienti (Canlı Pembe/Turuncu) - ESKİSİ
  static const Color primaryGradientStart = Color(0xFFFE806F);
  static const Color primaryGradientEnd = Color(0xFFF07294);

  // 2. YENİ: Karanlık Mod Gradienti (Deep Purple / Koyu Mürdüm)
  // Bu renkler siyah üzerinde çok daha şık durur.
  static const Color darkGradientStart = Color(0xFF2E1437); // Çok koyu mor
  static const Color darkGradientEnd = Color(0xFF948E99);   // Hafif griye çalan mor

  // Veya daha "Gece Mavisi" istersen bunu kullanabilirsin:
  // static const Color darkGradientStart = Color(0xFF0F2027);
  // static const Color darkGradientEnd = Color(0xFF2C5364);

  // Kategori Renkleri
  static const Color categoryWork = Color(0xFF007FFF);
  static const Color categoryHome = Color(0xFF28A745);
  static const Color categorySchool = Color(0xFFFFC107);
  static const Color categoryPersonal = Color(0xFF6F42C1);
  static const Color categoryGeneral = Colors.grey; 

  // Aciliyet Renkleri
  static const Color priorityHigh = Color(0xFFDC3545);
  static const Color priorityMedium = Color(0xFFFFC107);
  static const Color priorityLow = Color(0xFF17A2B8);
}