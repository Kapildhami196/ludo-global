import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_global/features/ludo/domain/entities/game_phase.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_game_state.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_player.dart';
import 'package:ludo_global/features/ludo/domain/entities/ludo_token.dart';
import 'package:ludo_global/features/ludo/domain/entities/player_color.dart';
import 'package:ludo_global/features/ludo/domain/entities/token_status.dart';
import 'package:ludo_global/features/ludo/presentation/widgets/ludo_board.dart';

void main() {
  testWidgets(
    'movable pawn remains tappable when overlapped by a non-movable opponent',
    (WidgetTester tester) async {
      int? tappedTokenId;

      const LudoGameState state = LudoGameState(
        players: <LudoPlayer>[
          LudoPlayer(
            id: 'red',
            name: 'Red',
            color: PlayerColor.red,
            tokens: <LudoToken>[
              LudoToken(
                id: 0,
                color: PlayerColor.red,
                pathPosition: 13,
                status: TokenStatus.active,
              ),
            ],
          ),
          LudoPlayer(
            id: 'green',
            name: 'Green',
            color: PlayerColor.green,
            tokens: <LudoToken>[
              LudoToken(
                id: 4,
                color: PlayerColor.green,
                pathPosition: 0,
                status: TokenStatus.active,
              ),
            ],
          ),
        ],
        currentPlayerIndex: 0,
        phase: GamePhase.selectingToken,
        mode: LudoGameMode.normal,
        diceValue: 1,
        movableTokenIds: <int>[0],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 300,
                child: LudoBoard(
                  gameState: state,
                  movableTokenIds: const <int>{0},
                  onTokenTap: (int tokenId) {
                    tappedTokenId = tokenId;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Finder boardFinder = find.byType(LudoBoard);
      final Rect boardRect = tester.getRect(boardFinder);
      final double cell = boardRect.width / 15;

      // Red progress 13 and Green progress 0 both map to global safe/start
      // index 39. Tap the shared cell center. The non-movable green pawn
      // must never intercept the red pawn's input.
      final Offset sharedCellCenter = Offset(
        boardRect.left + (6.5 * cell),
        boardRect.top + (13.5 * cell),
      );

      await tester.tapAt(sharedCellCenter);
      await tester.pump();

      expect(tappedTokenId, 0);
    },
  );
}
