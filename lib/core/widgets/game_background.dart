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
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GameAtmospherePainter(),
              ),
            ),
          ),
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
            colors: <Color>[
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameAtmospherePainter extends CustomPainter {
  const _GameAtmospherePainter();

  static const List<Offset> _sparkles = <Offset>[
    Offset(0.08, 0.14),
    Offset(0.19, 0.30),
    Offset(0.31, 0.09),
    Offset(0.42, 0.24),
    Offset(0.55, 0.12),
    Offset(0.69, 0.28),
    Offset(0.83, 0.17),
    Offset(0.93, 0.35),
    Offset(0.12, 0.55),
    Offset(0.26, 0.72),
    Offset(0.39, 0.48),
    Offset(0.57, 0.66),
    Offset(0.72, 0.52),
    Offset(0.87, 0.76),
    Offset(0.17, 0.88),
    Offset(0.48, 0.90),
    Offset(0.77, 0.91),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset source = Offset(size.width * 0.5, -size.height * 0.08);

    for (int index = 0; index < 5; index++) {
      final double spread = size.width * (0.18 + index * 0.09);
      final Path beam = Path()
        ..moveTo(source.dx - size.width * 0.03, source.dy)
        ..lineTo(size.width * 0.5 - spread, size.height)
        ..lineTo(size.width * 0.5 + spread * 0.32, size.height)
        ..lineTo(source.dx + size.width * 0.03, source.dy)
        ..close();

      canvas.drawPath(
        beam,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              const Color(0xFF2A8FFF).withValues(
                alpha: 0.075 - index * 0.009,
              ),
              Colors.transparent,
            ],
          ).createShader(Offset.zero & size),
      );
    }

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.22),
      size.width * 0.44,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFF147CFF).withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.5, size.height * 0.22),
            radius: size.width * 0.44,
          ),
        ),
    );

    for (int index = 0; index < _sparkles.length; index++) {
      final Offset point = Offset(
        _sparkles[index].dx * size.width,
        _sparkles[index].dy * size.height,
      );
      final double radius = index.isEven ? 1.35 : 0.85;
      final Color color = index % 4 == 0
          ? LudoGlobalColors.gold
          : LudoGlobalColors.cyan;

      canvas.drawCircle(
        point,
        radius * 3.2,
        Paint()
          ..color = color.withValues(alpha: 0.08)
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            4,
          ),
      );
      canvas.drawCircle(
        point,
        radius,
        Paint()..color = color.withValues(alpha: 0.50),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GameAtmospherePainter oldDelegate) => false;
}
