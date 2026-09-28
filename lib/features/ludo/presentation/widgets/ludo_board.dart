import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/game_asset_paths.dart';
import '../../domain/engine/ludo_board_map.dart';
import '../../domain/entities/ludo_game_state.dart';
import '../../domain/entities/ludo_player.dart';
import '../../domain/entities/ludo_token.dart';
import '../../domain/entities/player_color.dart';
import '../../domain/entities/power_type.dart';
import '../../domain/entities/token_status.dart';
import '../style/ludo_reference_visuals.dart';
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
          final double tokenSize = cell * 1.45;
          final List<_TokenPlacement> placements = _placements(cell);
          final Widget pawnLayer = _buildPawnLayer(
            placements: placements,
            tokenSize: tokenSize,
          );

          return RepaintBoundary(
            child: SizedBox.square(
              dimension: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: SvgPicture.asset(
                      GameAssetPaths.ludoBoard,
                      fit: BoxFit.fill,
                    ),
                  ),
                  if (gameState != null)
                    ..._playerLabels(
                      players: gameState!.players,
                      cell: cell,
                    ),
                  for (final MapEntry<PowerType, int> entry
                      in powerPickupPositions.entries)
                    Positioned(
                      key: ValueKey<String>(
                        '${entry.key.name}-${entry.value}',
                      ),
                      left:
                          (LudoBoardMap.commonPath[entry.value].column + 0.5) *
                                  cell -
                              (cell * 0.31),
                      top: (LudoBoardMap.commonPath[entry.value].row + 0.5) *
                              cell -
                          (cell * 0.31),
                      child: PowerPickupMarker(
                        type: entry.key,
                        size: cell * 0.62,
                      ),
                    ),
                  Positioned.fill(child: pawnLayer),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPawnLayer({
    required List<_TokenPlacement> placements,
    required double tokenSize,
  }) {
    // Paint from the back of the board toward the viewer. This keeps a pawn
    // on a lower row visually in front of a pawn above it instead of letting
    // player iteration order decide which pawn covers the other.
    final List<_TokenPlacement> depthSortedPlacements =
        List<_TokenPlacement>.of(placements)
          ..sort((_TokenPlacement a, _TokenPlacement b) {
            final int vertical = a.center.dy.compareTo(b.center.dy);
            if (vertical != 0) {
              return vertical;
            }

            final int horizontal = a.center.dx.compareTo(b.center.dx);
            if (horizontal != 0) {
              return horizontal;
            }

            return a.tokenId.compareTo(b.tokenId);
          });

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        for (final _TokenPlacement placement in depthSortedPlacements)
          AnimatedPositioned(
            key: ValueKey<String>('token-position-${placement.tokenId}'),
            duration: returningTokenIds.contains(placement.tokenId)
                ? const Duration(milliseconds: 520)
                : const Duration(milliseconds: 155),
            curve: returningTokenIds.contains(placement.tokenId)
                ? Curves.easeInOutCubic
                : Curves.easeOutCubic,
            left: placement.center.dx - ((tokenSize * placement.scale) / 2),
            top: placement.center.dy - ((tokenSize * placement.scale) * 1.12),
            child: PremiumLudoToken(
              key: ValueKey<int>(placement.tokenId),
              playerColor: placement.playerColor,
              size: tokenSize * placement.scale,
              dimmed: placement.dimmed,
              highlighted: movableTokenIds.contains(placement.tokenId),
              moving: movingTokenId == placement.tokenId,
              movementStep: visualPathOverrides[placement.tokenId],
              captured: capturedTokenIds.contains(placement.tokenId),
              returning: returningTokenIds.contains(placement.tokenId),
              shielded: shieldedTokenIds.contains(placement.tokenId),
              onTap: movableTokenIds.contains(placement.tokenId) &&
                      onTokenTap != null
                  ? () => onTokenTap!(placement.tokenId)
                  : null,
            ),
          ),
      ],
    );
  }

  List<Widget> _playerLabels({
    required List<LudoPlayer> players,
    required double cell,
  }) {
    final List<Widget> labels = <Widget>[];

    for (final LudoPlayer player in players) {
      final int finished =
          player.tokens.where((token) => token.isFinished).length;
      final Widget label = _BoardPlayerLabel(
        playerName: player.name,
        progressLabel: '$finished/${player.tokens.length}',
        color: LudoReferenceVisuals.colorFor(player.color),
        darkColor: LudoReferenceVisuals.darkColorFor(player.color),
        height: cell * 0.60,
      );

      switch (player.color) {
        case PlayerColor.yellow:
          labels.add(
            Positioned(
              left: cell * 1.00,
              top: cell * 0.05,
              width: cell * 4.65,
              child: label,
            ),
          );
          break;
        case PlayerColor.blue:
          labels.add(
            Positioned(
              right: cell * 0.42,
              top: cell * 0.05,
              width: cell * 4.65,
              child: label,
            ),
          );
          break;
        case PlayerColor.red:
          labels.add(
            Positioned(
              right: cell * 0.42,
              bottom: cell * 0.08,
              width: cell * 4.65,
              child: label,
            ),
          );
          break;
        case PlayerColor.green:
          labels.add(
            Positioned(
              left: cell * 1.00,
              bottom: cell * 0.08,
              width: cell * 4.65,
              child: label,
            ),
          );
          break;
      }
    }

    return labels;
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

        final int? visualProgress = visualPathOverrides[token.id];

        double scale = 1;

        if (visualProgress == null && token.status == TokenStatus.base) {
          center = _baseAnchor(
            player.color,
            tokenIndex,
            cell,
          );
        } else {
          scale = 0.94;
          final int pathPosition = visualProgress ?? token.pathPosition;
          final boardCell = LudoBoardMap.cellFor(
            color: player.color,
            pathPosition: pathPosition,
          );
          center = Offset(
            (boardCell.column + 0.5) * cell,
            (boardCell.row + 0.5) * cell,
          );

          final String key = '${boardCell.row}:${boardCell.column}';
          final int stackIndex = stackCounts[key] ?? 0;
          stackCounts[key] = stackIndex + 1;

          if (stackIndex > 0) {
            scale = 0.78;
            const List<Offset> offsets = <Offset>[
              Offset(0.20, -0.10),
              Offset(-0.20, 0.11),
              Offset(0.20, 0.13),
              Offset(-0.20, -0.12),
            ];
            final Offset delta = offsets[(stackIndex - 1) % offsets.length];
            center += Offset(delta.dx * cell, delta.dy * cell);
          }
        }

        result.add(
          _TokenPlacement(
            tokenId: token.id,
            playerColor: player.color,
            center: center,
            scale: scale,
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
    final Set<PlayerColor> activeColors = switch (activePlayerCount) {
      2 => const <PlayerColor>{
          PlayerColor.red,
          PlayerColor.yellow,
        },
      3 => const <PlayerColor>{
          PlayerColor.red,
          PlayerColor.green,
          PlayerColor.yellow,
        },
      _ => PlayerColor.values.toSet(),
    };

    int tokenId = 0;
    for (int playerIndex = 0; playerIndex < colors.length; playerIndex++) {
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
            dimmed: !activeColors.contains(colors[playerIndex]),
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
      PlayerColor.yellow => const <Offset>[
          Offset(2, 2),
          Offset(4, 2),
          Offset(2, 4),
          Offset(4, 4),
        ],
      PlayerColor.blue => const <Offset>[
          Offset(11, 2),
          Offset(13, 2),
          Offset(11, 4),
          Offset(13, 4),
        ],
      PlayerColor.red => const <Offset>[
          Offset(11, 11),
          Offset(13, 11),
          Offset(11, 13),
          Offset(13, 13),
        ],
      PlayerColor.green => const <Offset>[
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

class _BoardPlayerLabel extends StatelessWidget {
  const _BoardPlayerLabel({
    required this.playerName,
    required this.progressLabel,
    required this.color,
    required this.darkColor,
    required this.height,
  });

  final String playerName;
  final String progressLabel;
  final Color color;
  final Color darkColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Container(
            height: height * 0.80,
            constraints: BoxConstraints(minWidth: height * 1.45),
            padding: EdgeInsets.symmetric(horizontal: height * 0.26),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: darkColor.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(height * 0.28),
            ),
            child: Text(
              progressLabel,
              style: TextStyle(
                color: Colors.white,
                fontSize: height * 0.41,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          SizedBox(width: height * 0.12),
          Expanded(
            child: Text(
              playerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: darkColor,
                fontSize: height * 0.66,
                fontWeight: FontWeight.w900,
                height: 1,
                shadows: <Shadow>[
                  Shadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenPlacement {
  const _TokenPlacement({
    required this.tokenId,
    required this.playerColor,
    required this.center,
    this.dimmed = false,
    this.scale = 1,
  });

  final int tokenId;
  final PlayerColor playerColor;
  final Offset center;
  final bool dimmed;
  final double scale;
}

// Retained temporarily as a reference for the legacy board geometry. The live
// board is rendered exclusively from GameAssetPaths.ludoBoard above.
// ignore: unused_element
class _LudoBoardPainter extends CustomPainter {
  const _LudoBoardPainter();

  static const Color _grid = Color(0xFFA9B4BF);
  static const Color _safeStar = Color(0xFF7CA5D0);

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / 15;
    final double radius = cell * 0.18;
    final RRect boardShape = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    canvas.drawRRect(
      boardShape.shift(Offset(0, cell * 0.10)),
      Paint()
        ..color = const Color(0x8A000514)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          5,
        ),
    );

    canvas.save();
    canvas.clipRRect(boardShape);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF7F8FA),
    );

    _drawBase(
      canvas,
      cell,
      const Offset(0, 0),
      PlayerColor.red,
    );
    _drawBase(
      canvas,
      cell,
      const Offset(9, 0),
      PlayerColor.green,
    );
    _drawBase(
      canvas,
      cell,
      const Offset(9, 9),
      PlayerColor.yellow,
    );
    _drawBase(
      canvas,
      cell,
      const Offset(0, 9),
      PlayerColor.blue,
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
          const Color(0xFFFBFCFD),
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
      engineColor: PlayerColor.red,
    );
    _fillLane(
      canvas,
      cell,
      cells: <Offset>[
        for (int row = 1; row <= 5; row++) Offset(7, row.toDouble()),
      ],
      engineColor: PlayerColor.green,
    );
    _fillLane(
      canvas,
      cell,
      cells: <Offset>[
        for (int column = 9; column <= 13; column++)
          Offset(column.toDouble(), 7),
      ],
      engineColor: PlayerColor.yellow,
    );
    _fillLane(
      canvas,
      cell,
      cells: <Offset>[
        for (int row = 9; row <= 13; row++) Offset(7, row.toDouble()),
      ],
      engineColor: PlayerColor.blue,
    );

    _drawStartCell(canvas, cell, 1, 6, PlayerColor.red);
    _drawStartCell(canvas, cell, 8, 1, PlayerColor.green);
    _drawStartCell(canvas, cell, 13, 8, PlayerColor.yellow);
    _drawStartCell(canvas, cell, 6, 13, PlayerColor.blue);

    _drawSafeStar(canvas, cell, 2, 8);
    _drawSafeStar(canvas, cell, 6, 2);
    _drawSafeStar(canvas, cell, 12, 6);
    _drawSafeStar(canvas, cell, 8, 12);

    _drawDirectionArrow(
      canvas,
      cell,
      column: 0,
      row: 7,
      direction: _ArrowDirection.right,
      color: LudoReferenceVisuals.darkColorFor(PlayerColor.red),
    );
    _drawDirectionArrow(
      canvas,
      cell,
      column: 7,
      row: 0,
      direction: _ArrowDirection.down,
      color: LudoReferenceVisuals.darkColorFor(PlayerColor.green),
    );
    _drawDirectionArrow(
      canvas,
      cell,
      column: 14,
      row: 7,
      direction: _ArrowDirection.left,
      color: LudoReferenceVisuals.darkColorFor(PlayerColor.yellow),
    );
    _drawDirectionArrow(
      canvas,
      cell,
      column: 7,
      row: 14,
      direction: _ArrowDirection.up,
      color: LudoReferenceVisuals.darkColorFor(PlayerColor.blue),
    );

    _drawCenter(canvas, cell);

    canvas.restore();
    _drawOuterBorder(canvas, size, cell);
  }

  void _drawBase(
    Canvas canvas,
    double cell,
    Offset origin,
    PlayerColor engineColor,
  ) {
    final Color color = LudoReferenceVisuals.colorFor(engineColor);
    final Color dark = LudoReferenceVisuals.darkColorFor(engineColor);
    final Color soft = LudoReferenceVisuals.softColorFor(engineColor);

    final Rect baseRect = Rect.fromLTWH(
      origin.dx * cell,
      origin.dy * cell,
      cell * 6,
      cell * 6,
    );

    canvas.drawRect(
      baseRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            soft,
            color,
            dark.withValues(alpha: 0.92),
          ],
          stops: const <double>[0, 0.64, 1],
        ).createShader(baseRect),
    );

    canvas.drawRect(
      baseRect,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-1, -0.9),
          end: const Alignment(1, 0.9),
          colors: <Color>[
            Colors.white.withValues(alpha: 0.10),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.055),
          ],
          stops: const <double>[0, 0.52, 1],
        ).createShader(baseRect),
    );

    final Rect innerRect = Rect.fromLTWH(
      (origin.dx + 0.90) * cell,
      (origin.dy + 0.88) * cell,
      cell * 4.20,
      cell * 4.20,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        innerRect.shift(Offset(0, cell * 0.08)),
        Radius.circular(cell * 0.24),
      ),
      Paint()..color = const Color(0x35000000),
    );

    final RRect inner = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(cell * 0.24),
    );

    canvas.drawRRect(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            dark.withValues(alpha: 0.70),
            dark.withValues(alpha: 0.86),
          ],
        ).createShader(innerRect),
    );

    canvas.drawRRect(
      inner,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
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
        center.translate(0, cell * 0.04),
        cell * 0.38,
        Paint()..color = Colors.black.withValues(alpha: 0.14),
      );
      canvas.drawCircle(
        center,
        cell * 0.35,
        Paint()..color = dark.withValues(alpha: 0.30),
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
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFF7F8FA),
            Color(0xFFE8ECF0),
          ],
          stops: <double>[0, 0.66, 1],
        ).createShader(rect),
    );

    canvas.drawLine(
      rect.topLeft.translate(1, 1),
      rect.topRight.translate(-1, 1),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.78)
        ..strokeWidth = 1.15,
    );

    canvas.drawLine(
      rect.bottomLeft.translate(1, -1),
      rect.bottomRight.translate(-1, -1),
      Paint()
        ..color = const Color(0xFFC9D1D9)
        ..strokeWidth = 1.15,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..color = _grid
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.72,
    );
  }

  void _fillLane(
    Canvas canvas,
    double cell, {
    required List<Offset> cells,
    required PlayerColor engineColor,
  }) {
    final Color color = LudoReferenceVisuals.colorFor(engineColor);
    final Color dark = LudoReferenceVisuals.darkColorFor(engineColor);

    for (final Offset point in cells) {
      final Rect rect = Rect.fromLTWH(
        point.dx * cell,
        point.dy * cell,
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
              color,
              Color.lerp(color, dark, 0.18)!,
            ],
          ).createShader(rect),
      );

      canvas.drawRect(
        rect,
        Paint()
          ..color = _grid
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.72,
      );

      canvas.drawLine(
        rect.topLeft.translate(1, 1),
        rect.topRight.translate(-1, 1),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.34)
          ..strokeWidth = 1,
      );
    }
  }

  void _drawStartCell(
    Canvas canvas,
    double cell,
    int column,
    int row,
    PlayerColor engineColor,
  ) {
    final Color color = LudoReferenceVisuals.colorFor(engineColor);
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
            LudoReferenceVisuals.softColorFor(engineColor),
            color,
          ],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..color = _grid
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.72,
    );

    _drawStar(
      canvas,
      rect.center,
      cell * 0.31,
      LudoReferenceVisuals.darkColorFor(engineColor),
    );
  }

  void _drawSafeStar(
    Canvas canvas,
    double cell,
    int column,
    int row,
  ) {
    final Offset center = Offset(
      (column + 0.5) * cell,
      (row + 0.5) * cell,
    );
    _drawStar(canvas, center, cell * 0.31, _safeStar);
  }

  void _drawStar(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final Path star = Path();
    const int points = 5;

    for (int index = 0; index < points * 2; index++) {
      final double r = index.isEven ? radius : radius * 0.46;
      final double angle = (-math.pi / 2) + (index * math.pi / points);
      final Offset point =
          center + Offset(math.cos(angle), math.sin(angle)) * r;

      if (index == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    star.close();

    canvas.drawPath(
      star,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawPath(star, Paint()..color = color);
  }

  void _drawDirectionArrow(
    Canvas canvas,
    double cell, {
    required int column,
    required int row,
    required _ArrowDirection direction,
    required Color color,
  }) {
    final Offset center = Offset(
      (column + 0.5) * cell,
      (row + 0.5) * cell,
    );
    final double shaft = cell * 0.28;
    final double head = cell * 0.19;

    Offset start;
    Offset end;
    switch (direction) {
      case _ArrowDirection.right:
        start = center.translate(-shaft, 0);
        end = center.translate(shaft, 0);
        break;
      case _ArrowDirection.left:
        start = center.translate(shaft, 0);
        end = center.translate(-shaft, 0);
        break;
      case _ArrowDirection.down:
        start = center.translate(0, -shaft);
        end = center.translate(0, shaft);
        break;
      case _ArrowDirection.up:
        start = center.translate(0, shaft);
        end = center.translate(0, -shaft);
        break;
    }

    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..strokeWidth = cell * 0.075
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, paint);

    final Path arrowHead = Path();
    switch (direction) {
      case _ArrowDirection.right:
        arrowHead
          ..moveTo(end.dx, end.dy)
          ..lineTo(end.dx - head, end.dy - head)
          ..lineTo(end.dx - head, end.dy + head);
        break;
      case _ArrowDirection.left:
        arrowHead
          ..moveTo(end.dx, end.dy)
          ..lineTo(end.dx + head, end.dy - head)
          ..lineTo(end.dx + head, end.dy + head);
        break;
      case _ArrowDirection.down:
        arrowHead
          ..moveTo(end.dx, end.dy)
          ..lineTo(end.dx - head, end.dy - head)
          ..lineTo(end.dx + head, end.dy - head);
        break;
      case _ArrowDirection.up:
        arrowHead
          ..moveTo(end.dx, end.dy)
          ..lineTo(end.dx - head, end.dy + head)
          ..lineTo(end.dx + head, end.dy + head);
        break;
    }
    arrowHead.close();
    canvas.drawPath(arrowHead, Paint()..color = color.withValues(alpha: 0.72));
  }

  void _drawCenter(Canvas canvas, double cell) {
    final Rect rect = Rect.fromLTWH(
      6 * cell,
      6 * cell,
      3 * cell,
      3 * cell,
    );
    final Offset center = rect.center;

    final Path top = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(center.dx, center.dy)
      ..close();
    final Path right = Path()
      ..moveTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(center.dx, center.dy)
      ..close();
    final Path bottom = Path()
      ..moveTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(center.dx, center.dy)
      ..close();
    final Path left = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top)
      ..lineTo(center.dx, center.dy)
      ..close();

    canvas.drawPath(
      top,
      Paint()..color = LudoReferenceVisuals.colorFor(PlayerColor.green),
    );
    canvas.drawPath(
      right,
      Paint()..color = LudoReferenceVisuals.colorFor(PlayerColor.yellow),
    );
    canvas.drawPath(
      bottom,
      Paint()..color = LudoReferenceVisuals.colorFor(PlayerColor.blue),
    );
    canvas.drawPath(
      left,
      Paint()..color = LudoReferenceVisuals.colorFor(PlayerColor.red),
    );
  }

  void _drawOuterBorder(
    Canvas canvas,
    Size size,
    double cell,
  ) {
    final RRect border = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        cell * 0.04,
        cell * 0.04,
        size.width - cell * 0.08,
        size.height - cell * 0.08,
      ),
      Radius.circular(cell * 0.16),
    );

    canvas.drawRRect(
      border,
      Paint()
        ..color = const Color(0xFF344758)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.105,
    );

    final RRect inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        cell * 0.10,
        cell * 0.10,
        size.width - cell * 0.20,
        size.height - cell * 0.20,
      ),
      Radius.circular(cell * 0.13),
    );

    canvas.drawRRect(
      inner,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant _LudoBoardPainter oldDelegate) => false;
}

enum _ArrowDirection {
  right,
  left,
  down,
  up,
}
