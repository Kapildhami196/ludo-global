import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/game_asset_paths.dart';
import '../../../../core/theme/ludo_global_tokens.dart';
import '../../domain/entities/player_color.dart';
import 'animated_dice.dart';

class PlayerDiceSlot extends StatelessWidget {
  const PlayerDiceSlot({
    required this.color,
    required this.active,
    required this.value,
    required this.rolling,
    required this.enabled,
    required this.onRoll,
    required this.size,
    super.key,
  });

  final PlayerColor color;
  final bool active;
  final int value;
  final bool rolling;
  final bool enabled;
  final VoidCallback onRoll;
  final double size;

  Color get _accentColor => switch (color) {
        PlayerColor.red => LudoGlobalColors.red,
        PlayerColor.green => LudoGlobalColors.green,
        PlayerColor.yellow => LudoGlobalColors.gold,
        PlayerColor.blue => LudoGlobalColors.electricBlue,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      scale: active ? 1 : 0.82,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: active ? 1 : 0.46,
        child: Container(
          padding: EdgeInsets.all(size * 0.08),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xCC061127),
            border: Border.all(
              color: _accentColor.withValues(
                alpha: active ? 0.95 : 0.30,
              ),
              width: active ? 1.6 : 0.9,
            ),
            boxShadow: <BoxShadow>[
              if (active)
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.42),
                  blurRadius: size * 0.42,
                  spreadRadius: 1,
                ),
              const BoxShadow(
                color: Color(0x66000000),
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: active
              ? AnimatedDice(
                  value: value,
                  enabled: enabled,
                  rolling: rolling,
                  onTap: onRoll,
                  accentColor: _accentColor,
                  size: size,
                  compact: true,
                )
              : IgnorePointer(
                  child: Opacity(
                    opacity: 0.52,
                    child: SvgPicture.asset(
                      GameAssetPaths.dice1,
                      width: size * 0.66,
                      height: size * 0.66,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
