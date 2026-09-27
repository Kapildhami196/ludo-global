import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/ludo_game_state.dart';
import '../../domain/entities/player_color.dart';
import '../style/ludo_reference_visuals.dart';
import 'player_dice_slot.dart';
import 'player_game_panel.dart';

class GameBoardStage extends StatelessWidget {
  const GameBoardStage({
    required this.gameState,
    required this.board,
    required this.diceValue,
    required this.diceRolling,
    required this.diceEnabled,
    required this.onRoll,
    this.computerPlayerIds = const <String>{},
    super.key,
  });

  final LudoGameState gameState;
  final Widget board;
  final int diceValue;
  final bool diceRolling;
  final bool diceEnabled;
  final VoidCallback onRoll;
  final Set<String> computerPlayerIds;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        // Keep the whole gameplay scene on one screen. The board is centered
        // inside the available stage and scales down only when vertical space
        // is tighter (small phones / Power mode).
        final double boardSize = math.min(
          width * 0.985,
          height / 1.30,
        );
        final double boardLeft = (width - boardSize) / 2;
        final double boardTop = (height - boardSize) / 2;
        final double cell = boardSize / 15;

        final double avatarSize = cell * 1.58;
        final double diceSize = cell * 2.55;
        final double edgeInset = cell * 0.20;
        final double hudGap = cell * 0.10;
        final Color activeColor =
            LudoReferenceVisuals.colorFor(gameState.currentPlayer.color);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: boardLeft,
              top: boardTop + cell * 0.085,
              width: boardSize,
              height: boardSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cell * 0.17),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x78000000),
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: boardLeft,
              top: boardTop,
              width: boardSize,
              height: boardSize,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cell * 0.17),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                    if (diceRolling)
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.13),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: RepaintBoundary(child: board),
              ),
            ),
            for (final player in gameState.players)
              ..._hudForPlayer(
                playerId: player.id,
                color: player.color,
                boardLeft: boardLeft,
                boardTop: boardTop,
                boardSize: boardSize,
                avatarSize: avatarSize,
                diceSize: diceSize,
                edgeInset: edgeInset,
                hudGap: hudGap,
              ),
          ],
        );
      },
    );
  }

  List<Widget> _hudForPlayer({
    required String playerId,
    required PlayerColor color,
    required double boardLeft,
    required double boardTop,
    required double boardSize,
    required double avatarSize,
    required double diceSize,
    required double edgeInset,
    required double hudGap,
  }) {
    final player =
        gameState.players.firstWhere((candidate) => candidate.id == playerId);
    final bool active = playerId == gameState.currentPlayer.id;
    final bool alignRight =
        color == PlayerColor.green || color == PlayerColor.yellow;
    final bool top =
        color == PlayerColor.red || color == PlayerColor.green;

    final double cell = boardSize / 15;
    final double avatarX = alignRight
        ? boardLeft + boardSize - edgeInset - avatarSize
        : boardLeft + edgeInset;
    final double avatarY = top
        ? boardTop - avatarSize - cell * 0.28
        : boardTop + boardSize + cell * 0.22;

    final double diceWidth = diceSize * 1.18;
    final double diceX = alignRight
        ? avatarX - diceWidth - hudGap
        : avatarX + avatarSize + hudGap;
    final double diceY =
        avatarY + ((avatarSize - diceSize) / 2);

    // Reference behavior: the die rolls mostly vertically toward the viewer,
    // not in a large circular orbit across the board.
    final Offset launchDirection = Offset(
      alignRight ? -0.18 : 0.18,
      top ? 0.30 : -0.30,
    );

    final List<Widget> result = <Widget>[
      Positioned(
        left: avatarX,
        top: avatarY,
        width: avatarSize,
        height: avatarSize,
        child: PlayerGamePanel(
          player: player,
          active: active,
          isComputer: computerPlayerIds.contains(playerId),
          consecutiveSixes:
              active ? gameState.consecutiveSixes : 0,
          alignRight: alignRight,
          size: avatarSize,
        ),
      ),
    ];

    if (active) {
      result.add(
        Positioned(
          left: diceX,
          top: diceY,
          child: PlayerDiceSlot(
            color: color,
            active: true,
            value: diceValue,
            rolling: diceRolling,
            enabled: diceEnabled,
            onRoll: onRoll,
            size: diceSize,
            launchDirection: launchDirection,
            tailOnRight: alignRight,
          ),
        ),
      );
    }

    return result;
  }
}
