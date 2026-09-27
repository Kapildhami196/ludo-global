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
      aspectRatio: 0.78,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double boardSize = width;
          final double cell = width / 15;
          final double boardTop = width * 0.145;
          final double avatarSize = cell * 1.68;
          final double diceSize = cell * 2.10;
          final double edgeInset = width * 0.025;
          final double hudGap = cell * 0.34;
          final Color activeColor =
              LudoReferenceVisuals.colorFor(gameState.currentPlayer.color);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: boardTop + cell * 0.08,
                width: boardSize,
                height: boardSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cell * 0.18),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x70000000),
                        blurRadius: 8,
                        offset: Offset(0, 5),
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
                      if (diceRolling)
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.16),
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

    final double avatarX = alignRight
        ? boardSize - edgeInset - avatarSize
        : edgeInset;
    final double avatarY = top
        ? boardTop - avatarSize - (boardSize / 15) * 0.22
        : boardTop + boardSize + (boardSize / 15) * 0.20;

    final double diceWidth = diceSize * 1.18;
    final double diceX = alignRight
        ? avatarX - diceWidth - hudGap
        : avatarX + avatarSize + hudGap;
    final double diceY =
        avatarY + ((avatarSize - diceSize) / 2);

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
            tailOnRight: alignRight,
          ),
        ),
      );
    }

    return result;
  }
}
