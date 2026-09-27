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
    this.size = 88,
    this.compact = false,
    this.launchDirection = Offset.zero,
    super.key,
  });

  final int value;
  final bool enabled;
  final bool rolling;
  final VoidCallback onTap;
  final Color accentColor;
  final double size;
  final bool compact;
  final Offset launchDirection;

  @override
  State<AnimatedDice> createState() => _AnimatedDiceState();
}

class _AnimatedDiceState extends State<AnimatedDice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  bool _settling = false;
  int _settleSequence = 0;

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
      _settling = false;
      _settleSequence++;
      _controller
        ..stop()
        ..duration = const Duration(milliseconds: 650)
        ..repeat();
      return;
    }

    if (!widget.rolling && oldWidget.rolling) {
      final int sequence = ++_settleSequence;
      _settling = true;
      _controller
        ..stop()
        ..duration = const Duration(milliseconds: 800);

      _controller.forward(from: 0).whenComplete(() {
        if (!mounted ||
            sequence != _settleSequence ||
            widget.rolling) {
          return;
        }
        setState(() {
          _settling = false;
          _controller.reset();
        });
      });
    }
  }

  @override
  void dispose() {
    _settleSequence++;
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
          duration: const Duration(milliseconds: 150),
          opacity:
              widget.enabled || widget.rolling || _settling ? 1 : 0.74,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final double t = _controller.value;

              double travel = 0;
              double scale = 1;
              double xRotation = 0;
              int previewValue = widget.value.clamp(1, 6).toInt();

              if (widget.rolling) {
                // Front-face-only vertical tumble. Each half turn swaps to
                // the next front face, so the fallback never reveals fake
                // top/right artwork or a mirrored back face.
                const int halfTurnsPerCycle = 8;
                final double halfTurnProgress =
                    t * halfTurnsPerCycle;
                final int halfTurnIndex =
                    halfTurnProgress.floor();
                final double local =
                    halfTurnProgress - halfTurnIndex;

                previewValue = (halfTurnIndex % 6) + 1;

                // First half of each step tips away to an edge; the next
                // front face enters from the opposite edge and lands flat.
                xRotation = local < 0.5
                    ? local * math.pi
                    : (local - 1) * math.pi;

                // One clean vertical hop for the full roll cycle.
                travel = math.sin(t * math.pi).abs();
                scale = 1 + travel * 0.14;
              } else if (_settling) {
                final double bounceWindow =
                    (t / 0.20).clamp(0.0, 1.0).toDouble();
                final double bounce =
                    math.sin(bounceWindow * math.pi).abs();
                scale = 1 + bounce * 0.06;
                xRotation = -bounce * 0.055;
              }

              final double verticalOffset =
                  -travel * widget.size * 0.27;

              final Matrix4 transform = Matrix4.identity()
                ..setEntry(3, 2, 0.0028)
                ..rotateX(xRotation);

              return Transform.translate(
                offset: Offset(0, verticalOffset),
                child: Transform.scale(
                  scale: scale,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: transform,
                    child: _FlatDiceFace(
                      value: previewValue,
                      size: widget.size,
                      accentColor: widget.accentColor,
                      active: widget.enabled ||
                          widget.rolling ||
                          _settling,
                      travel: travel,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FlatDiceFace extends StatelessWidget {
  const _FlatDiceFace({
    required this.value,
    required this.size,
    required this.accentColor,
    required this.active,
    required this.travel,
  });

  final int value;
  final double size;
  final Color accentColor;
  final bool active;
  final double travel;

  @override
  Widget build(BuildContext context) {
    final double faceSize = size * 0.80;
    final double shadowWidth =
        size * (0.68 - travel * 0.12);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            bottom: size * 0.06,
            child: Container(
              width: shadowWidth,
              height: size * 0.075,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.30 - travel * 0.10,
                    ),
                    blurRadius: size * 0.11,
                    offset: Offset(0, size * 0.035),
                  ),
                ],
              ),
            ),
          ),
          if (active)
            Container(
              width: faceSize * 1.06,
              height: faceSize * 1.06,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.18),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.10),
                    blurRadius: size * 0.15,
                    spreadRadius: size * 0.006,
                  ),
                ],
              ),
            ),
          Container(
            width: faceSize,
            height: faceSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFFFFFFFF),
                  Color(0xFFF7F9FC),
                  Color(0xFFDCE4EC),
                ],
                stops: <double>[0, 0.58, 1],
              ),
              border: Border.all(
                color: const Color(0xFF95A5B4),
                width: math.max(1.4, size * 0.018),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.72),
                  blurRadius: size * 0.04,
                  offset: Offset(
                    -size * 0.018,
                    -size * 0.018,
                  ),
                ),
                BoxShadow(
                  color: const Color(0xFF637383)
                      .withValues(alpha: 0.24),
                  blurRadius: size * 0.075,
                  offset: Offset(0, size * 0.045),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _FrontPipsPainter(value: value),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrontPipsPainter extends CustomPainter {
  const _FrontPipsPainter({
    required this.value,
  });

  final int value;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.shortestSide * 0.075;
    final Paint pipPaint = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[
          Color(0xFF315672),
          Color(0xFF081827),
          Color(0xFF02070D),
        ],
        stops: <double>[0, 0.58, 1],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.45, size.height * 0.42),
          radius: size.shortestSide * 0.12,
        ),
      );

    for (final Offset point in _pipLayout(value)) {
      final Offset center = Offset(
        size.width * point.dx,
        size.height * point.dy,
      );
      canvas.drawCircle(center, radius, pipPaint);

      canvas.drawCircle(
        center.translate(
          -radius * 0.22,
          -radius * 0.24,
        ),
        radius * 0.24,
        Paint()
          ..color = const Color(0xFF7FA1BC)
              .withValues(alpha: 0.36),
      );
    }
  }

  List<Offset> _pipLayout(int value) {
    const double low = 0.27;
    const double mid = 0.50;
    const double high = 0.73;

    return switch (value) {
      1 => const <Offset>[Offset(mid, mid)],
      2 => const <Offset>[
          Offset(low, low),
          Offset(high, high),
        ],
      3 => const <Offset>[
          Offset(low, low),
          Offset(mid, mid),
          Offset(high, high),
        ],
      4 => const <Offset>[
          Offset(low, low),
          Offset(high, low),
          Offset(low, high),
          Offset(high, high),
        ],
      5 => const <Offset>[
          Offset(low, low),
          Offset(high, low),
          Offset(mid, mid),
          Offset(low, high),
          Offset(high, high),
        ],
      6 => const <Offset>[
          Offset(low, low),
          Offset(high, low),
          Offset(low, mid),
          Offset(high, mid),
          Offset(low, high),
          Offset(high, high),
        ],
      _ => const <Offset>[Offset(mid, mid)],
    };
  }

  @override
  bool shouldRepaint(covariant _FrontPipsPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
