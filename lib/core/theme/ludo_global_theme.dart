import 'package:flutter/material.dart';

abstract final class LudoGlobalTheme {
  static const Color _background = Color(0xFF071A36);
  static const Color _surface = Color(0xFF0C2B55);
  static const Color _accent = Color(0xFF18A7FF);

  static ThemeData get dark {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.dark,
      surface: _surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _background,
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
      ),
    );
  }
}
