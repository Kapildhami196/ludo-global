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
          Icons.gps_fixed_rounded,
          LudoGlobalColors.purple,
        ),
      PowerType.bonusRoll => (
          Icons.add_rounded,
          LudoGlobalColors.gold,
        ),
    };

    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xF20A1730),
          border: Border.all(color: color, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.55),
              blurRadius: size * 0.45,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: size * 0.64,
          color: color,
        ),
      ),
    );
  }
}
