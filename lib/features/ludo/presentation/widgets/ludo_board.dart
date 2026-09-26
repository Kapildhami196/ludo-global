import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';
import 'premium_ludo_token.dart';

class LudoBoard extends StatelessWidget {
  const LudoBoard({
    this.activePlayerCount = 4,
    super.key,
  });

  final int activePlayerCount;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double size = math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final double cell = size / 15;
          final double tokenSize = cell * 0.78;

          return RepaintBoundary(
            child: SizedBox.square(
              dimension: size,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(
                      painter: _LudoBoardPainter(),
                    ),
                  ),
                  ..._tokenAnchors(cell).map(
                    (anchor) => Positioned(
                      left: anchor.x - (tokenSize / 2),
                      top: anchor.y - (tokenSize * 0.58),
                      child: PremiumLudoToken(
                        color: anchor.color,
                        size: tokenSize,
                        dimmed: anchor.playerIndex >= activePlayerCount,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<_TokenAnchor> _tokenAnchors(double cell) {
    List<_TokenAnchor> four(
      int playerIndex,
      Color color,
      List<Offset> cells,
    ) {
      return cells
          .map(
            (point) => _TokenAnchor(
              playerIndex: playerIndex,
              color: color,
              x: point.dx * cell,
              y: point.dy * cell,
            ),
          )
          .toList();
    }

    return [
      ...four(
        0,
        LudoGlobalColors.red,
        const [
          Offset(2, 2),
          Offset(4, 2),
          Offset(2, 4),
          Offset(4, 4),
        ],
      ),
      ...four(
        1,
        LudoGlobalColors.green,
        const [
          Offset(11, 2),
          Offset(13, 2),
          Offset(11, 4),
          Offset(13, 4),
        ],
      ),
      ...four(
        2,
        LudoGlobalColors.gold,
        const [
          Offset(11, 11),
          Offset(13, 11),
          Offset(11, 13),
          Offset(13, 13),
        ],
      ),
      ...four(
        3,
        LudoGlobalColors.electricBlue,
        const [
          Offset(2, 11),
          Offset(4, 11),
          Offset(2, 13),
          Offset(4, 13),
        ],
      ),
    ];
  }
}

class _TokenAnchor {
  const _TokenAnchor({
    required this.playerIndex,
    required this.color,
    required this.x,
    required this.y,
  });

  final int playerIndex;
  final Color color;
  final double x;
  final double y;
}

class _LudoBoardPainter extends CustomPainter {
  const _LudoBoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / 15;
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF173A66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final Paint whitePaint = Paint()..color = const Color(0xFFF8FBFF);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(cell * 0.45),
      ),
      Paint()..color = const Color(0xFFEAF4FF),
    );

    _drawBase(
      canvas,
      cell,
      const Offset(0, 0),
      LudoGlobalColors.red,
      borderPaint,
    );
    _drawBase(
      canvas,
      cell,
      const Offset(9, 0),
      LudoGlobalColors.green,
      borderPaint,
    );
    _drawBase(
      canvas,
      cell,
      const Offset(9, 9),
      LudoGlobalColors.gold,
      borderPaint,
    );
    _drawBase(
      canvas,
      cell,
      const Offset(0, 9),
      LudoGlobalColors.electricBlue,
      borderPaint,
    );

    for (int row = 0; row < 15; row++) {
      for (int column = 0; column < 15; column++) {
        final bool onTrack =
            (row >= 6 && row <= 8) || (column >= 6 && column <= 8);
        final bool inCenter =
            row >= 6 && row <= 8 && column >= 6 && column <= 8;

        if (!onTrack || inCenter) {
          continue;
        }

        final Rect rect = Rect.fromLTWH(
          column * cell,
          row * cell,
          cell,
          cell,
        );
        canvas.drawRect(rect, whitePaint);
        canvas.drawRect(rect, borderPaint);
      }
    }

    _fillLane(
      canvas,
      cell,
      cells: [
        for (int column = 1; column <= 5; column++) Offset(column.toDouble(), 7),
      ],
      color: LudoGlobalColors.red,
      borderPaint: borderPaint,
    );
    _fillLane(
      canvas,
      cell,
      cells: [
        for (int row = 1; row <= 5; row++) Offset(7, row.toDouble()),
      ],
      color: LudoGlobalColors.green,
      borderPaint: borderPaint,
    );
    _fillLane(
      canvas,
      cell,
      cells: [
        for (int column = 9; column <= 13; column++)
          Offset(column.toDouble(), 7),
      ],
      color: LudoGlobalColors.gold,
      borderPaint: borderPaint,
    );
    _fillLane(
      canvas,
      cell,
      cells: [
        for (int row = 9; row <= 13; row++) Offset(7, row.toDouble()),
      ],
      color: LudoGlobalColors.electricBlue,
      borderPaint: borderPaint,
    );

    _drawStartCell(canvas, cell, 1, 6, LudoGlobalColors.red, borderPaint);
    _drawStartCell(canvas, cell, 8, 1, LudoGlobalColors.green, borderPaint);
    _drawStartCell(canvas, cell, 13, 8, LudoGlobalColors.gold, borderPaint);
    _drawStartCell(
      canvas,
      cell,
      6,
      13,
      LudoGlobalColors.electricBlue,
      borderPaint,
    );

    _drawCenter(canvas, cell);
    _drawOuterBorder(canvas, size, cell);
  }

  void _drawBase(
    Canvas canvas,
    double cell,
    Offset origin,
    Color color,
    Paint borderPaint,
  ) {
    final Rect baseRect = Rect.fromLTWH(
      origin.dx * cell,
      origin.dy * cell,
      cell * 6,
      cell * 6,
    );
    canvas.drawRect(baseRect, Paint()..color = color);

    final Rect innerRect = Rect.fromLTWH(
      (origin.dx + 1) * cell,
      (origin.dy + 1) * cell,
      cell * 4,
      cell * 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, Radius.circular(cell * 0.55)),
      Paint()..color = const Color(0xFFF8FBFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, Radius.circular(cell * 0.55)),
      borderPaint,
    );

    final List<Offset> holes = [
      Offset(origin.dx + 2, origin.dy + 2),
      Offset(origin.dx + 4, origin.dy + 2),
      Offset(origin.dx + 2, origin.dy + 4),
      Offset(origin.dx + 4, origin.dy + 4),
    ];

    for (final Offset hole in holes) {
      canvas.drawCircle(
        Offset(hole.dx * cell, hole.dy * cell),
        cell * 0.48,
        Paint()..color = color.withValues(alpha: 0.18),
      );
      canvas.drawCircle(
        Offset(hole.dx * cell, hole.dy * cell),
        cell * 0.48,
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _fillLane(
    Canvas canvas,
    double cell, {
    required List<Offset> cells,
    required Color color,
    required Paint borderPaint,
  }) {
    for (final Offset point in cells) {
      final Rect rect = Rect.fromLTWH(
        point.dx * cell,
        point.dy * cell,
        cell,
        cell,
      );
      canvas.drawRect(
        rect,
        Paint()..color = color.withValues(alpha: 0.82),
      );
      canvas.drawRect(rect, borderPaint);
    }
  }

  void _drawStartCell(
    Canvas canvas,
    double cell,
    int column,
    int row,
    Color color,
    Paint borderPaint,
  ) {
    final Rect rect = Rect.fromLTWH(
      column * cell,
      row * cell,
      cell,
      cell,
    );
    canvas.drawRect(rect, Paint()..color = color);
    canvas.drawRect(rect, borderPaint);

    canvas.drawCircle(
      rect.center,
      cell * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  void _drawCenter(Canvas canvas, double cell) {
    final Rect center = Rect.fromLTWH(
      6 * cell,
      6 * cell,
      3 * cell,
      3 * cell,
    );
    final Offset c = center.center;

    final List<(Color, Path)> triangles = [
      (
        LudoGlobalColors.red,
        Path()
          ..moveTo(center.left, center.top)
          ..lineTo(center.left, center.bottom)
          ..lineTo(c.dx, c.dy)
          ..close(),
      ),
      (
        LudoGlobalColors.green,
        Path()
          ..moveTo(center.left, center.top)
          ..lineTo(center.right, center.top)
          ..lineTo(c.dx, c.dy)
          ..close(),
      ),
      (
        LudoGlobalColors.gold,
        Path()
          ..moveTo(center.right, center.top)
          ..lineTo(center.right, center.bottom)
          ..lineTo(c.dx, c.dy)
          ..close(),
      ),
      (
        LudoGlobalColors.electricBlue,
        Path()
          ..moveTo(center.left, center.bottom)
          ..lineTo(center.right, center.bottom)
          ..lineTo(c.dx, c.dy)
          ..close(),
      ),
    ];

    for (final (Color color, Path path) in triangles) {
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  void _drawOuterBorder(Canvas canvas, Size size, double cell) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(cell * 0.45),
      ),
      Paint()
        ..color = const Color(0xFF173A66)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _LudoBoardPainter oldDelegate) => false;
}
