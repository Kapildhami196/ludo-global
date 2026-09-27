import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/game_asset_paths.dart';
import '../../domain/entities/player_color.dart';

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
    duration: const Duration(milliseconds: 140),
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
        ..duration = const Duration(milliseconds: 140)
        ..repeat();
      return;
    }

    _controller
      ..stop()
      ..reset();
  }

  Color get _accentColor => switch (widget.playerColor) {
        PlayerColor.red => const Color(0xFFF13B48),
        PlayerColor.green => const Color(0xFF26C45A),
        PlayerColor.yellow => const Color(0xFFF5C433),
        PlayerColor.blue => const Color(0xFF2495F2),
      };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      enabled: widget.onTap != null,
      label: widget.highlighted ? 'Movable Ludo pawn' : 'Ludo pawn',
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double t = _controller.value;
            final double hop = widget.returning
                ? -math.sin(t * math.pi).abs() * widget.size * 0.72
                : widget.moving
                    ? -math.sin(t * math.pi).abs() * widget.size * 0.30
                    : 0;
            final double squash = widget.returning
                ? 1 - math.sin(t * math.pi).abs() * 0.05
                : widget.moving
                    ? 1 - math.sin(t * math.pi).abs() * 0.035
                    : 1;
            final double shake = widget.captured
                ? math.sin(t * math.pi * 10) *
                    widget.size *
                    0.16 *
                    (1 - t)
                : 0;
            final double captureScale = widget.captured
                ? 1 - (0.28 * Curves.easeIn.transform(t))
                : widget.returning
                    ? 0.92 + (math.sin(t * math.pi).abs() * 0.12)
                    : 1;

            return Transform.translate(
              offset: Offset(shake, hop),
              child: Transform.scale(
                scaleX: captureScale / squash,
                scaleY: captureScale * squash,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            );
          },
          child: AnimatedScale(
            scale: widget.highlighted ? 1.14 : 1,
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutBack,
            alignment: Alignment.bottomCenter,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: widget.dimmed ? 0.28 : 1,
              child: SizedBox(
                width: widget.size,
                height: widget.size * 1.34,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    if (widget.highlighted || widget.shielded)
                      Positioned(
                        left: -widget.size * 0.18,
                        right: -widget.size * 0.18,
                        bottom: widget.size * 0.02,
                        height: widget.size * 0.72,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: (widget.shielded
                                        ? const Color(0xFF29D9FF)
                                        : _accentColor)
                                    .withValues(alpha: 0.72),
                                blurRadius: widget.size * 0.72,
                                spreadRadius: widget.size * 0.05,
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: widget.size * 0.02,
                      child: Container(
                        width: widget.size * 0.72,
                        height: widget.size * 0.13,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x99000000),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: SvgPicture.asset(
                        GameAssetPaths.pawnFor(widget.playerColor),
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (widget.shielded)
                      Positioned(
                        right: -widget.size * 0.09,
                        top: widget.size * 0.03,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
