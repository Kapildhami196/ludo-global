import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ludo_global_tokens.dart';

class GameBackground extends StatefulWidget {
  const GameBackground({
    required this.child,
    this.referencePurple = false,
    super.key,
  });

  final Widget child;
  final bool referencePurple;

  @override
  State<GameBackground> createState() => _GameBackgroundState();
}

class _GameBackgroundState extends State<GameBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Gradient backgroundGradient = widget.referencePurple
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF343A8E),
              Color(0xFF4743A2),
              Color(0xFF5847AC),
              Color(0xFF443990),
            ],
            stops: <double>[0, 0.34, 0.72, 1],
          )
        : LudoGlobalGradients.background;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: backgroundGradient,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      painter: _GameAtmospherePainter(
                        progress: _controller.value,
                        referencePurple: widget.referencePurple,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -70,
            child: _GlowOrb(
              size: 220,
              color: widget.referencePurple
                  ? const Color(0xFF796CFF)
                  : LudoGlobalColors.electricBlue,
              opacity: widget.referencePurple ? 0.10 : 0.22,
            ),
          ),
          Positioned(
            bottom: 20,
            left: -100,
            child: _GlowOrb(
              size: 240,
              color: widget.referencePurple
                  ? const Color(0xFFA34FEA)
                  : LudoGlobalColors.purple,
              opacity: widget.referencePurple ? 0.12 : 0.22,
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

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
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameAtmospherePainter extends CustomPainter {
  const _GameAtmospherePainter({
    required this.progress,
    required this.referencePurple,
  });

  final double progress;
  final bool referencePurple;

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
    final double wave = math.sin(progress * math.pi * 2);
    final Offset source = Offset(
      size.width * (0.5 + wave * 0.015),
      -size.height * 0.08,
    );

    for (int index = 0; index < 5; index++) {
      final double spread = size.width * (0.18 + index * 0.09);
      final double drift =
          math.sin(progress * math.pi * 2 + index * 0.8) * size.width * 0.025;
      final Path beam = Path()
        ..moveTo(source.dx - size.width * 0.03, source.dy)
        ..lineTo(size.width * 0.5 - spread + drift, size.height)
        ..lineTo(
          size.width * 0.5 + spread * 0.32 + drift,
          size.height,
        )
        ..lineTo(source.dx + size.width * 0.03, source.dy)
        ..close();

      canvas.drawPath(
        beam,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              (referencePurple
                      ? const Color(0xFF8A79FF)
                      : const Color(0xFF2A8FFF))
                  .withValues(
                alpha: (referencePurple ? 0.025 : 0.055) +
                    ((wave + 1) * 0.5) *
                        (referencePurple ? 0.012 : 0.025) -
                    index * 0.004,
              ),
              Colors.transparent,
            ],
          ).createShader(Offset.zero & size),
      );
    }

    final Offset haloCenter = Offset(
      size.width * 0.5,
      size.height * (0.22 + wave * 0.008),
    );
    canvas.drawCircle(
      haloCenter,
      size.width * 0.44,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            (referencePurple
                    ? const Color(0xFF7166E8)
                    : const Color(0xFF147CFF))
                .withValues(
              alpha: referencePurple
                  ? 0.045
                  : 0.08 + ((wave + 1) * 0.5) * 0.04,
            ),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: haloCenter,
            radius: size.width * 0.44,
          ),
        ),
    );

    for (int index = 0; index < _sparkles.length; index++) {
      final Offset seed = _sparkles[index];
      final double phase =
          progress * math.pi * 2 + index * 0.73;
      final Offset point = Offset(
        (seed.dx * size.width) + math.sin(phase) * 4,
        (seed.dy * size.height) + math.cos(phase * 0.82) * 5,
      );
      final double pulse =
          0.45 + (math.sin(phase * 1.7) + 1) * 0.28;
      final double radius = index.isEven ? 1.35 : 0.85;
      final Color color = index % 4 == 0
          ? LudoGlobalColors.gold
          : (referencePurple
              ? const Color(0xFF9BD4FF)
              : LudoGlobalColors.cyan);

      canvas.drawCircle(
        point,
        radius * 3.2,
        Paint()
          ..color = color.withValues(
            alpha: (referencePurple ? 0.045 : 0.08) * pulse,
          )
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            4,
          ),
      );
      canvas.drawCircle(
        point,
        radius,
        Paint()
          ..color = color.withValues(
            alpha: (referencePurple ? 0.34 : 0.55) * pulse,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GameAtmospherePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.referencePurple != referencePurple;
  }
}
