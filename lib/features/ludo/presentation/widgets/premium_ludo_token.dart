import 'dart:math' as math;

import 'package:flutter/material.dart';

class PremiumLudoToken extends StatefulWidget {
  const PremiumLudoToken({
    required this.color,
    this.size = 30,
    this.dimmed = false,
    this.highlighted = false,
    this.moving = false,
    this.captured = false,
    this.onTap,
    super.key,
  });

  final Color color;
  final double size;
  final bool dimmed;
  final bool highlighted;
  final bool moving;
  final bool captured;
  final VoidCallback? onTap;

  @override
  State<PremiumLudoToken> createState() => _PremiumLudoTokenState();
}

class _PremiumLudoTokenState extends State<PremiumLudoToken>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
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
        oldWidget.captured != widget.captured) {
      _syncMotion();
    }
  }

  void _syncMotion() {
    if (widget.captured) {
      _controller
        ..duration = const Duration(milliseconds: 430)
        ..forward(from: 0);
      return;
    }

    if (widget.moving) {
      _controller
        ..duration = const Duration(milliseconds: 180)
        ..repeat();
      return;
    }

    _controller
      ..stop()
      ..reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HSLColor hsl = HSLColor.fromColor(widget.color);
    final Color highlight = hsl
        .withLightness(
          (hsl.lightness + 0.25).clamp(0.0, 1.0).toDouble(),
        )
        .toColor();
    final Color shadow = hsl
        .withLightness(
          (hsl.lightness - 0.18).clamp(0.0, 1.0).toDouble(),
        )
        .toColor();

    return Semantics(
      button: widget.onTap != null,
      enabled: widget.onTap != null,
      label: widget.highlighted ? 'Movable Ludo token' : 'Ludo token',
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double t = _controller.value;
            final double hop = widget.moving
                ? -math.sin(t * math.pi).abs() * 6
                : 0;
            final double shake = widget.captured
                ? math.sin(t * math.pi * 9) * 5 * (1 - t)
                : 0;
            final double captureScale = widget.captured
                ? 1 - (0.2 * Curves.easeIn.transform(t))
                : 1;

            return Transform.translate(
              offset: Offset(shake, hop),
              child: Transform.scale(
                scale: captureScale,
                child: child,
              ),
            );
          },
          child: AnimatedScale(
            scale: widget.highlighted ? 1.12 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: Opacity(
              opacity: widget.dimmed ? 0.28 : 1,
              child: SizedBox(
                width: widget.size,
                height: widget.size * 1.15,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    if (widget.highlighted)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withValues(alpha: 0.78),
                                blurRadius: widget.size * 0.65,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    Container(
                      width: widget.size * 0.92,
                      height: widget.size * 0.3,
                      decoration: BoxDecoration(
                        color: shadow.withValues(alpha: 0.48),
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(
                            widget.size,
                            widget.size * 0.35,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.38),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: widget.size * 0.12,
                      child: Container(
                        width: widget.size * 0.72,
                        height: widget.size * 0.72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: const Alignment(-0.35, -0.45),
                            colors: [
                              highlight,
                              widget.color,
                              shadow,
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: widget.highlighted ? 0.95 : 0.65,
                            ),
                            width: widget.highlighted ? 2 : 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Align(
                          alignment: const Alignment(-0.35, -0.45),
                          child: Container(
                            width: widget.size * 0.14,
                            height: widget.size * 0.14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.66),
                            ),
                          ),
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
