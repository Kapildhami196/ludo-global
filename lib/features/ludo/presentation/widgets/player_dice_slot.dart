import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/player_color.dart';
import '../style/ludo_reference_visuals.dart';
import 'animated_dice.dart';

class PlayerDiceSlot extends StatefulWidget {
  const PlayerDiceSlot({
    required this.color,
    required this.active,
    required this.value,
    required this.rolling,
    required this.enabled,
    required this.onRoll,
    required this.size,
    this.tailOnRight = false,
    super.key,
  });

  final PlayerColor color;
  final bool active;
  final int value;
  final bool rolling;
  final bool enabled;
  final VoidCallback onRoll;
  final double size;
  final bool tailOnRight;

  @override
  State<PlayerDiceSlot> createState() => _PlayerDiceSlotState();
}

class _PlayerDiceSlotState extends State<PlayerDiceSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PlayerDiceSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.repeat();
    } else if (!widget.active && oldWidget.active) {
      _controller
        ..stop()
        ..reset();
    }
  }

  Color get _accentColor =>
      LudoReferenceVisuals.colorFor(widget.color);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double wave =
            (math.sin(_controller.value * math.pi * 2) + 1) / 2;
        final double pulseScale = 0.992 + wave * 0.016;

        return Transform.scale(
          scale: pulseScale,
          child: SizedBox(
            width: widget.size * 1.18,
            height: widget.size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: widget.tailOnRight ? null : 0,
                  right: widget.tailOnRight ? 0 : null,
                  top: widget.size * 0.45,
                  child: CustomPaint(
                    size: Size(widget.size * 0.28, widget.size * 0.28),
                    painter: _DiceBubbleTailPainter(
                      pointRight: !widget.tailOnRight,
                    ),
                  ),
                ),
                Positioned(
                  left: widget.tailOnRight ? 0 : widget.size * 0.18,
                  right: widget.tailOnRight ? widget.size * 0.18 : 0,
                  child: Container(
                    width: widget.size,
                    height: widget.size * 0.90,
                    padding: EdgeInsets.all(widget.size * 0.09),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.size * 0.19),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          Color(0xFF262653),
                          Color(0xFF161638),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFF0D102D),
                        width: widget.size * 0.035,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.44),
                          blurRadius: widget.size * 0.14,
                          offset: Offset(0, widget.size * 0.07),
                        ),
                        BoxShadow(
                          color: _accentColor.withValues(
                            alpha: 0.10 + wave * 0.09,
                          ),
                          blurRadius: widget.size * 0.20,
                          spreadRadius: widget.size * 0.01,
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedDice(
                        value: widget.value,
                        enabled: widget.enabled,
                        rolling: widget.rolling,
                        onTap: widget.onRoll,
                        accentColor: _accentColor,
                        size: widget.size * 0.72,
                        compact: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DiceBubbleTailPainter extends CustomPainter {
  const _DiceBubbleTailPainter({
    required this.pointRight,
  });

  final bool pointRight;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();

    if (pointRight) {
      path
        ..moveTo(0, size.height * 0.16)
        ..lineTo(size.width, size.height * 0.50)
        ..lineTo(0, size.height * 0.84)
        ..close();
    } else {
      path
        ..moveTo(size.width, size.height * 0.16)
        ..lineTo(0, size.height * 0.50)
        ..lineTo(size.width, size.height * 0.84)
        ..close();
    }

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF171737),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF0D102D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.12,
    );
  }

  @override
  bool shouldRepaint(covariant _DiceBubbleTailPainter oldDelegate) {
    return oldDelegate.pointRight != pointRight;
  }
}
