import 'package:flutter/material.dart';

class PreorderTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.green);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.green);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
    );
  }
}

