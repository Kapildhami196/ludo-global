import 'package:flutter/material.dart';

import '../theme/ludo_global_tokens.dart';

class GameBackground extends StatelessWidget {
  const GameBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LudoGlobalGradients.background,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: -90,
            right: -70,
            child: _GlowOrb(
              size: 220,
              color: LudoGlobalColors.electricBlue,
            ),
          ),
          const Positioned(
            bottom: 20,
            left: -100,
            child: _GlowOrb(
              size: 240,
              color: LudoGlobalColors.purple,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
