import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';
import '../../domain/entities/player_color.dart';
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
    super.key,
  });

  final PlayerColor color;
  final bool active;
  final int value;
  final bool rolling;
  final bool enabled;
  final VoidCallback onRoll;
  final double size;

  @override
  State<PlayerDiceSlot> createState() => _PlayerDiceSlotState();
}

class _PlayerDiceSlotState extends State<PlayerDiceSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat();

  Color get _accentColor => switch (widget.color) {
        PlayerColor.red => LudoGlobalColors.red,
        PlayerColor.green => LudoGlobalColors.green,
        PlayerColor.yellow => LudoGlobalColors.gold,
        PlayerColor.blue => LudoGlobalColors.electricBlue,
      };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double wave =
            (math.sin(_controller.value * math.pi * 2) + 1) / 2;
        final double pulseScale = widget.active
            ? 0.985 + wave * 0.025
            : 1;

        return AnimatedScale(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          scale: (widget.active ? 1 : 0.82) * pulseScale,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: widget.active ? 1 : 0.32,
            child: Container(
              width: widget.size,
              height: widget.size,
              padding: EdgeInsets.all(widget.size * 0.08),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xD1061127),
                border: Border.all(
                  color: _accentColor.withValues(
                    alpha: widget.active ? 0.92 : 0.22,
                  ),
                  width: widget.active ? 1.6 : 0.9,
                ),
                boxShadow: <BoxShadow>[
                  if (widget.active)
                    BoxShadow(
                      color: _accentColor.withValues(
                        alpha: 0.30 + wave * 0.24,
                      ),
                      blurRadius:
                          widget.size * (0.30 + wave * 0.20),
                      spreadRadius: wave * 1.4,
                    ),
                  const BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: widget.active
                  ? AnimatedDice(
                      value: widget.value,
                      enabled: widget.enabled,
                      rolling: widget.rolling,
                      onTap: widget.onRoll,
                      accentColor: _accentColor,
                      size: widget.size * 0.92,
                      compact: true,
                    )
                  : Icon(
                      Icons.casino_rounded,
                      size: widget.size * 0.42,
                      color: _accentColor.withValues(alpha: 0.70),
                    ),
            ),
          ),
        );
      },
    );
  }
}
