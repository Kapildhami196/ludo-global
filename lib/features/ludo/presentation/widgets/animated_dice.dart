import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/game_asset_paths.dart';
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
              double yRotation = 0;
              double zRotation = -0.018;
              int previewValue = widget.value.clamp(1, 6).toInt();

              if (widget.rolling) {
                // A real-feeling vertical cube roll: six half-turns over one
                // roll cycle. The visible front face advances 1→6 as the cube
                // turns over its horizontal axis instead of orbiting in a
                // flat circle.
                final int faceIndex =
                    (t * 6).floor().clamp(0, 5);
                previewValue = faceIndex + 1;

                xRotation = t * math.pi * 12;
                yRotation =
                    math.sin(t * math.pi * 4) * 0.10;
                zRotation =
                    math.sin(t * math.pi * 2) * 0.035;

                travel = math.sin(t * math.pi).abs();
                scale = 1 + travel * 0.86;
              } else if (_settling) {
                // Keep the actual result clearly visible for the 800ms settle
                // window, with only a small physical landing bounce.
                final double bounceWindow =
                    (t / 0.20).clamp(0.0, 1.0).toDouble();
                final double bounce =
                    math.sin(bounceWindow * math.pi).abs();
                scale = 1 + bounce * 0.07;
                xRotation = -bounce * 0.05;
                zRotation = -0.018 + bounce * 0.025;
              }

              final Offset launchOffset = Offset(
                widget.launchDirection.dx * widget.size * travel,
                widget.launchDirection.dy * widget.size * travel,
              );
              final double arc =
                  -travel * widget.size * 0.17;

              final Matrix4 transform = Matrix4.identity()
                ..setEntry(3, 2, 0.0024)
                ..rotateX(xRotation)
                ..rotateY(yRotation)
                ..rotateZ(zRotation);

              final int topValue =
                  ((previewValue + 1) % 6) + 1;
              final int sideValue =
                  ((previewValue + 3) % 6) + 1;

              return Transform.translate(
                offset: launchOffset.translate(0, arc),
                child: Transform.scale(
                  scale: scale,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: transform,
                    child: _DiceFace(
                      value: previewValue,
                      topValue: topValue,
                      sideValue: sideValue,
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

class _DiceFace extends StatelessWidget {
  const _DiceFace({
    required this.value,
    required this.topValue,
    required this.sideValue,
    required this.size,
    required this.accentColor,
    required this.active,
    required this.travel,
  });

  final int value;
  final int topValue;
  final int sideValue;
  final double size;
  final Color accentColor;
  final bool active;
  final double travel;

  @override
  Widget build(BuildContext context) {
    final double faceSize = size * 0.94;
    final double shadowWidth =
        size * (0.78 - travel * 0.14);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: size * 0.01,
            child: Container(
              width: shadowWidth,
              height: size * 0.10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.32 - travel * 0.12,
                    ),
                    blurRadius: size * 0.13,
                    offset: Offset(
                      size * 0.02,
                      size * 0.035,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (active)
            Container(
              width: size * 0.92,
              height: size * 0.92,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.20),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.10),
                    blurRadius: size * 0.16,
                    spreadRadius: size * 0.004,
                  ),
                ],
              ),
            ),
          SizedBox.square(
            dimension: faceSize,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SvgPicture.asset(
                  GameAssetPaths.diceFor(value),
                  fit: BoxFit.contain,
                ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: _DiceSidePipsPainter(
                      topValue: topValue,
                      sideValue: sideValue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiceSidePipsPainter extends CustomPainter {
  const _DiceSidePipsPainter({
    required this.topValue,
    required this.sideValue,
  });

  final int topValue;
  final int sideValue;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pipPaint = Paint()
      ..color = const Color(0xFF081827);

    for (final Offset p in _pipLayout(topValue)) {
      final Offset point = Offset(
        size.width * (0.24 + p.dx * 0.50 + p.dy * 0.055),
        size.height * (0.105 + p.dy * 0.115 - p.dx * 0.015),
      );
      canvas.drawCircle(
        point,
        size.shortestSide * 0.020,
        pipPaint,
      );
    }

    for (final Offset p in _pipLayout(sideValue)) {
      final Offset point = Offset(
        size.width * (0.795 + p.dx * 0.075 + p.dy * 0.018),
        size.height * (0.255 + p.dy * 0.43 + p.dx * 0.015),
      );
      canvas.drawCircle(
        point,
        size.shortestSide * 0.017,
        pipPaint,
      );
    }
  }

  List<Offset> _pipLayout(int value) {
    const double low = 0.22;
    const double mid = 0.50;
    const double high = 0.78;

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
  bool shouldRepaint(covariant _DiceSidePipsPainter oldDelegate) {
    return oldDelegate.topValue != topValue ||
        oldDelegate.sideValue != sideValue;
  }
}
