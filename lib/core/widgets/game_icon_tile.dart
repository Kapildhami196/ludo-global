import 'package:flutter/material.dart';

import '../theme/ludo_global_tokens.dart';

class GameIconTile extends StatelessWidget {
  const GameIconTile({
    required this.icon,
    required this.gradient,
    this.size = 56,
    this.iconSize = 28,
    super.key,
  });

  final IconData icon;
  final Gradient gradient;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: LudoGlobalColors.electricBlue.withValues(alpha: 0.26),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
          const BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 5,
            left: 8,
            right: 8,
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Center(
            child: Icon(
              icon,
              size: iconSize,
              color: Colors.white,
              shadows: const [
                Shadow(
                  blurRadius: 8,
                  color: Color(0x99000000),
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
