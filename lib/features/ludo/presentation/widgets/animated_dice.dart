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
    super.key,
  });

  final int value;
  final bool enabled;
  final bool rolling;
  final VoidCallback onTap;
  final Color accentColor;
  final double size;
  final bool compact;

  @override
  State<AnimatedDice> createState() => _AnimatedDiceState();
}

class _AnimatedDiceState extends State<AnimatedDice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 680),
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
          opacity: widget.enabled || widget.rolling ? 1 : 0.34,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final double t = _controller.value;
              final double eased = Curves.easeOutCubic.transform(t);
              final double angle = widget.rolling
                  ? (eased * math.pi * 4.5) - 0.08
                  : -0.08;
              final double jump = widget.rolling
                  ? -math.sin(t * math.pi).abs() * widget.size * 0.15
                  : 0;
              final double scale = widget.rolling
                  ? 0.94 + math.sin(t * math.pi).abs() * 0.10
                  : 1;
              final int previewValue = widget.rolling
                  ? ((t * 23).floor() % 6) + 1
                  : widget.value.clamp(1, 6).toInt();

              return Transform.translate(
                offset: Offset(0, jump),
                child: Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: angle,
                    child: _DiceShell(
                      value: previewValue,
                      size: widget.size,
                      accentColor: widget.accentColor,
                      active: widget.enabled || widget.rolling,
                      compact: widget.compact,
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

class _DiceShell extends StatelessWidget {
  const _DiceShell({
    required this.value,
    required this.size,
    required this.accentColor,
    required this.active,
    required this.compact,
  });

  final int value;
  final double size;
  final Color accentColor;
  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double dieSize = size * (compact ? 0.72 : 0.66);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: size * 0.05,
            child: Container(
              width: size * 0.58,
              height: size * 0.13,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xAA000000),
                    blurRadius: size * 0.13,
                    spreadRadius: size * 0.01,
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: size * 0.92,
            height: size * 0.92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  accentColor.withValues(alpha: active ? 0.26 : 0.08),
                  accentColor.withValues(alpha: active ? 0.08 : 0.02),
                  Colors.transparent,
                ],
                stops: const <double>[0.28, 0.68, 1],
              ),
              border: Border.all(
                color: accentColor.withValues(
                  alpha: active ? 0.88 : 0.18,
                ),
                width: compact ? 1.2 : 2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: accentColor.withValues(
                    alpha: active ? 0.60 : 0.08,
                  ),
                  blurRadius: size * (active ? 0.28 : 0.12),
                  spreadRadius: active ? size * 0.025 : 0,
                ),
              ],
            ),
          ),
          SvgPicture.asset(
            GameAssetPaths.diceFor(value),
            width: dieSize,
            height: dieSize,
          ),
        ],
      ),
    );
  }
}
