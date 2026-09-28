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
    this.size = 110,
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
        if (!mounted || sequence != _settleSequence || widget.rolling) {
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
          opacity: widget.enabled || widget.rolling || _settling ? 1 : 0.74,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final double t = _controller.value;

              double travel = 0;
              double scale = 1;
              double xRotation = 0;

              int previewValue = widget.value.clamp(1, 6).toInt();

              if (widget.rolling) {
                // Vertical/front-face tumble.
                const int halfTurnsPerCycle = 8;

                final double halfTurnProgress = t * halfTurnsPerCycle;

                final int halfTurnIndex = halfTurnProgress.floor();

                final double local = halfTurnProgress - halfTurnIndex;

                previewValue = (halfTurnIndex % 6) + 1;

                xRotation =
                    local < 0.5 ? local * math.pi : (local - 1) * math.pi;

                // Vertical hop.
                travel = math.sin(t * math.pi).abs();

                // Dice grows slightly while airborne.
                scale = 1 + travel * 0.14;
              } else if (_settling) {
                final double bounceWindow =
                    (t / 0.20).clamp(0.0, 1.0).toDouble();

                final double bounce = math
                    .sin(
                      bounceWindow * math.pi,
                    )
                    .abs();

                scale = 1 + bounce * 0.06;

                xRotation = -bounce * 0.055;
              }

              final double verticalOffset = -travel * widget.size * 0.27;

              final Matrix4 transform = Matrix4.identity()
                ..setEntry(3, 2, 0.0028)
                ..rotateX(xRotation);

              return Transform.translate(
                offset: Offset(
                  0,
                  verticalOffset,
                ),
                child: Transform.scale(
                  scale: scale,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: transform,
                    child: _FlatDiceFace(
                      value: previewValue,
                      size: widget.size,
                      accentColor: widget.accentColor,
                      active: widget.enabled || widget.rolling || _settling,
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
    // ---------------------------------------------------------
    // IMPORTANT:
    //
    // Your dice SVG has transparent/empty space around the
    // actual white dice face.
    //
    // Making the SizedBox bigger alone doesn't solve that.
    // We scale the SVG AFTER layout using Transform.scale.
    // ---------------------------------------------------------

    const double visibleDiceScale = 1.05;

    final double shadowWidth = size * (0.80 - travel * 0.12);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          // Ground shadow.
          Positioned(
            bottom: size * 0.01,
            child: Container(
              width: shadowWidth,
              height: size * 0.080,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.32 - travel * 0.12,
                    ),
                    blurRadius: size * 0.12,
                    offset: Offset(
                      0,
                      size * 0.040,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Active dice glow.
          if (active)
            Container(
              width: size * 1.06,
              height: size * 1.06,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  size * 0.20,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: accentColor.withValues(
                      alpha: 0.13,
                    ),
                    blurRadius: size * 0.22,
                    spreadRadius: size * 0.015,
                  ),
                ],
              ),
            ),

          // -----------------------------------------------------
          // ACTUAL DICE SVG
          // -----------------------------------------------------
          //
          // Transform.scale is intentional.
          //
          // A larger SizedBox was being constrained by the Stack.
          // Transform.scale paints outside those constraints.
          //
          Transform.scale(
            scale: visibleDiceScale,
            alignment: Alignment.center,
            child: SizedBox.square(
              dimension: size,
              child: SvgPicture.asset(
                GameAssetPaths.diceFor(value),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
