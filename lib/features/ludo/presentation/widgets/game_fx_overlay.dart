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
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
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
            final double t = Curves.easeOut.transform(_controller.value);
            final double fade = 1 - _controller.value;

            return Stack(
              alignment: Alignment.center,
              children: [
                if (widget.type == GameFxType.winner)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ConfettiPainter(progress: _controller.value),
                    ),
                  ),
                Opacity(
                  opacity: fade.clamp(0.0, 1.0).toDouble(),
                  child: Transform.scale(
                    scale: 0.65 + (t * 0.55),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xD9081730),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withValues(alpha: 0.45),
                            blurRadius: 35,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _icon,
                            color: _accent,
                            size: widget.type == GameFxType.winner ? 64 : 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.label ?? _defaultLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
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

  IconData get _icon {
    return switch (widget.type!) {
      GameFxType.capture => Icons.flash_on_rounded,
      GameFxType.home => Icons.auto_awesome_rounded,
      GameFxType.winner => Icons.emoji_events_rounded,
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
