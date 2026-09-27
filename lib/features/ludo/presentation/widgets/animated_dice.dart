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
          duration: const Duration(milliseconds: 150),
          opacity: widget.enabled || widget.rolling ? 1 : 0.58,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final double t = _controller.value;
              final double lift =
                  widget.rolling ? math.sin(t * math.pi).abs() : 0;
              final double jump =
                  widget.rolling ? -lift * widget.size * 0.22 : 0;
              final double wobbleX = widget.rolling
                  ? math.sin(t * math.pi * 6) *
                      widget.size *
                      0.055
                  : 0;
              final double scale = widget.rolling
                  ? 0.96 + (lift * 0.15)
                  : 1;
              final double zRotation = widget.rolling
                  ? t * math.pi * 4.4
                  : -0.035;
              final double xRotation = widget.rolling
                  ? math.sin(t * math.pi * 4) * 0.24
                  : 0;
              final double yRotation = widget.rolling
                  ? math.cos(t * math.pi * 5) * 0.20
                  : 0;
              final int previewValue = widget.rolling
                  ? ((t * 25).floor() % 6) + 1
                  : widget.value.clamp(1, 6).toInt();

              final Matrix4 transform = Matrix4.identity()
                ..setEntry(3, 2, 0.0018)
                ..rotateX(xRotation)
                ..rotateY(yRotation)
                ..rotateZ(zRotation);

              return Transform.translate(
                offset: Offset(wobbleX, jump),
                child: Transform.scale(
                  scale: scale,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: transform,
                    child: _DiceFace(
                      value: previewValue,
                      size: widget.size,
                      accentColor: widget.accentColor,
                      active: widget.enabled || widget.rolling,
                      lift: lift,
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
    required this.size,
    required this.accentColor,
    required this.active,
    required this.lift,
  });

  final int value;
  final double size;
  final Color accentColor;
  final bool active;
  final double lift;

  @override
  Widget build(BuildContext context) {
    final double faceSize = size * 0.92;
    final double shadowWidth = size * (0.70 - lift * 0.18);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: size * 0.025,
            child: Container(
              width: shadowWidth,
              height: size * 0.12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.42 - lift * 0.17,
                    ),
                    blurRadius: size * 0.13,
                    spreadRadius: size * 0.012,
                  ),
                ],
              ),
            ),
          ),
          if (active)
            Container(
              width: size * 0.88,
              height: size * 0.88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.22),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.24),
                    blurRadius: size * 0.22,
                    spreadRadius: size * 0.015,
                  ),
                ],
              ),
            ),
          SvgPicture.asset(
            GameAssetPaths.diceFor(value),
            width: faceSize,
            height: faceSize,
          ),
        ],
      ),
    );
  }
}
