import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';
import '../../../../core/widgets/game_icon_tile.dart';
import '../../../../core/widgets/glossy_game_button.dart';

class LudoModeCard extends StatelessWidget {
  const LudoModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onPressed,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LudoGlobalSpacing.md),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(LudoGlobalRadius.large),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.32),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          GameIconTile(
            icon: icon,
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.24),
                Colors.black.withValues(alpha: 0.16),
              ],
            ),
            size: 70,
            iconSize: 38,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
              shadows: [
                Shadow(
                  color: Color(0x99000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          GlossyGameButton(
            label: 'Play Now',
            onPressed: onPressed,
            gradient: LudoGlobalGradients.gold,
          ),
        ],
      ),
    );
  }
}
