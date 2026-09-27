import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/game_asset_paths.dart';
import '../../domain/entities/player_color.dart';
import '../style/ludo_reference_visuals.dart';

class PremiumLudoToken extends StatefulWidget {
  const PremiumLudoToken({
    required this.playerColor,
    this.size = 30,
    this.dimmed = false,
    this.highlighted = false,
    this.moving = false,
    this.captured = false,
    this.returning = false,
    this.shielded = false,
    this.onTap,
    super.key,
  });

  final PlayerColor playerColor;
  final double size;
  final bool dimmed;
  final bool highlighted;
  final bool moving;
  final bool captured;
  final bool returning;
  final bool shielded;
  final VoidCallback? onTap;

  @override
  State<PremiumLudoToken> createState() => _PremiumLudoTokenState();
}

class _PremiumLudoTokenState extends State<PremiumLudoToken>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );

  @override
  void initState() {
    super.initState();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant PremiumLudoToken oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moving != widget.moving ||
        oldWidget.captured != widget.captured ||
        oldWidget.returning != widget.returning) {
      _syncMotion();
    }
  }

  void _syncMotion() {
    if (widget.captured) {
      _controller
        ..duration = const Duration(milliseconds: 420)
        ..forward(from: 0);
      return;
    }

    if (widget.returning) {
      _controller
        ..duration = const Duration(milliseconds: 520)
        ..forward(from: 0);
      return;
    }

    if (widget.moving) {
      _controller
        ..duration = const Duration(milliseconds: 150)
        ..repeat();
      return;
    }

    _controller
      ..stop()
      ..reset();
  }

  Color get _accentColor =>
      LudoReferenceVisuals.colorFor(widget.playerColor);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PlayerColor displayColor =
        LudoReferenceVisuals.displayColorFor(widget.playerColor);

    return Semantics(
      button: widget.onTap != null,
      enabled: widget.onTap != null,
      label: widget.highlighted ? 'Movable Ludo pawn' : 'Ludo pawn',
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: widget.dimmed ? 0.28 : 1,
          child: AnimatedScale(
            scale: widget.highlighted ? 1.10 : 1,
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutBack,
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final double t = _controller.value;
                final double lift = widget.returning
                    ? math.sin(t * math.pi).abs()
                    : widget.moving
                        ? math.sin(t * math.pi).abs()
                        : 0;
                final double hop = widget.returning
                    ? -lift * widget.size * 0.70
                    : widget.moving
                        ? -lift * widget.size * 0.34
                        : 0;
                final double squash = widget.returning
                    ? 1 - lift * 0.055
                    : widget.moving
                        ? 1 - lift * 0.040
                        : 1;
                final double shake = widget.captured
                    ? math.sin(t * math.pi * 10) *
                        widget.size *
                        0.15 *
                        (1 - t)
                    : 0;
                final double captureScale = widget.captured
                    ? 1 - (0.28 * Curves.easeIn.transform(t))
                    : widget.returning
                        ? 0.92 + lift * 0.12
                        : 1;
                final double shadowWidth =
                    widget.size * (0.73 - lift * 0.20);
                final double shadowOpacity = 0.46 - lift * 0.20;

                return SizedBox(
                  width: widget.size,
                  height: widget.size * 1.36,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      if (widget.highlighted || widget.shielded)
                        Positioned(
                          left: -widget.size * 0.20,
                          right: -widget.size * 0.20,
                          bottom: widget.size * 0.05,
                          height: widget.size * 0.72,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: (widget.shielded
                                          ? const Color(0xFF29D9FF)
                                          : _accentColor)
                                      .withValues(alpha: 0.58),
                                  blurRadius: widget.size * 0.58,
                                  spreadRadius: widget.size * 0.025,
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: widget.size * 0.015,
                        child: Container(
                          width: shadowWidth,
                          height: widget.size * 0.115,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: shadowOpacity,
                                ),
                                blurRadius: widget.size * 0.12,
                                spreadRadius: widget.size * 0.015,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(shake, hop),
                        child: Transform.scale(
                          scaleX: captureScale / squash,
                          scaleY: captureScale * squash,
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            width: widget.size,
                            height: widget.size * 1.30,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: SvgPicture.asset(
                                    GameAssetPaths.pawnFor(displayColor),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  left: widget.size * 0.20,
                                  top: widget.size * 0.12,
                                  child: IgnorePointer(
                                    child: Container(
                                      width: widget.size * 0.20,
                                      height: widget.size * 0.09,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        color: Colors.white.withValues(
                                          alpha: 0.24,
                                        ),
                                        boxShadow: <BoxShadow>[
                                          BoxShadow(
                                            color: Colors.white.withValues(
                                              alpha: 0.22,
                                            ),
                                            blurRadius: widget.size * 0.12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (widget.shielded)
                        Positioned(
                          right: -widget.size * 0.08,
                          top: widget.size * 0.02,
                          child: Container(
                            width: widget.size * 0.39,
                            height: widget.size * 0.39,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  Color(0xFF67F0FF),
                                  Color(0xFF0876E8),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white,
                                width: 1,
                              ),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0xAA00C8FF),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.shield_rounded,
                              size: widget.size * 0.23,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
