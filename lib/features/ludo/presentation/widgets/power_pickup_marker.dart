import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';
import '../../domain/entities/power_type.dart';

class PowerPickupMarker extends StatelessWidget {
  const PowerPickupMarker({
    required this.type,
    required this.size,
    super.key,
  });

  final PowerType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (type) {
      PowerType.doubleDistance => (
          Icons.double_arrow_rounded,
          LudoGlobalColors.red,
        ),
      PowerType.shield => (
          Icons.shield_rounded,
          LudoGlobalColors.electricBlue,
        ),
      PowerType.diceControl => (
          Icons.casino_rounded,
          LudoGlobalColors.purple,
        ),
      PowerType.bonusRoll => (
          Icons.add_rounded,
          LudoGlobalColors.gold,
        ),
    };

    final HSLColor hsl = HSLColor.fromColor(color);
    final Color light = hsl
        .withLightness(
          (hsl.lightness + 0.20).clamp(0.0, 1.0).toDouble(),
        )
        .toColor();
    final Color dark = hsl
        .withLightness(
          (hsl.lightness - 0.18).clamp(0.0, 1.0).toDouble(),
        )
        .toColor();

    return IgnorePointer(
      child: Transform.rotate(
        angle: -0.06,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                light,
                color,
                dark,
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.82),
              width: 1.1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: color.withValues(alpha: 0.78),
                blurRadius: size * 0.52,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: const Color(0x99000000),
                blurRadius: size * 0.18,
                offset: Offset(0, size * 0.10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: size * 0.13,
                right: size * 0.13,
                top: size * 0.10,
                child: Container(
                  height: size * 0.08,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Center(
                child: Icon(
                  icon,
                  size: size * 0.63,
                  color: Colors.white,
                  shadows: const <Shadow>[
                    Shadow(
                      color: Color(0x88000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
