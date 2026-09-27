import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';
import '../../domain/entities/player_color.dart';

/// Presentation-only visual tokens for the reference gameplay board.
///
/// The board now keeps the engine's natural color orientation:
/// red top-left, green top-right, yellow bottom-right, blue bottom-left.
abstract final class LudoReferenceVisuals {
  static PlayerColor displayColorFor(PlayerColor engineColor) => engineColor;

  static Color colorFor(PlayerColor engineColor) {
    return switch (engineColor) {
      PlayerColor.red => const Color(0xFFD7353A),
      PlayerColor.green => const Color(0xFF19B746),
      PlayerColor.yellow => const Color(0xFFE5B80B),
      PlayerColor.blue => const Color(0xFF2A9FDE),
    };
  }

  static Color darkColorFor(PlayerColor engineColor) {
    return switch (engineColor) {
      PlayerColor.red => const Color(0xFF981E25),
      PlayerColor.green => const Color(0xFF087A2E),
      PlayerColor.yellow => const Color(0xFFA97700),
      PlayerColor.blue => const Color(0xFF0B6CA9),
    };
  }

  static Color softColorFor(PlayerColor engineColor) {
    return switch (engineColor) {
      PlayerColor.red => const Color(0xFFE9575A),
      PlayerColor.green => const Color(0xFF43D66C),
      PlayerColor.yellow => const Color(0xFFF2D33B),
      PlayerColor.blue => const Color(0xFF5CC2EE),
    };
  }

  static Color legacyColorFor(PlayerColor engineColor) {
    return switch (engineColor) {
      PlayerColor.red => LudoGlobalColors.red,
      PlayerColor.green => LudoGlobalColors.green,
      PlayerColor.yellow => LudoGlobalColors.gold,
      PlayerColor.blue => LudoGlobalColors.electricBlue,
    };
  }
}
