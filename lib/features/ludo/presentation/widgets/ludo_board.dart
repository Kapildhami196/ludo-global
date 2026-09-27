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
import 'board_decoration_layer.dart';
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
    this.returningTokenIds = const <int>{},
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
  final Set<int> returningTokenIds;
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
          final double tokenSize = cell * 0.62;
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
                  const Positioned.fill(
                    child: BoardDecorationLayer(),
                  ),
                  for (final MapEntry<PowerType, int> entry
                      in powerPickupPositions.entries)
                    Positioned(
                      key: ValueKey<String>(
                        '${entry.key.name}-${entry.value}',
                      ),
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
                      duration: returningTokenIds.contains(placement.tokenId)
                          ? const Duration(milliseconds: 520)
                          : const Duration(milliseconds: 120),
                      curve: returningTokenIds.contains(placement.tokenId)
                          ? Curves.easeInOutCubic
                          : Curves.easeOutCubic,
                      left: placement.center.dx - (tokenSize / 2),
                      top: placement.center.dy - (tokenSize * 1.12),
                      child: PremiumLudoToken(
                        key: ValueKey<int>(placement.tokenId),
                        playerColor: placement.playerColor,
                        size: tokenSize,
                        dimmed: placement.dimmed,
                        highlighted:
                            movableTokenIds.contains(placement.tokenId),
                        moving: movingTokenId == placement.tokenId,
                        captured:
                            capturedTokenIds.contains(placement.tokenId),
                        returning:
                            returningTokenIds.contains(placement.tokenId),
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
            playerColor: player.color,
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
            playerColor: colors[playerIndex],
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
}

class _TokenPlacement {
  const _TokenPlacement({
    required this.tokenId,
    required this.playerColor,
    required this.center,
    this.dimmed = false,
  });

  final int tokenId;
  final PlayerColor playerColor;
  final Offset center;
  final bool dimmed;
}

class _LudoBoardPainter extends CustomPainter {
  const _LudoBoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / 15;
    final RRect boardShape = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(cell * 0.52),
    );

    canvas.drawRRect(
      boardShape.shift(Offset(0, cell * 0.18)),
      Paint()
        ..color = const Color(0xAA000817)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          8,
        ),
    );

    canvas.save();
    canvas.clipRRect(boardShape);

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFDFEFF),
            Color(0xFFEAF1F7),
            Color(0xFFC9D7E4),
          ],
        ).createShader(Offset.zero & size),
    );

    _drawBase(
      canvas,
      cell,
      const Offset(0, 0),
      LudoGlobalColors.red,
    );
    _drawBase(
      canvas,
      cell,
      const Offset(9, 0),
      LudoGlobalColors.green,
    );
    _drawBase(
      canvas,
      cell,
      const Offset(9, 9),
      LudoGlobalColors.gold,
    );
    _drawBase(
      canvas,
      cell,
      const Offset(0, 9),
      LudoGlobalColors.electricBlue,
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

        _drawTrackCell(
          canvas,
          cell,
          column,
          row,
          const Color(0xFFF9FBFC),
        );
      }
    }

    _fillLane(
      canvas,
      cell,
      cells: <Offset>[
        for (int column = 1; column <= 5; column++)
          Offset(column.toDouble(), 7),
      ],
      color: LudoGlobalColors.red,
    );
    _fillLane(
      canvas,
      cell,
      cells: <Offset>[
        for (int row = 1; row <= 5; row++)
          Offset(7, row.toDouble()),
      ],
      color: LudoGlobalColors.green,
    );
    _fillLane(
      canvas,
      cell,
      cells: <Offset>[
        for (int column = 9; column <= 13; column++)
          Offset(column.toDouble(), 7),
      ],
      color: LudoGlobalColors.gold,
    );
    _fillLane(
      canvas,
      cell,
      cells: <Offset>[
        for (int row = 9; row <= 13; row++)
          Offset(7, row.toDouble()),
      ],
      color: LudoGlobalColors.electricBlue,
    );

    _drawStartCell(
      canvas,
      cell,
      1,
      6,
      LudoGlobalColors.red,
    );
    _drawStartCell(
      canvas,
      cell,
      8,
      1,
      LudoGlobalColors.green,
    );
    _drawStartCell(
      canvas,
      cell,
      13,
      8,
      LudoGlobalColors.gold,
    );
    _drawStartCell(
      canvas,
      cell,
      6,
      13,
      LudoGlobalColors.electricBlue,
    );

    _drawSafeCell(canvas, cell, 6, 2);
    _drawSafeCell(canvas, cell, 12, 6);
    _drawSafeCell(canvas, cell, 8, 12);
    _drawSafeCell(canvas, cell, 2, 8);

    _drawCenter(canvas, cell);

    canvas.restore();

    _drawOuterBorder(canvas, size, cell);
  }

  void _drawBase(
    Canvas canvas,
    double cell,
    Offset origin,
    Color color,
  ) {
    final Rect baseRect = Rect.fromLTWH(
      origin.dx * cell,
      origin.dy * cell,
      cell * 6,
      cell * 6,
    );

    final HSLColor hsl = HSLColor.fromColor(color);
    final Color dark = hsl
        .withLightness(
          (hsl.lightness - 0.20).clamp(0.0, 1.0).toDouble(),
        )
        .toColor();
    final Color light = hsl
        .withLightness(
          (hsl.lightness + 0.17).clamp(0.0, 1.0).toDouble(),
        )
        .toColor();

    canvas.drawRect(
      baseRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[light, color, dark],
        ).createShader(baseRect),
    );

    final Rect panelShadow = Rect.fromLTWH(
      (origin.dx + 0.86) * cell,
      (origin.dy + 0.96) * cell,
      cell * 4.28,
      cell * 4.28,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        panelShadow,
        Radius.circular(cell * 0.52),
      ),
      Paint()..color = const Color(0x55000A18),
    );

    final Rect innerRect = Rect.fromLTWH(
      (origin.dx + 0.78) * cell,
      (origin.dy + 0.78) * cell,
      cell * 4.28,
      cell * 4.28,
    );
    final RRect inner = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(cell * 0.54),
    );

    canvas.drawRRect(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            light.withValues(alpha: 0.98),
            color,
            dark,
          ],
          stops: const <double>[0, 0.55, 1],
        ).createShader(innerRect),
    );

    canvas.drawRRect(
      inner,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final List<Offset> holes = <Offset>[
      Offset(origin.dx + 2, origin.dy + 2),
      Offset(origin.dx + 4, origin.dy + 2),
      Offset(origin.dx + 2, origin.dy + 4),
      Offset(origin.dx + 4, origin.dy + 4),
    ];

    for (final Offset hole in holes) {
      final Offset center = Offset(hole.dx * cell, hole.dy * cell);
      canvas.drawCircle(
        center.translate(0, cell * 0.07),
        cell * 0.46,
        Paint()..color = const Color(0x66000816),
      );
      canvas.drawCircle(
        center,
        cell * 0.43,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.35),
            colors: <Color>[
              color.withValues(alpha: 0.20),
              dark.withValues(alpha: 0.48),
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: cell * 0.43),
          ),
      );
      canvas.drawCircle(
        center,
        cell * 0.43,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _drawTrackCell(
    Canvas canvas,
    double cell,
    int column,
    int row,
    Color color,
  ) {
    final Rect rect = Rect.fromLTWH(
      column * cell,
      row * cell,
      cell,
      cell,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white,
            color,
            const Color(0xFFD4DEE7),
          ],
          stops: const <double>[0, 0.64, 1],
        ).createShader(rect),
    );

    final Paint grid = Paint()
      ..color = const Color(0xFF7F93A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.72;
    canvas.drawRect(rect, grid);

    canvas.drawLine(
      rect.topLeft.translate(1, 1),
      rect.topRight.translate(-1, 1),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.76)
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      rect.bottomLeft.translate(1, -1),
      rect.bottomRight.translate(-1, -1),
      Paint()
        ..color = const Color(0x55728AA0)
        ..strokeWidth = 1.15,
    );
  }

  void _fillLane(
    Canvas canvas,
    double cell, {
    required List<Offset> cells,
    required Color color,
  }) {
    for (final Offset point in cells) {
      final Rect rect = Rect.fromLTWH(
        point.dx * cell,
        point.dy * cell,
        cell,
        cell,
      );
      final HSLColor hsl = HSLColor.fromColor(color);
      final Color light = hsl
          .withLightness(
            (hsl.lightness + 0.18).clamp(0.0, 1.0).toDouble(),
          )
          .toColor();

      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[light, color],
          ).createShader(rect),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = const Color(0xFF5D7085)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.75,
      );
      canvas.drawLine(
        rect.topLeft.translate(1, 1),
        rect.topRight.translate(-1, 1),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.42)
          ..strokeWidth = 0.9,
      );
    }
  }

  void _drawStartCell(
    Canvas canvas,
    double cell,
    int column,
    int row,
    Color color,
  ) {
    final Rect rect = Rect.fromLTWH(
      column * cell,
      row * cell,
      cell,
      cell,
    );
    _drawTrackCell(canvas, cell, column, row, color);
    canvas.drawCircle(
      rect.center,
      cell * 0.17,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.white,
            Colors.white.withValues(alpha: 0.35),
          ],
        ).createShader(rect),
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
          index.isEven ? cell * 0.29 : cell * 0.13;
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
      star.shift(Offset(0, cell * 0.05)),
      Paint()..color = const Color(0x55708498),
    );
    canvas.drawPath(
      star,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFCBD7E2),
            Color(0xFF738AA1),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: cell * 0.30),
        ),
    );
    canvas.drawPath(
      star,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
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

    final List<(Color, Path)> triangles = <(Color, Path)>[
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
      final HSLColor hsl = HSLColor.fromColor(color);
      final Color light = hsl
          .withLightness(
            (hsl.lightness + 0.18).clamp(0.0, 1.0).toDouble(),
          )
          .toColor();

      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[light, color],
          ).createShader(center),
      );
    }

    final Rect medallion = Rect.fromCircle(
      center: c,
      radius: cell * 0.57,
    );
    canvas.drawCircle(
      c.translate(0, cell * 0.08),
      cell * 0.58,
      Paint()..color = const Color(0x66000000),
    );
    canvas.drawCircle(
      c,
      cell * 0.56,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.30, -0.32),
          colors: <Color>[
            Color(0xFFFFF29B),
            Color(0xFFFFC72E),
            Color(0xFFCE7800),
          ],
        ).createShader(medallion),
    );
    canvas.drawCircle(
      c,
      cell * 0.56,
      Paint()
        ..color = const Color(0xFFFFF1A0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    final TextPainter crown = TextPainter(
      text: TextSpan(
        text: '♛',
        style: TextStyle(
          color: const Color(0xFF7B4100),
          fontSize: cell * 0.82,
          fontWeight: FontWeight.w900,
          shadows: const <Shadow>[
            Shadow(
              color: Colors.white,
              blurRadius: 1,
              offset: Offset(0, -0.5),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    crown.paint(
      canvas,
      Offset(
        c.dx - crown.width / 2,
        c.dy - crown.height / 2 - cell * 0.03,
      ),
    );
  }

  void _drawOuterBorder(
    Canvas canvas,
    Size size,
    double cell,
  ) {
    final RRect border = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(cell * 0.52),
    );
    canvas.drawRRect(
      border,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFF4BB),
            Color(0xFFB57A20),
            Color(0xFF344B63),
          ],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cell * 0.10,
          cell * 0.10,
          size.width - cell * 0.20,
          size.height - cell * 0.20,
        ),
        Radius.circular(cell * 0.44),
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant _LudoBoardPainter oldDelegate) => false;
}
