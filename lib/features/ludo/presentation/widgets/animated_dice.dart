import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';

class AnimatedDice extends StatefulWidget {
  const AnimatedDice({
    required this.value,
    required this.enabled,
    required this.rolling,
    required this.onTap,
    this.accentColor = LudoGlobalColors.electricBlue,
    super.key,
  });

  final int value;
  final bool enabled;
  final bool rolling;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  State<AnimatedDice> createState() => _AnimatedDiceState();
}

class _AnimatedDiceState extends State<AnimatedDice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void initState() {
    super.initState();
    if (widget.rolling) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedDice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rolling && !oldWidget.rolling) {
      _controller.repeat();
    } else if (!widget.rolling && oldWidget.rolling) {
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: 'Roll dice',
      child: GestureDetector(
        key: const Key('roll_dice_button'),
        onTap: widget.enabled ? widget.onTap : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: widget.enabled || widget.rolling ? 1 : 0.46,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double t = _controller.value;
              final double angle = widget.rolling
                  ? (t * math.pi * 4) - 0.10
                  : -0.10;
              final double jump = widget.rolling
                  ? -math.sin(t * math.pi * 2).abs() * 10
                  : 0;
              final double scale = widget.rolling
                  ? 0.93 + (math.sin(t * math.pi).abs() * 0.12)
                  : 1;

              return Transform.translate(
                offset: Offset(0, jump),
                child: Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: angle,
                    child: child,
                  ),
                ),
              );
            },
            child: SizedBox.square(
              dimension: 88,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 60,
                      height: 15,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x99000000),
                            blurRadius: 13,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: <Color>[
                          widget.accentColor.withValues(alpha: 0.22),
                          widget.accentColor.withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                        stops: const <double>[0.35, 0.68, 1],
                      ),
                      border: Border.all(
                        color: widget.accentColor.withValues(
                          alpha: widget.enabled || widget.rolling
                              ? 0.88
                              : 0.28,
                        ),
                        width: 2.2,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: widget.accentColor.withValues(
                            alpha: widget.enabled || widget.rolling
                                ? 0.62
                                : 0.14,
                          ),
                          blurRadius: widget.rolling ? 24 : 18,
                          spreadRadius: widget.rolling ? 3 : 1,
                        ),
                      ],
                    ),
                  ),
                  _DiceFace(
                    value: widget.value,
                    rolling: widget.rolling,
                    tick: _controller,
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

class _DiceFace extends StatelessWidget {
  const _DiceFace({
    required this.value,
    required this.rolling,
    required this.tick,
  });

  final int value;
  final bool rolling;
  final Animation<double> tick;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: tick,
      builder: (context, _) {
        final int previewValue = rolling
            ? ((tick.value * 19).floor() % 6) + 1
            : value.clamp(1, 6).toInt();

        return CustomPaint(
          size: const Size.square(58),
          painter: _ThreeDDicePainter(value: previewValue),
        );
      },
    );
  }
}

class _ThreeDDicePainter extends CustomPainter {
  const _ThreeDDicePainter({required this.value});

  final int value;

  static const List<Alignment> _spots = <Alignment>[
    Alignment(-0.56, -0.56),
    Alignment(0, -0.56),
    Alignment(0.56, -0.56),
    Alignment(-0.56, 0),
    Alignment.center,
    Alignment(0.56, 0),
    Alignment(-0.56, 0.56),
    Alignment(0, 0.56),
    Alignment(0.56, 0.56),
  ];

  static const Map<int, List<int>> _faceMap = <int, List<int>>{
    1: <int>[4],
    2: <int>[0, 8],
    3: <int>[0, 4, 8],
    4: <int>[0, 2, 6, 8],
    5: <int>[0, 2, 4, 6, 8],
    6: <int>[0, 2, 3, 5, 6, 8],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final Rect shadowRect = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.10,
      size.width * 0.88,
      size.height * 0.88,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        shadowRect,
        Radius.circular(size.width * 0.18),
      ),
      Paint()
        ..color = const Color(0xAA001126)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          5,
        ),
    );

    final Rect faceRect = Rect.fromLTWH(
      size.width * 0.03,
      size.height * 0.02,
      size.width * 0.88,
      size.height * 0.88,
    );
    final RRect face = RRect.fromRectAndRadius(
      faceRect,
      Radius.circular(size.width * 0.18),
    );

    canvas.drawRRect(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFF7FBFF),
            Color(0xFFD9E5F0),
            Color(0xFFB5C8D9),
          ],
          stops: <double>[0, 0.46, 0.78, 1],
        ).createShader(faceRect),
    );

    canvas.drawRRect(
      face,
      Paint()
        ..color = const Color(0xFF8EA9C1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    final Path lowerBevel = Path()
      ..moveTo(faceRect.left + size.width * 0.10, faceRect.bottom)
      ..lineTo(faceRect.right - size.width * 0.10, faceRect.bottom)
      ..quadraticBezierTo(
        faceRect.right,
        faceRect.bottom,
        faceRect.right,
        faceRect.bottom - size.height * 0.10,
      );
    canvas.drawPath(
      lowerBevel,
      Paint()
        ..color = const Color(0x778298AB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.055
        ..strokeCap = StrokeCap.round,
    );

    final Path shine = Path()
      ..moveTo(faceRect.left + size.width * 0.12, faceRect.top + size.height * 0.08)
      ..quadraticBezierTo(
        faceRect.left + size.width * 0.34,
        faceRect.top,
        faceRect.right - size.width * 0.14,
        faceRect.top + size.height * 0.06,
      );
    canvas.drawPath(
      shine,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    final Paint pipShadow = Paint()..color = const Color(0x88000000);
    final Paint pipPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        colors: <Color>[
          Color(0xFF284866),
          Color(0xFF071A30),
          Color(0xFF020A14),
        ],
      ).createShader(faceRect);

    final double faceSide = faceRect.width;
    for (final int index in _faceMap[value] ?? const <int>[4]) {
      final Alignment spot = _spots[index];
      final Offset center = Offset(
        faceRect.left + faceSide * (spot.x + 1) / 2,
        faceRect.top + faceSide * (spot.y + 1) / 2,
      );
      final double radius = size.width * 0.068;
      canvas.drawCircle(
        center.translate(0.8, 1.1),
        radius * 1.05,
        pipShadow,
      );
      canvas.drawCircle(center, radius, pipPaint);
      canvas.drawCircle(
        center.translate(-radius * 0.24, -radius * 0.28),
        radius * 0.20,
        Paint()..color = Colors.white.withValues(alpha: 0.34),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ThreeDDicePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
