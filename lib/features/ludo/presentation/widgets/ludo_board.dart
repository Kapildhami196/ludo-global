import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';
import '../../domain/engine/ludo_board_map.dart';
import '../../domain/entities/ludo_game_state.dart';
import '../../domain/entities/ludo_player.dart';
import '../../domain/entities/ludo_token.dart';
import '../../domain/entities/player_color.dart';
import '../../domain/entities/power_type.dart';
import '../../domain/entities/token_status.dart';
import 'power_pickup_marker.dart';
import 'premium_ludo_token.dart';

class LudoBoard extends StatelessWidget {
  const LudoBoard({
    this.activePlayerCount = 4,
    this.gameState,
    this.movableTokenIds = const <int>{},
    this.visualPathOverrides = const <int, int>{},
    this.movingTokenId,
    this.capturedTokenIds = const <int>{},
    this.shieldedTokenIds = const <int>{},
    this.powerPickupPositions = const <PowerType, int>{},
    this.onTokenTap,
    super.key,
  });

  final int activePlayerCount;
  final LudoGameState? gameState;
  final Set<int> movableTokenIds;
  final Map<int, int> visualPathOverrides;
  final int? movingTokenId;
  final Set<int> capturedTokenIds;
  final Set<int> shieldedTokenIds;
  final Map<PowerType, int> powerPickupPositions;
  final ValueChanged<int>? onTokenTap;

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
          final double tokenSize = cell * 0.9;
          final List<_TokenPlacement> placements =
              _placements(cell);

          return RepaintBoundary(
            child: SizedBox.square(
              dimension: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(
                    child: CustomPaint(
                      painter: _LudoBoardPainter(),
                    ),
                  ),
                  for (final MapEntry<PowerType, int> entry
                      in powerPickupPositions.entries)
                    Positioned(
                      left: (LudoBoardMap.commonPath[entry.value].column + 0.5) *
                              cell -
                          (cell * 0.3),
                      top: (LudoBoardMap.commonPath[entry.value].row + 0.5) *
                              cell -
                          (cell * 0.3),
                      child: PowerPickupMarker(
                        type: entry.key,
                        size: cell * 0.6,
                      ),
                    ),
                  for (final _TokenPlacement placement in placements)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 125),
                      curve: Curves.easeOut,
                      left: placement.center.dx - (tokenSize / 2),
                      top: placement.center.dy - (tokenSize * 0.58),
                      child: PremiumLudoToken(
                        key: ValueKey<int>(placement.tokenId),
                        color: placement.color,
                        size: tokenSize,
                        dimmed: placement.dimmed,
                        highlighted:
                            movableTokenIds.contains(placement.tokenId),
                        moving: movingTokenId == placement.tokenId,
                        captured:
                            capturedTokenIds.contains(placement.tokenId),
                        shielded:
                            shieldedTokenIds.contains(placement.tokenId),
                        onTap: movableTokenIds.contains(placement.tokenId) &&
                                onTokenTap != null
                            ? () => onTokenTap!(placement.tokenId)
                            : null,
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

  List<_TokenPlacement> _placements(double cell) {
    if (gameState == null) {
      return _previewPlacements(cell);
    }

    final List<_TokenPlacement> result = <_TokenPlacement>[];
    final Map<String, int> stackCounts = <String, int>{};

    for (final LudoPlayer player in gameState!.players) {
      for (int tokenIndex = 0;
          tokenIndex < player.tokens.length;
          tokenIndex++) {
        final LudoToken token = player.tokens[tokenIndex];
        Offset center;

        final int? visualProgress =
            visualPathOverrides[token.id];

        if (visualProgress == null &&
            token.status == TokenStatus.base) {
          center = _baseAnchor(
            player.color,
            tokenIndex,
            cell,
          );
        } else {
          final int pathPosition =
              visualProgress ?? token.pathPosition;
          final boardCell = LudoBoardMap.cellFor(
            color: player.color,
            pathPosition: pathPosition,
          );
          center = Offset(
            (boardCell.column + 0.5) * cell,
            (boardCell.row + 0.5) * cell,
          );

          final String key =
              '${boardCell.row}:${boardCell.column}';
          final int stackIndex = stackCounts[key] ?? 0;
          stackCounts[key] = stackIndex + 1;

          if (stackIndex > 0) {
            const List<Offset> offsets = <Offset>[
              Offset(-0.13, -0.10),
              Offset(0.13, -0.10),
              Offset(-0.13, 0.12),
              Offset(0.13, 0.12),
            ];
            final Offset delta =
                offsets[stackIndex % offsets.length];
            center += Offset(delta.dx * cell, delta.dy * cell);
          }
        }

        result.add(
          _TokenPlacement(
            tokenId: token.id,
            color: _colorFor(player.color),
            center: center,
          ),
        );
      }
    }

    return result;
  }

  List<_TokenPlacement> _previewPlacements(double cell) {
    final List<_TokenPlacement> result = <_TokenPlacement>[];
    const List<PlayerColor> colors = <PlayerColor>[
      PlayerColor.red,
      PlayerColor.green,
      PlayerColor.yellow,
      PlayerColor.blue,
    ];

    int tokenId = 0;
    for (int playerIndex = 0;
        playerIndex < colors.length;
        playerIndex++) {
      for (int tokenIndex = 0; tokenIndex < 4; tokenIndex++) {
        result.add(
          _TokenPlacement(
            tokenId: tokenId++,
            color: _colorFor(colors[playerIndex]),
            center: _baseAnchor(
              colors[playerIndex],
              tokenIndex,
              cell,
            ),
            dimmed: playerIndex >= activePlayerCount,
          ),
        );
      }
    }

    return result;
  }

  Offset _baseAnchor(
    PlayerColor color,
    int tokenIndex,
    double cell,
  ) {
    final List<Offset> positions = switch (color) {
      PlayerColor.red => const <Offset>[
          Offset(2, 2),
          Offset(4, 2),
          Offset(2, 4),
          Offset(4, 4),
        ],
      PlayerColor.green => const <Offset>[
          Offset(11, 2),
          Offset(13, 2),
          Offset(11, 4),
          Offset(13, 4),
        ],
      PlayerColor.yellow => const <Offset>[
          Offset(11, 11),
          Offset(13, 11),
          Offset(11, 13),
          Offset(13, 13),
        ],
      PlayerColor.blue => const <Offset>[
          Offset(2, 11),
          Offset(4, 11),
          Offset(2, 13),
          Offset(4, 13),
        ],
    };

    final Offset point = positions[tokenIndex % positions.length];
    return Offset(point.dx * cell, point.dy * cell);
  }

  Color _colorFor(PlayerColor color) {
    return switch (color) {
      PlayerColor.red => LudoGlobalColors.red,
      PlayerColor.green => LudoGlobalColors.green,
      PlayerColor.yellow => LudoGlobalColors.gold,
      PlayerColor.blue => LudoGlobalColors.electricBlue,
    };
  }
}

class _TokenPlacement {
  const _TokenPlacement({
    required this.tokenId,
    required this.color,
    required this.center,
    this.dimmed = false,
  });

  final int tokenId;
  final Color color;
  final Offset center;
  final bool dimmed;
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

    _drawBase(canvas, cell, const Offset(0, 0),
        LudoGlobalColors.red, borderPaint);
    _drawBase(canvas, cell, const Offset(9, 0),
        LudoGlobalColors.green, borderPaint);
    _drawBase(canvas, cell, const Offset(9, 9),
        LudoGlobalColors.gold, borderPaint);
    _drawBase(canvas, cell, const Offset(0, 9),
        LudoGlobalColors.electricBlue, borderPaint);

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
        for (int column = 1; column <= 5; column++)
          Offset(column.toDouble(), 7),
      ],
      color: LudoGlobalColors.red,
      borderPaint: borderPaint,
    );
    _fillLane(
      canvas,
      cell,
      cells: [
        for (int row = 1; row <= 5; row++)
          Offset(7, row.toDouble()),
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
        for (int row = 9; row <= 13; row++)
          Offset(7, row.toDouble()),
      ],
      color: LudoGlobalColors.electricBlue,
      borderPaint: borderPaint,
    );

    _drawStartCell(canvas, cell, 1, 6,
        LudoGlobalColors.red, borderPaint);
    _drawStartCell(canvas, cell, 8, 1,
        LudoGlobalColors.green, borderPaint);
    _drawStartCell(canvas, cell, 13, 8,
        LudoGlobalColors.gold, borderPaint);
    _drawStartCell(canvas, cell, 6, 13,
        LudoGlobalColors.electricBlue, borderPaint);

    _drawSafeCell(canvas, cell, 6, 2);
    _drawSafeCell(canvas, cell, 12, 6);
    _drawSafeCell(canvas, cell, 8, 12);
    _drawSafeCell(canvas, cell, 2, 8);

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
      RRect.fromRectAndRadius(
        innerRect,
        Radius.circular(cell * 0.55),
      ),
      Paint()..color = const Color(0xFFF8FBFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        innerRect,
        Radius.circular(cell * 0.55),
      ),
      borderPaint,
    );

    final List<Offset> holes = <Offset>[
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

  void _drawSafeCell(
    Canvas canvas,
    double cell,
    int column,
    int row,
  ) {
    final Offset center = Offset(
      (column + 0.5) * cell,
      (row + 0.5) * cell,
    );
    final Path star = Path();
    const int points = 5;
    for (int index = 0; index < points * 2; index++) {
      final double radius =
          index.isEven ? cell * 0.28 : cell * 0.12;
      final double angle =
          (-math.pi / 2) + (index * math.pi / points);
      final Offset p = center +
          Offset(math.cos(angle), math.sin(angle)) * radius;
      if (index == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();

    canvas.drawPath(
      star,
      Paint()..color = const Color(0xFF7E9AB8),
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

  void _drawOuterBorder(
    Canvas canvas,
    Size size,
    double cell,
  ) {
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
