import 'package:flutter/material.dart';

/// Acktron Preorder — Shadow & Elevation Tokens
///
/// Consistent elevation system for cards, modals, and interactive elements.
class AppShadows {
  AppShadows._();

  // ── Card Shadows ─────────────────────────────────────────────────
  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      ),
    ];
  }

  static List<BoxShadow> cardShadowMedium(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.4)
            : Colors.black.withValues(alpha: 0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      ),
    ];
  }

  static List<BoxShadow> cardShadowLarge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.12),
        blurRadius: 32,
        offset: const Offset(0, 12),
        spreadRadius: 0,
      ),
    ];
  }

  // ── Soft Glow ────────────────────────────────────────────────────
  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: const Color(0xFFE65100).withValues(alpha: 0.3),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> successGlow = [
    BoxShadow(
      color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  // ── Bottom Sheet / Modal ─────────────────────────────────────────
  static List<BoxShadow> get bottomSheetShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 24,
      offset: const Offset(0, -8),
      spreadRadius: 0,
    ),
  ];

  // ── Floating Action Button ───────────────────────────────────────
  static List<BoxShadow> get fabShadow => [
    BoxShadow(
      color: const Color(0xFFE65100).withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  // ── Border Radius Tokens ─────────────────────────────────────────
  static const double radiusXs = 6;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 28;
  static const double radiusFull = 100;

  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusXxl = BorderRadius.all(Radius.circular(radiusXxl));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));

  // ── Spacing Tokens ───────────────────────────────────────────────
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 20;
  static const double spacingXxl = 24;
  static const double spacing3xl = 32;
  static const double spacing4xl = 40;
  static const double spacing5xl = 48;
}
