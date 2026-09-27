import 'package:flutter/material.dart';

class BoardLightingOverlay extends StatefulWidget {
  const BoardLightingOverlay({
    required this.activeColor,
    super.key,
  });

  final Color activeColor;

  @override
  State<BoardLightingOverlay> createState() =>
      _BoardLightingOverlayState();
}

class _BoardLightingOverlayState extends State<BoardLightingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _BoardLightingPainter(
              progress: _controller.value,
              activeColor: widget.activeColor,
            ),
          );
        },
      ),
    );
  }
}

class _BoardLightingPainter extends CustomPainter {
  const _BoardLightingPainter({
    required this.progress,
    required this.activeColor,
  });

  final double progress;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final double sweepX =
        -size.width * 0.55 + progress * size.width * 2.1;

    final Rect sweepRect = Rect.fromLTWH(
      sweepX,
      -size.height * 0.20,
      size.width * 0.34,
      size.height * 1.40,
    );

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        rect,
        Radius.circular(size.width * 0.035),
      ),
    );

    canvas.drawRect(
      sweepRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.transparent,
            Colors.white.withValues(alpha: 0.00),
            Colors.white.withValues(alpha: 0.085),
            activeColor.withValues(alpha: 0.055),
            Colors.transparent,
          ],
          stops: const <double>[0, 0.28, 0.46, 0.60, 1],
        ).createShader(sweepRect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment.center,
          radius: 0.82,
          colors: <Color>[
            Colors.transparent,
            const Color(0x10000A18),
            const Color(0x3600040C),
          ],
          stops: const <double>[0.50, 0.78, 1],
        ).createShader(rect),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BoardLightingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor;
  }
}
