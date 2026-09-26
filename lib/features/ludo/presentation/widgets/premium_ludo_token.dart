import 'package:flutter/material.dart';

class PremiumLudoToken extends StatelessWidget {
  const PremiumLudoToken({
    required this.color,
    this.size = 30,
    this.dimmed = false,
    this.highlighted = false,
    this.onTap,
    super.key,
  });

  final Color color;
  final double size;
  final bool dimmed;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final HSLColor hsl = HSLColor.fromColor(color);
    final Color highlight = hsl
        .withLightness(
          (hsl.lightness + 0.25).clamp(0.0, 1.0).toDouble(),
        )
        .toColor();
    final Color shadow = hsl
        .withLightness(
          (hsl.lightness - 0.18).clamp(0.0, 1.0).toDouble(),
        )
        .toColor();

    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: highlighted ? 'Movable Ludo token' : 'Ludo token',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: highlighted ? 1.12 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: Opacity(
            opacity: dimmed ? 0.28 : 1,
            child: SizedBox(
              width: size,
              height: size * 1.15,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  if (highlighted)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.78),
                              blurRadius: size * 0.65,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    width: size * 0.92,
                    height: size * 0.3,
                    decoration: BoxDecoration(
                      color: shadow.withValues(alpha: 0.48),
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(size, size * 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.38),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: size * 0.12,
                    child: Container(
                      width: size * 0.72,
                      height: size * 0.72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.35, -0.45),
                          colors: [
                            highlight,
                            color,
                            shadow,
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: highlighted ? 0.95 : 0.65,
                          ),
                          width: highlighted ? 2 : 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Align(
                        alignment: const Alignment(-0.35, -0.45),
                        child: Container(
                          width: size * 0.14,
                          height: size * 0.14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.66),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
