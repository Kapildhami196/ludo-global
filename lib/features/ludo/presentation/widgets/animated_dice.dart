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

  /// Direction, expressed in die-size units, used when the die flies toward
  /// the camera/board during a roll.
  final Offset launchDirection;

  @override
  State<AnimatedDice> createState() => _AnimatedDiceState();
}

class _AnimatedDiceState extends State<AnimatedDice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 680),
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
        ..duration = const Duration(milliseconds: 680)
        ..repeat();
      return;
    }

    if (!widget.rolling && oldWidget.rolling) {
      final int sequence = ++_settleSequence;
      _settling = true;
      _controller
        ..stop()
        ..duration = const Duration(milliseconds: 800)
        ..forward(from: 0);

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

              double launchProgress = 0;
              double zRotation = -0.035;
              double xRotation = 0;
              double yRotation = 0;
              int previewValue = widget.value.clamp(1, 6).toInt();

              if (widget.rolling) {
                final double flightT =
                    (t / 0.72).clamp(0.0, 1.0).toDouble();
                launchProgress =
                    Curves.easeOutCubic.transform(flightT);
                zRotation = t * math.pi * 5.4;
                xRotation =
                    math.sin(t * math.pi * 5) * 0.62;
                yRotation =
                    math.cos(t * math.pi * 4.5) * 0.58;
                previewValue = ((t * 31).floor() % 6) + 1;
              } else if (_settling) {
                final double returnT = t <= 0.62
                    ? 0
                    : ((t - 0.62) / 0.38)
                        .clamp(0.0, 1.0)
                        .toDouble();
                final double easedReturn =
                    Curves.easeInOutCubic.transform(returnT);
                launchProgress = 1 - easedReturn;
                zRotation = 0.16 * launchProgress;
                xRotation = -0.10 * launchProgress;
                yRotation = 0.12 * launchProgress;
              }

              final double scale =
                  1 + (launchProgress * 1.48);
              final Offset launchOffset = Offset(
                widget.launchDirection.dx *
                    widget.size *
                    launchProgress,
                widget.launchDirection.dy *
                    widget.size *
                    launchProgress,
              );

              final double flightArc = widget.rolling
                  ? -math.sin(
                        (t / 0.72)
                                .clamp(0.0, 1.0)
                                .toDouble() *
                            math.pi,
                      ) *
                      widget.size *
                      0.34
                  : 0;

              final Matrix4 transform = Matrix4.identity()
                ..setEntry(3, 2, 0.0028)
                ..rotateX(xRotation)
                ..rotateY(yRotation)
                ..rotateZ(zRotation);

              return Transform.translate(
                offset: launchOffset.translate(0, flightArc),
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
                      depth: launchProgress,
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
    required this.depth,
  });

  final int value;
  final double size;
  final Color accentColor;
  final bool active;
  final double depth;

  @override
  Widget build(BuildContext context) {
    final double faceSize = size * 0.86;
    final double extrusion = size * (0.055 + depth * 0.035);
    final double shadowWidth =
        size * (0.72 - depth * 0.16);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: size * 0.015,
            child: Container(
              width: shadowWidth,
              height: size * 0.115,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.44 - depth * 0.18,
                    ),
                    blurRadius: size * 0.14,
                    spreadRadius: size * 0.012,
                  ),
                ],
              ),
            ),
          ),
          if (active)
            Container(
              width: size * 0.90,
              height: size * 0.90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.22),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: accentColor.withValues(
                      alpha: 0.18 + depth * 0.10,
                    ),
                    blurRadius: size * 0.24,
                    spreadRadius: size * 0.01,
                  ),
                ],
              ),
            ),
          Transform.translate(
            offset: Offset(extrusion, extrusion),
            child: Container(
              width: faceSize,
              height: faceSize,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(faceSize * 0.22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFDDE6EE),
                    Color(0xFF8A9AAC),
                    Color(0xFF5D6C7D),
                  ],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: size * 0.06,
                    offset: Offset(
                      size * 0.035,
                      size * 0.045,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(
              -extrusion * 0.42,
              -extrusion * 0.52,
            ),
            child: SvgPicture.asset(
              GameAssetPaths.diceFor(value),
              width: faceSize,
              height: faceSize,
            ),
          ),
          Positioned(
            top: size * 0.11,
            left: size * 0.19,
            child: IgnorePointer(
              child: Container(
                width: size * 0.28,
                height: size * 0.055,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.22),
                      blurRadius: size * 0.05,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
