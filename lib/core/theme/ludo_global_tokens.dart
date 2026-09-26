import 'package:flutter/material.dart';

abstract final class LudoGlobalColors {
  static const Color background = Color(0xFF06152E);
  static const Color backgroundDeep = Color(0xFF031024);
  static const Color surface = Color(0xFF0A2A52);
  static const Color surfaceBright = Color(0xFF0E3C73);
  static const Color border = Color(0xFF2769A8);
  static const Color electricBlue = Color(0xFF159CFF);
  static const Color royalBlue = Color(0xFF0A67F5);
  static const Color cyan = Color(0xFF26D9FF);
  static const Color gold = Color(0xFFFFC93D);
  static const Color orange = Color(0xFFFF7A1A);
  static const Color red = Color(0xFFF33F52);
  static const Color green = Color(0xFF21D367);
  static const Color purple = Color(0xFF9B4DFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB7C9E6);
}

abstract final class LudoGlobalRadius {
  static const double small = 12;
  static const double medium = 18;
  static const double large = 26;
  static const double pill = 999;
}

abstract final class LudoGlobalSpacing {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class LudoGlobalGradients {
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      LudoGlobalColors.background,
      LudoGlobalColors.backgroundDeep,
    ],
  );

  static const LinearGradient normal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF1AA7FF),
      Color(0xFF0754D4),
    ],
  );

  static const LinearGradient power = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFFF622E),
      Color(0xFFCB153E),
    ],
  );

  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFFFE46B),
      Color(0xFFFFA31A),
    ],
  );
}
