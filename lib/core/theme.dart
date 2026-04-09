import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color bgCream = Color(0xFFFFF8E7);
  static const Color primary = Color(0xFFE8A020);      // yellow "preorder"
  static const Color gradientStart = Color(0xFFF5A623); // orange
  static const Color gradientEnd = Color(0xFFD0021B);   // red
  static const Color darkBg = Color(0xFF1A1410);
  static const Color darkCard = Color(0xFF2C2010);
  static const Color textDark = Color(0xFF1A1410);
  static const Color textMuted = Color(0xFF6B6B6B);
  static const Color white = Color(0xFFFFFFFF);

  static LinearGradient get buttonGradient => const LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class PreorderTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgCream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.bgCream,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 40, fontWeight: FontWeight.w900,
          color: AppColors.textDark, height: 1.1,
        ),
        headlineMedium: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16, color: AppColors.textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        surface: AppColors.darkBg,
      ),
    );
  }
}