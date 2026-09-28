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
    required this.launchDirection,
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
  final Offset launchDirection;
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
  void didUpdateWidget(
    covariant PlayerDiceSlot oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (widget.active && !oldWidget.active) {
      _controller.repeat();
    } else if (!widget.active && oldWidget.active) {
      _controller
        ..stop()
        ..reset();
    }
  }

  Color get _accentColor => LudoReferenceVisuals.colorFor(
        widget.color,
      );

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
        final double wave = (math.sin(
                  _controller.value * math.pi * 2,
                ) +
                1) /
            2;

        final double pulseScale = 0.994 + wave * 0.012;

        return Transform.scale(
          scale: pulseScale,
          child: _buildDiceSlot(wave),
        );
      },
    );
  }

  Widget _buildDiceSlot(double wave) {
    return SizedBox(
      width: widget.size * 1.20,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Speech-bubble pointer.
          Positioned(
            left: widget.tailOnRight ? null : 0,
            right: widget.tailOnRight ? 0 : null,
            top: widget.size * 0.43,
            child: CustomPaint(
              size: Size(
                widget.size * 0.30,
                widget.size * 0.30,
              ),
              painter: _DiceBubbleTailPainter(
                pointRight: widget.tailOnRight,
              ),
            ),
          ),

          Positioned(
            left: widget.tailOnRight ? 0 : widget.size * 0.20,
            right: widget.tailOnRight ? widget.size * 0.20 : 0,
            child: Container(
              width: widget.size,

              // Keep the surrounding dice bubble compact.
              height: widget.size * 0.88,

              // Reduced padding significantly so the dice has
              // more usable room.
              padding: EdgeInsets.all(
                widget.size * 0.010,
              ),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  widget.size * 0.19,
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFF2B2B59),
                    Color(0xFF161638),
                  ],
                ),
                border: Border.all(
                  color: const Color(
                    0xFF0B0E28,
                  ),
                  width: widget.size * 0.036,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.48,
                    ),
                    blurRadius: widget.size * 0.15,
                    offset: Offset(
                      0,
                      widget.size * 0.07,
                    ),
                  ),
                  BoxShadow(
                    color: _accentColor.withValues(
                      alpha: 0.08 + wave * 0.08,
                    ),
                    blurRadius: widget.size * 0.14,
                    spreadRadius: widget.size * 0.004,
                  ),
                ],
              ),

              // ------------------------------------------------
              // BIGGER DICE
              // ------------------------------------------------
              //
              // OverflowBox prevents the bubble's 0.88-height
              // constraint from shrinking the dice again.
              //
              child: OverflowBox(
                alignment: Alignment.center,
                minWidth: 0,
                minHeight: 0,
                maxWidth: widget.size * 1.10,
                maxHeight: widget.size * 1.10,
                child: AnimatedDice(
                  value: widget.value,
                  enabled: widget.enabled,
                  rolling: widget.rolling,
                  onTap: widget.onRoll,
                  accentColor: _accentColor,

                  // OLD:
                  // size: widget.size * 0.84,

                  // NEW:
                  size: widget.size * 0.96,

                  launchDirection: widget.launchDirection,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiceBubbleTailPainter extends CustomPainter {
  const _DiceBubbleTailPainter({
    required this.pointRight,
  });

  final bool pointRight;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Path path = Path();

    if (pointRight) {
      path
        ..moveTo(
          0,
          size.height * 0.14,
        )
        ..lineTo(
          size.width,
          size.height * 0.50,
        )
        ..lineTo(
          0,
          size.height * 0.86,
        )
        ..close();
    } else {
      path
        ..moveTo(
          size.width,
          size.height * 0.14,
        )
        ..lineTo(
          0,
          size.height * 0.50,
        )
        ..lineTo(
          size.width,
          size.height * 0.86,
        )
        ..close();
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(
          0xFF171737,
        ),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(
          0xFF0B0E28,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.12,
    );
  }

  @override
  bool shouldRepaint(
    covariant _DiceBubbleTailPainter oldDelegate,
  ) {
    return oldDelegate.pointRight != pointRight;
  }
}
