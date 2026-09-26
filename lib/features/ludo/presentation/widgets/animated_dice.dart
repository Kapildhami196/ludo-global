import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';

class AnimatedDice extends StatefulWidget {
  const AnimatedDice({
    required this.value,
    required this.enabled,
    required this.rolling,
    required this.onTap,
    super.key,
  });

  final int value;
  final bool enabled;
  final bool rolling;
  final VoidCallback onTap;

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
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: widget.enabled || widget.rolling ? 1 : 0.48,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double t = _controller.value;
              final double angle = widget.rolling
                  ? (t * math.pi * 4)
                  : 0;
              final double jump = widget.rolling
                  ? -math.sin(t * math.pi * 2).abs() * 10
                  : 0;
              final double scale = widget.rolling
                  ? 0.92 + (math.sin(t * math.pi).abs() * 0.12)
                  : 1;

              return Transform.translate(
                offset: Offset(0, jump),
                child: Transform.rotate(
                  angle: angle,
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                ),
              );
            },
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                gradient: LudoGlobalGradients.normal,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.52),
                  width: 1.7,
                ),
                boxShadow: [
                  BoxShadow(
                    color: LudoGlobalColors.electricBlue.withValues(
                      alpha: widget.enabled || widget.rolling ? 0.5 : 0.12,
                    ),
                    blurRadius: 20,
                    spreadRadius: widget.rolling ? 2 : 0,
                  ),
                  const BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 10,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 6,
                    left: 14,
                    right: 14,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Center(
                    child: _DiceFace(
                      value: widget.value,
                      rolling: widget.rolling,
                      tick: _controller,
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
            ? ((tick.value * 17).floor() % 6) + 1
            : value.clamp(1, 6);

        return CustomPaint(
          size: const Size.square(48),
          painter: _DiceFacePainter(value: previewValue),
        );
      },
    );
  }
}

class _DiceFacePainter extends CustomPainter {
  const _DiceFacePainter({required this.value});

  final int value;

  static const List<Alignment> _spots = <Alignment>[
    Alignment(-0.55, -0.55),
    Alignment(0, -0.55),
    Alignment(0.55, -0.55),
    Alignment(-0.55, 0),
    Alignment.center,
    Alignment(0.55, 0),
    Alignment(-0.55, 0.55),
    Alignment(0, 0.55),
    Alignment(0.55, 0.55),
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
    final Rect rect = Offset.zero & size;
    final RRect die = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(11),
    );

    canvas.drawRRect(
      die,
      Paint()..color = const Color(0xFFF8FBFF),
    );
    canvas.drawRRect(
      die,
      Paint()
        ..color = const Color(0xFFB7D8F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final Paint pipPaint = Paint()..color = const Color(0xFF102D52);
    for (final int index in _faceMap[value] ?? const <int>[4]) {
      final Alignment spot = _spots[index];
      final Offset center = Offset(
        size.width * (spot.x + 1) / 2,
        size.height * (spot.y + 1) / 2,
      );
      canvas.drawCircle(center, 4.1, pipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiceFacePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
