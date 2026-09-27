import 'dart:math' as math;

import 'package:flutter/material.dart';

class PremiumLudoToken extends StatefulWidget {
  const PremiumLudoToken({
    required this.color,
    this.size = 30,
    this.dimmed = false,
    this.highlighted = false,
    this.moving = false,
    this.captured = false,
    this.shielded = false,
    this.onTap,
    super.key,
  });

  final Color color;
  final double size;
  final bool dimmed;
  final bool highlighted;
  final bool moving;
  final bool captured;
  final bool shielded;
  final VoidCallback? onTap;

  @override
  State<PremiumLudoToken> createState() => _PremiumLudoTokenState();
}

class _PremiumLudoTokenState extends State<PremiumLudoToken>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  @override
  void initState() {
    super.initState();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant PremiumLudoToken oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moving != widget.moving ||
        oldWidget.captured != widget.captured) {
      _syncMotion();
    }
  }

  void _syncMotion() {
    if (widget.captured) {
      _controller
        ..duration = const Duration(milliseconds: 430)
        ..forward(from: 0);
      return;
    }

    if (widget.moving) {
      _controller
        ..duration = const Duration(milliseconds: 180)
        ..repeat();
      return;
    }

    _controller
      ..stop()
      ..reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      enabled: widget.onTap != null,
      label: widget.highlighted ? 'Movable Ludo token' : 'Ludo token',
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double t = _controller.value;
            final double hop = widget.moving
                ? -math.sin(t * math.pi).abs() * 7
                : 0;
            final double shake = widget.captured
                ? math.sin(t * math.pi * 9) * 5 * (1 - t)
                : 0;
            final double captureScale = widget.captured
                ? 1 - (0.24 * Curves.easeIn.transform(t))
                : 1;

            return Transform.translate(
              offset: Offset(shake, hop),
              child: Transform.scale(
                scale: captureScale,
                child: child,
              ),
            );
          },
          child: AnimatedScale(
            scale: widget.highlighted ? 1.13 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: Opacity(
              opacity: widget.dimmed ? 0.28 : 1,
              child: SizedBox(
                width: widget.size,
                height: widget.size * 1.34,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PawnPainter(
                          color: widget.color,
                          highlighted: widget.highlighted,
                          shielded: widget.shielded,
                        ),
                      ),
                    ),
                    if (widget.shielded)
                      Positioned(
                        right: -widget.size * 0.08,
                        top: widget.size * 0.02,
                        child: Container(
                          width: widget.size * 0.38,
                          height: widget.size * 0.38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                Color(0xFF4CEBFF),
                                Color(0xFF0876E8),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white,
                              width: 1,
                            ),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0xAA00C8FF),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.shield_rounded,
                            size: widget.size * 0.22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PawnPainter extends CustomPainter {
  const _PawnPainter({
    required this.color,
    required this.highlighted,
    required this.shielded,
  });

  final Color color;
  final bool highlighted;
  final bool shielded;

  @override
  void paint(Canvas canvas, Size size) {
    final HSLColor hsl = HSLColor.fromColor(color);
    final Color light = hsl
        .withLightness((hsl.lightness + 0.24).clamp(0.0, 1.0))
        .toColor();
    final Color dark = hsl
        .withLightness((hsl.lightness - 0.20).clamp(0.0, 1.0))
        .toColor();
    final Color deep = hsl
        .withLightness((hsl.lightness - 0.30).clamp(0.0, 1.0))
        .toColor();

    final Rect whole = Offset.zero & size;
    final double w = size.width;
    final double h = size.height;

    if (highlighted || shielded) {
      final Color glowColor =
          shielded ? const Color(0xFF29D9FF) : color;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.72),
          width: w * 1.18,
          height: h * 0.75,
        ),
        Paint()
          ..color = glowColor.withValues(alpha: 0.20)
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            12,
          ),
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.94),
        width: w * 0.84,
        height: h * 0.14,
      ),
      Paint()
        ..color = const Color(0x77000000)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          4,
        ),
    );

    final Path body = Path()
      ..moveTo(w * 0.39, h * 0.34)
      ..quadraticBezierTo(w * 0.42, h * 0.44, w * 0.37, h * 0.52)
      ..quadraticBezierTo(w * 0.31, h * 0.64, w * 0.23, h * 0.70)
      ..quadraticBezierTo(w * 0.17, h * 0.76, w * 0.18, h * 0.84)
      ..lineTo(w * 0.82, h * 0.84)
      ..quadraticBezierTo(w * 0.83, h * 0.76, w * 0.77, h * 0.70)
      ..quadraticBezierTo(w * 0.69, h * 0.64, w * 0.63, h * 0.52)
      ..quadraticBezierTo(w * 0.58, h * 0.44, w * 0.61, h * 0.34)
      ..close();

    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-0.8, -1),
        end: const Alignment(0.9, 1),
        stops: const <double>[0, 0.42, 1],
        colors: <Color>[light, color, dark],
      ).createShader(whole);

    canvas.drawPath(body, bodyPaint);
    canvas.drawPath(
      body,
      Paint()
        ..color = deep.withValues(alpha: 0.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    final Rect base = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.84),
      width: w * 0.76,
      height: h * 0.18,
    );
    canvas.drawOval(
      base,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[light, color, deep],
        ).createShader(base),
    );
    canvas.drawOval(
      base,
      Paint()
        ..color = deep.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    final Rect head = Rect.fromCircle(
      center: Offset(w * 0.5, h * 0.24),
      radius: w * 0.19,
    );
    canvas.drawOval(
      head,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.38, -0.42),
          radius: 0.95,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.88),
            light,
            color,
            dark,
          ],
          stops: const <double>[0, 0.18, 0.58, 1],
        ).createShader(head),
    );
    canvas.drawOval(
      head,
      Paint()
        ..color = deep.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.43, h * 0.19),
        width: w * 0.10,
        height: h * 0.06,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.32, h * 0.71)
        ..quadraticBezierTo(
          w * 0.40,
          h * 0.58,
          w * 0.43,
          h * 0.44,
        ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1, w * 0.07),
    );
  }

  @override
  bool shouldRepaint(covariant _PawnPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.highlighted != highlighted ||
        oldDelegate.shielded != shielded;
  }
}
