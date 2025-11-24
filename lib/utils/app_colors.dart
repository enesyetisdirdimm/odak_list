// lib/utils/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Arka plan renkleri
  static const Color background = Color(0xFFF2F5FF); // Çok açık mavi/beyaz
  static const Color cardBackground = Colors.white;

  // Ana vurgu renkleri (Gradient için)
  static const Color primaryGradientStart = Color(0xFFFE806F); // Turuncu
  static const Color primaryGradientEnd = Color(0xFFF07294);   // Pembe

  // Kategori Renkleri (Daha canlı)
  static const Color categoryWork = Color(0xFF007FFF);   // Mavi
  static const Color categoryHome = Color(0xFF28A745);   // Yeşil
  static const Color categorySchool = Color(0xFFFFC107); // Sarı
  static const Color categoryPersonal = Color(0xFF6F42C1); // Mor

  // YENİ: Aciliyet Renkleri
  static const Color priorityHigh = Color(0xFFDC3545); // Kırmızı
  static const Color priorityMedium = Color(0xFFFFC107); // Sarı/Turuncu
  static const Color priorityLow = Color(0xFF17A2B8);    // Mavi/Gri

  // Metin Renkleri
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textLight = Colors.white;
}