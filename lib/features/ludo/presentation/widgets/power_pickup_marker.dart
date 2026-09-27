import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/game_asset_paths.dart';
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

  Color get _glowColor => switch (type) {
        PowerType.doubleDistance => LudoGlobalColors.red,
        PowerType.shield => LudoGlobalColors.electricBlue,
        PowerType.diceControl => LudoGlobalColors.purple,
        PowerType.bonusRoll => LudoGlobalColors.gold,
      };

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.62, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: scale.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.24),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _glowColor.withValues(alpha: 0.68),
                blurRadius: size * 0.52,
                spreadRadius: size * 0.04,
              ),
              BoxShadow(
                color: const Color(0x99000000),
                blurRadius: size * 0.20,
                offset: Offset(0, size * 0.10),
              ),
            ],
          ),
          child: SvgPicture.asset(
            GameAssetPaths.powerFor(type),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
