import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/game_asset_paths.dart';
import '../../domain/entities/ludo_player.dart';
import '../style/ludo_reference_visuals.dart';

class PlayerGamePanel extends StatelessWidget {
  const PlayerGamePanel({
    required this.player,
    required this.active,
    this.isComputer = false,
    this.consecutiveSixes = 0,
    this.alignRight = false,
    this.size = 68,
    super.key,
  });

  final LudoPlayer player;
  final bool active;
  final bool isComputer;
  final int consecutiveSixes;
  final bool alignRight;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color color = LudoReferenceVisuals.colorFor(player.color);
    final Color dark = LudoReferenceVisuals.darkColorFor(player.color);
    final displayColor =
        LudoReferenceVisuals.displayColorFor(player.color);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: size,
            height: size,
            padding: EdgeInsets.all(size * 0.09),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF4F6F8),
              border: Border.all(
                color: active ? color : dark,
                width: active ? size * 0.055 : size * 0.042,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: size * 0.11,
                  offset: Offset(0, size * 0.05),
                ),
                if (active)
                  BoxShadow(
                    color: color.withValues(alpha: 0.36),
                    blurRadius: size * 0.18,
                    spreadRadius: size * 0.015,
                  ),
              ],
            ),
            child: Container(
              padding: EdgeInsets.all(size * 0.11),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.25, -0.30),
                  colors: <Color>[
                    Colors.white,
                    color.withValues(alpha: 0.16),
                  ],
                ),
              ),
              child: SvgPicture.asset(
                GameAssetPaths.pawnFor(displayColor),
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (isComputer)
            Positioned(
              right: -size * 0.02,
              top: -size * 0.02,
              child: Container(
                width: size * 0.31,
                height: size * 0.31,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF262653),
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: size * 0.18,
                ),
              ),
            ),
          if (active && consecutiveSixes > 0)
            Positioned(
              left: -size * 0.02,
              bottom: -size * 0.02,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size * 0.09,
                  vertical: size * 0.035,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color, width: 1),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Text(
                  '6×$consecutiveSixes',
                  style: TextStyle(
                    color: dark,
                    fontSize: size * 0.12,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
