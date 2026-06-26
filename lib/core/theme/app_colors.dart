import 'package:flutter/material.dart';

/// Acktron Preorder — Design System Colors
///
/// Palette inspired by Zomato/Swiggy with a warm, food-centric feel.
/// Primary: Deep Orange, Secondary: Amber, Accent: Green.
class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFE65100);       // Deep Orange 900
  static const Color primaryLight = Color(0xFFFF6E40);   // Deep Orange accent
  static const Color primaryDark = Color(0xFFBF360C);    // Deep Orange 900+

  static const Color secondary = Color(0xFFFFC107);      // Amber
  static const Color secondaryLight = Color(0xFFFFD54F);  // Amber 300
  static const Color secondaryDark = Color(0xFFF57F17);   // Amber 900

  static const Color accent = Color(0xFF4CAF50);          // Green
  static const Color accentLight = Color(0xFF81C784);     // Green 300
  static const Color accentDark = Color(0xFF2E7D32);      // Green 800

  // ── Semantic ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57F17);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF1565C0);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ── Light Theme ──────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF5F5F5);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE0E0E0);

  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF616161);
  static const Color textTertiaryLight = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Dark Theme ───────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2C2C2C);
  static const Color cardDark = Color(0xFF252525);
  static const Color dividerDark = Color(0xFF383838);

  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFBDBDBD);
  static const Color textTertiaryDark = Color(0xFF757575);

  // ── Veg / Non-Veg ───────────────────────────────────────────────
  static const Color vegGreen = Color(0xFF0F8A0F);
  static const Color nonVegRed = Color(0xFFC62828);

  // ── Order Status Colors ──────────────────────────────────────────
  static const Color statusPending = Color(0xFFFF9800);
  static const Color statusConfirmed = Color(0xFF2196F3);
  static const Color statusPreparing = Color(0xFF9C27B0);
  static const Color statusReady = Color(0xFF4CAF50);
  static const Color statusCompleted = Color(0xFF388E3C);
  static const Color statusCancelled = Color(0xFFF44336);

  // ── Gradients ────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6E40), Color(0xFFE65100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF6E40), Color(0xFFFFC107)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFE65100), Color(0xFFFF6E40), Color(0xFFFFC107)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkOverlayGradient = LinearGradient(
    colors: [Colors.transparent, Color(0xCC000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Color(0xFFEEEEEE),
      Color(0xFFF5F5F5),
      Color(0xFFEEEEEE),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  static const LinearGradient shimmerGradientDark = LinearGradient(
    colors: [
      Color(0xFF2C2C2C),
      Color(0xFF383838),
      Color(0xFF2C2C2C),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  // ── Glassmorphism ────────────────────────────────────────────────
  static Color glassLight = Colors.white.withValues(alpha: 0.75);
  static Color glassDark = Colors.black.withValues(alpha: 0.45);
  static Color glassBorderLight = Colors.white.withValues(alpha: 0.3);
  static Color glassBorderDark = Colors.white.withValues(alpha: 0.1);
}
