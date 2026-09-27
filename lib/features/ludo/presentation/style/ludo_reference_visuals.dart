import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';
import '../../domain/entities/player_color.dart';

/// Presentation-only color mapping used to match the reference board orientation
/// without changing the game engine's path/rules.
abstract final class LudoReferenceVisuals {
  static PlayerColor displayColorFor(PlayerColor engineColor) {
    return switch (engineColor) {
      PlayerColor.red => PlayerColor.yellow,
      PlayerColor.green => PlayerColor.blue,
      PlayerColor.yellow => PlayerColor.red,
      PlayerColor.blue => PlayerColor.green,
    };
  }

  static Color colorFor(PlayerColor engineColor) {
    return switch (displayColorFor(engineColor)) {
      PlayerColor.red => const Color(0xFFE84335),
      PlayerColor.green => const Color(0xFF17B954),
      PlayerColor.yellow => const Color(0xFFFFD20B),
      PlayerColor.blue => const Color(0xFF19A8E6),
    };
  }

  static Color darkColorFor(PlayerColor engineColor) {
    return switch (displayColorFor(engineColor)) {
      PlayerColor.red => const Color(0xFF9E261E),
      PlayerColor.green => const Color(0xFF087A36),
      PlayerColor.yellow => const Color(0xFFBE8E00),
      PlayerColor.blue => const Color(0xFF0677B4),
    };
  }

  static Color softColorFor(PlayerColor engineColor) {
    return switch (displayColorFor(engineColor)) {
      PlayerColor.red => const Color(0xFFF1786F),
      PlayerColor.green => const Color(0xFF48DE81),
      PlayerColor.yellow => const Color(0xFFFFE552),
      PlayerColor.blue => const Color(0xFF62D4FF),
    };
  }

  static Color legacyColorFor(PlayerColor engineColor) {
    return switch (displayColorFor(engineColor)) {
      PlayerColor.red => LudoGlobalColors.red,
      PlayerColor.green => LudoGlobalColors.green,
      PlayerColor.yellow => LudoGlobalColors.gold,
      PlayerColor.blue => LudoGlobalColors.electricBlue,
    };
  }
}
