import 'package:flutter/material.dart';

import '../../../../core/theme/ludo_global_tokens.dart';
import '../../domain/entities/ludo_game_state.dart';
import '../../domain/entities/player_color.dart';
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
      aspectRatio: 0.84,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;
          final double boardSize = width;
          final double panelWidth = width * 0.34;
          final double panelGap = width * 0.012;
          final double diceSize = (width / 15) * 1.46;
          final double boardTop = (height - boardSize) / 2;
          final Color activeColor =
              _colorFor(gameState.currentPlayer.color);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: boardTop + width * 0.018,
                width: boardSize,
                height: boardSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width * 0.035),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0xB0000612),
                        blurRadius: 24,
                        spreadRadius: 4,
                        offset: Offset(0, 10),
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
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width * 0.035),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: activeColor.withValues(
                          alpha: diceRolling ? 0.34 : 0.17,
                        ),
                        blurRadius: diceRolling ? 30 : 18,
                        spreadRadius: diceRolling ? 3 : 1,
                      ),
                    ],
                  ),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    scale: diceRolling ? 0.996 : 1,
                    child: RepaintBoundary(
                      child: board,
                    ),
                  ),
                ),
              ),
              for (final player in gameState.players)
                ..._hudForPlayer(
                  playerId: player.id,
                  color: player.color,
                  panelWidth: panelWidth,
                  panelGap: panelGap,
                  boardTop: boardTop,
                  boardSize: boardSize,
                  diceSize: diceSize,
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
    required double panelWidth,
    required double panelGap,
    required double boardTop,
    required double boardSize,
    required double diceSize,
  }) {
    final player =
        gameState.players.firstWhere((candidate) => candidate.id == playerId);
    final bool active = playerId == gameState.currentPlayer.id;
    final bool alignRight =
        color == PlayerColor.green || color == PlayerColor.yellow;
    final bool top =
        color == PlayerColor.red || color == PlayerColor.green;
    final double panelY =
        top ? 0 : boardTop + boardSize + 5;
    final double panelX =
        alignRight ? boardSize - panelWidth : 0;
    final double diceX = alignRight
        ? panelX - diceSize - panelGap
        : panelX + panelWidth + panelGap;
    final double diceY = panelY + 1;

    return <Widget>[
      Positioned(
        left: panelX,
        top: panelY,
        width: panelWidth,
        child: PlayerGamePanel(
          player: player,
          active: active,
          isComputer: computerPlayerIds.contains(playerId),
          consecutiveSixes:
              active ? gameState.consecutiveSixes : 0,
          alignRight: alignRight,
        ),
      ),
      Positioned(
        left: diceX,
        top: diceY,
        child: PlayerDiceSlot(
          color: color,
          active: active,
          value: diceValue,
          rolling: active && diceRolling,
          enabled: active && diceEnabled,
          onRoll: onRoll,
          size: diceSize,
        ),
      ),
    ];
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
