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
              widget.enabled || widget.rolling || _settling ? 1 : 0.72,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final double t = _controller.value;

              double travel = 0;
              double scale = 1;
              double zRotation = -0.025;
              double xRotation = 0;
              double yRotation = 0;
              int previewValue = widget.value.clamp(1, 6).toInt();

              if (widget.rolling) {
                travel = math.sin(t * math.pi).abs();
                scale = 1 + travel * 0.46;
                zRotation = t * math.pi * 4.8;
                xRotation = math.sin(t * math.pi * 3.6) * 0.38;
                yRotation = math.cos(t * math.pi * 4.2) * 0.34;
                previewValue = ((t * 29).floor() % 6) + 1;
              } else if (_settling) {
                final double bounceWindow =
                    (t / 0.22).clamp(0.0, 1.0).toDouble();
                final double bounce =
                    math.sin(bounceWindow * math.pi).abs();
                scale = 1 + bounce * 0.08;
                zRotation = -0.025 + bounce * 0.045;
              }

              final Offset launchOffset = Offset(
                widget.launchDirection.dx * widget.size * travel,
                widget.launchDirection.dy * widget.size * travel,
              );
              final double arc =
                  -travel * widget.size * 0.18;

              final Matrix4 transform = Matrix4.identity()
                ..setEntry(3, 2, 0.0022)
                ..rotateX(xRotation)
                ..rotateY(yRotation)
                ..rotateZ(zRotation);

              return Transform.translate(
                offset: launchOffset.translate(0, arc),
                child: Transform.scale(
                  scale: scale,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: transform,
                    child: _DiceFace(
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

class _DiceFace extends StatelessWidget {
  const _DiceFace({
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
    final double faceSize = size * 0.90;
    final double shadowWidth =
        size * (0.72 - travel * 0.12);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: size * 0.02,
            child: Container(
              width: shadowWidth,
              height: size * 0.10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.30 - travel * 0.10,
                    ),
                    blurRadius: size * 0.12,
                    offset: Offset(
                      size * 0.025,
                      size * 0.03,
                    ),
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
                borderRadius: BorderRadius.circular(size * 0.20),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.11),
                    blurRadius: size * 0.16,
                    spreadRadius: size * 0.005,
                  ),
                ],
              ),
            ),
          SvgPicture.asset(
            GameAssetPaths.diceFor(value),
            width: faceSize,
            height: faceSize,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
