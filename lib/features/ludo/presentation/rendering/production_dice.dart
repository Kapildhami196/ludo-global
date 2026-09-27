import 'package:flutter/material.dart';

import '../widgets/animated_dice.dart';
import 'flame_dice_3d.dart';
import 'ludo_renderer_capabilities.dart';

class ProductionDice extends StatelessWidget {
  const ProductionDice({
    required this.value,
    required this.enabled,
    required this.rolling,
    required this.onTap,
    required this.accentColor,
    required this.size,
    required this.launchDirection,
    super.key,
  });

  final int value;
  final bool enabled;
  final bool rolling;
  final VoidCallback onTap;
  final Color accentColor;
  final double size;
  final Offset launchDirection;

  @override
  Widget build(BuildContext context) {
    if (!LudoRendererCapabilities.supportsFlame3D) {
      return AnimatedDice(
        value: value,
        enabled: enabled,
        rolling: rolling,
        onTap: onTap,
        accentColor: accentColor,
        size: size,
        compact: true,
        launchDirection: launchDirection,
      );
    }

    return FlameDice3D(
      value: value,
      enabled: enabled,
      rolling: rolling,
      onTap: onTap,
      accentColor: accentColor,
      size: size,
      launchDirection: launchDirection,
    );
  }
}
