import 'package:flutter/material.dart';

import 'ludo_global_tokens.dart';

abstract final class LudoGlobalTheme {
  static ThemeData get dark {
    const ColorScheme colorScheme = ColorScheme.dark(
      primary: LudoGlobalColors.electricBlue,
      secondary: LudoGlobalColors.gold,
      surface: LudoGlobalColors.surface,
      error: LudoGlobalColors.red,
      onPrimary: Colors.white,
      onSecondary: Color(0xFF1A2740),
      onSurface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: LudoGlobalColors.backgroundDeep,
      fontFamily: null,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          color: LudoGlobalColors.textPrimary,
        ),
        bodySmall: TextStyle(
          color: LudoGlobalColors.textSecondary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: LudoGlobalColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
