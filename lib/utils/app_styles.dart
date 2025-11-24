// lib/utils/app_styles.dart
import 'package:flutter/material.dart';
import 'package:odak_list/utils/app_colors.dart';

class AppStyles {
  // Bu, "Soft UI" (Neumorphism) gölge efektini verir.
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 15,
      offset: const Offset(5, 5),
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.9),
      blurRadius: 15,
      offset: const Offset(-5, -5),
    ),
  ];

  // Ana pembe/turuncu gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      AppColors.primaryGradientStart,
      AppColors.primaryGradientEnd,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}