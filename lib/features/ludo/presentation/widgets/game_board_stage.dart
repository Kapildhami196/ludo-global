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
    return AspectRatio(
      aspectRatio: 0.66,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double boardSize = width;
          final double cell = width / 15;

          // The reference game keeps a large breathing area above the board,
          // placing the board visually around the middle of the screen rather
          // than immediately below the header.
          final double boardTop = width * 0.34;
          final double avatarSize = cell * 1.76;
          final double diceSize = cell * 2.34;
          final double edgeInset = width * 0.026;
          final double hudGap = cell * 0.18;
          final Color activeColor =
              LudoReferenceVisuals.colorFor(gameState.currentPlayer.color);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: boardTop + cell * 0.09,
                width: boardSize,
                height: boardSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cell * 0.18),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x76000000),
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: boardTop,
                width: boardSize,
                height: boardSize,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cell * 0.18),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.17),
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                      if (diceRolling)
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.17),
                          blurRadius: 18,
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
      ),
    );
  }

  List<Widget> _hudForPlayer({
    required String playerId,
    required PlayerColor color,
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
        ? boardSize - edgeInset - avatarSize
        : edgeInset;
    final double avatarY = top
        ? boardTop - avatarSize - cell * 0.30
        : boardTop + boardSize + cell * 0.24;

    final double diceWidth = diceSize * 1.20;
    final double diceX = alignRight
        ? avatarX - diceWidth - hudGap
        : avatarX + avatarSize + hudGap;
    final double diceY =
        avatarY + ((avatarSize - diceSize) / 2);

    // The die launches diagonally from the active player's slot toward the
    // center of the play field while scaling toward the viewer.
    final Offset launchDirection = Offset(
      alignRight ? -0.78 : 0.78,
      top ? 0.92 : -0.92,
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
