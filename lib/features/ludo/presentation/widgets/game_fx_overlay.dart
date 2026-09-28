import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';

enum GameFxType {
  capture,
  home,
  winner,
}

class GameFxOverlay extends StatefulWidget {
  const GameFxOverlay({
    required this.type,
    required this.sequence,
    this.label,
    super.key,
  });

  final GameFxType? type;
  final int sequence;
  final String? label;

  @override
  State<GameFxOverlay> createState() => _GameFxOverlayState();
}

class _GameFxOverlayState extends State<GameFxOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.type != null) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant GameFxOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sequence != oldWidget.sequence && widget.type != null) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final double raw = _controller.value;
            final double t = Curves.easeOutBack.transform(
              raw.clamp(0.0, 1.0).toDouble(),
            );
            final double fade =
                (1 - Curves.easeIn.transform(raw)).clamp(0.0, 1.0).toDouble();

            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _EventBurstPainter(
                      progress: raw,
                      type: widget.type!,
                      accent: _accent,
                    ),
                  ),
                ),
                if (widget.type == GameFxType.winner)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ConfettiPainter(progress: raw),
                    ),
                  ),
                Opacity(
                  opacity: fade,
                  child: Transform.rotate(
                    angle: widget.type == GameFxType.capture
                        ? math.sin(raw * math.pi * 2) * 0.018
                        : 0,
                    child: Transform.scale(
                      scale: 0.72 + (t * 0.32),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              const Color(0xF20B1E3B),
                              _accent.withValues(alpha: 0.16),
                              const Color(0xF2051024),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _accent.withValues(alpha: 0.88),
                            width: 1.6,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: _accent.withValues(alpha: 0.50),
                              blurRadius: 34,
                              spreadRadius: 5,
                            ),
                            const BoxShadow(
                              color: Color(0x99000000),
                              blurRadius: 18,
                              offset: Offset(0, 9),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _EventIcon(
                              type: widget.type!,
                              accent: _accent,
                            ),
                            const SizedBox(height: 7),
                            Text(
                              widget.label ?? _defaultLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                shadows: <Shadow>[
                                  Shadow(
                                    color: Color(0xAA000000),
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color get _accent {
    return switch (widget.type!) {
      GameFxType.capture => LudoGlobalColors.red,
      GameFxType.home => LudoGlobalColors.cyan,
      GameFxType.winner => LudoGlobalColors.gold,
    };
  }

  String get _defaultLabel {
    return switch (widget.type!) {
      GameFxType.capture => 'CAPTURE!',
      GameFxType.home => 'HOME!',
      GameFxType.winner => 'WINNER!',
    };
  }
}

class _EventIcon extends StatelessWidget {
  const _EventIcon({
    required this.type,
    required this.accent,
  });

  final GameFxType type;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final IconData icon = switch (type) {
      GameFxType.capture => Icons.flash_on_rounded,
      GameFxType.home => Icons.auto_awesome_rounded,
      GameFxType.winner => Icons.emoji_events_rounded,
    };

    final double size = type == GameFxType.winner ? 64 : 48;

    return Container(
      width: size + 16,
      height: size + 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            accent.withValues(alpha: 0.34),
            accent.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: 0.50),
            blurRadius: 22,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: accent,
        size: size,
        shadows: const <Shadow>[
          Shadow(
            color: Color(0xAA000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _EventBurstPainter extends CustomPainter {
  const _EventBurstPainter({
    required this.progress,
    required this.type,
    required this.accent,
  });

  final double progress;
  final GameFxType type;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double maxRadius = math.min(size.width, size.height) * 0.34;
    final double ringProgress = Curves.easeOutCubic.transform(progress);
    final double ringRadius = maxRadius * ringProgress;

    if (progress < 0.76) {
      canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..color = accent.withValues(
            alpha: ((1 - progress / 0.76) * 0.34)
                .clamp(0.0, 1.0)
                .toDouble(),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              5 * (1 - progress).clamp(0.2, 1.0).toDouble(),
      );
    }

    final int particleCount = type == GameFxType.winner ? 0 : 28;
    for (int index = 0; index < particleCount; index++) {
      final double angle = (math.pi * 2 / particleCount) * index +
          ((index % 3) * 0.11);
      final double speed = 0.62 + (index % 5) * 0.09;
      final double distance =
          maxRadius * progress * speed;
      final Offset point = center +
          Offset(math.cos(angle), math.sin(angle)) * distance;
      final double life =
          (1 - progress).clamp(0.0, 1.0).toDouble();
      final double radius =
          (index.isEven ? 3.2 : 2.0) * (0.55 + life * 0.55);

      canvas.drawCircle(
        point,
        radius * 2.4,
        Paint()
          ..color = accent.withValues(alpha: 0.08 * life)
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            5,
          ),
      );

      canvas.drawCircle(
        point,
        radius,
        Paint()..color = accent.withValues(alpha: 0.72 * life),
      );
    }

    if (type == GameFxType.home) {
      for (int index = 0; index < 8; index++) {
        final double angle = index * math.pi / 4 + progress;
        final double distance =
            maxRadius * (0.20 + progress * 0.46);
        final Offset point = center +
            Offset(math.cos(angle), math.sin(angle)) * distance;
        final double alpha =
            (1 - progress).clamp(0.0, 1.0).toDouble();

        canvas.drawCircle(
          point,
          2.4,
          Paint()
            ..color =
                Colors.white.withValues(alpha: 0.85 * alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EventBurstPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.type != type ||
        oldDelegate.accent != accent;
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress});

  final double progress;

  static const List<Color> _colors = <Color>[
    LudoGlobalColors.gold,
    LudoGlobalColors.cyan,
    LudoGlobalColors.red,
    LudoGlobalColors.green,
    LudoGlobalColors.purple,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    for (int index = 0; index < 54; index++) {
      final double seed = index * 0.61803398875;
      final double x = (seed % 1) * size.width;
      final double speed = 0.65 + ((index % 7) * 0.06);
      final double y =
          ((progress * speed + ((index * 0.137) % 1)) % 1.15) * size.height;
      final double sway = math.sin((progress * 8) + index) * 16;
      paint.color = _colors[index % _colors.length].withValues(
        alpha: (1 - progress * 0.25).clamp(0.0, 1.0).toDouble(),
      );

      canvas.save();
      canvas.translate(x + sway, y - 20);
      canvas.rotate(progress * 8 + index);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -7, 8, 14),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
