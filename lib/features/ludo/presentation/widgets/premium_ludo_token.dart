import 'package:flutter/material.dart';

class PremiumLudoToken extends StatelessWidget {
  const PremiumLudoToken({
    required this.color,
    this.size = 30,
    this.dimmed = false,
    super.key,
  });

  final Color color;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final HSLColor hsl = HSLColor.fromColor(color);
    final Color highlight = hsl
        .withLightness((hsl.lightness + 0.25).clamp(0.0, 1.0).toDouble())
        .toColor();
    final Color shadow = hsl
        .withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0).toDouble())
        .toColor();

    return Opacity(
      opacity: dimmed ? 0.28 : 1,
      child: SizedBox(
        width: size,
        height: size * 1.15,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
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
                    color: Colors.white.withValues(alpha: 0.65),
                    width: 1.2,
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
    );
  }
}
