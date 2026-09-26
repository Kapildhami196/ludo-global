import '../entities/board_cell.dart';
import '../entities/player_color.dart';
import '../rules/classic_rules.dart';

abstract final class LudoBoardMap {
  /// Canonical clockwise shared path. Red starts at global index 0.
  static const List<BoardCell> commonPath = <BoardCell>[
    BoardCell(row: 6, column: 1),
    BoardCell(row: 6, column: 2),
    BoardCell(row: 6, column: 3),
    BoardCell(row: 6, column: 4),
    BoardCell(row: 6, column: 5),
    BoardCell(row: 5, column: 6),
    BoardCell(row: 4, column: 6),
    BoardCell(row: 3, column: 6),
    BoardCell(row: 2, column: 6),
    BoardCell(row: 1, column: 6),
    BoardCell(row: 0, column: 6),
    BoardCell(row: 0, column: 7),
    BoardCell(row: 0, column: 8),
    BoardCell(row: 1, column: 8),
    BoardCell(row: 2, column: 8),
    BoardCell(row: 3, column: 8),
    BoardCell(row: 4, column: 8),
    BoardCell(row: 5, column: 8),
    BoardCell(row: 6, column: 9),
    BoardCell(row: 6, column: 10),
    BoardCell(row: 6, column: 11),
    BoardCell(row: 6, column: 12),
    BoardCell(row: 6, column: 13),
    BoardCell(row: 6, column: 14),
    BoardCell(row: 7, column: 14),
    BoardCell(row: 8, column: 14),
    BoardCell(row: 8, column: 13),
    BoardCell(row: 8, column: 12),
    BoardCell(row: 8, column: 11),
    BoardCell(row: 8, column: 10),
    BoardCell(row: 8, column: 9),
    BoardCell(row: 9, column: 8),
    BoardCell(row: 10, column: 8),
    BoardCell(row: 11, column: 8),
    BoardCell(row: 12, column: 8),
    BoardCell(row: 13, column: 8),
    BoardCell(row: 14, column: 8),
    BoardCell(row: 14, column: 7),
    BoardCell(row: 14, column: 6),
    BoardCell(row: 13, column: 6),
    BoardCell(row: 12, column: 6),
    BoardCell(row: 11, column: 6),
    BoardCell(row: 10, column: 6),
    BoardCell(row: 9, column: 6),
    BoardCell(row: 8, column: 5),
    BoardCell(row: 8, column: 4),
    BoardCell(row: 8, column: 3),
    BoardCell(row: 8, column: 2),
    BoardCell(row: 8, column: 1),
    BoardCell(row: 8, column: 0),
    BoardCell(row: 7, column: 0),
    BoardCell(row: 6, column: 0),
  ];

  static const Map<PlayerColor, int> startOffsets = <PlayerColor, int>{
    PlayerColor.red: 0,
    PlayerColor.green: 13,
    PlayerColor.yellow: 26,
    PlayerColor.blue: 39,
  };

  static const Map<PlayerColor, List<BoardCell>> homeLanes =
      <PlayerColor, List<BoardCell>>{
    PlayerColor.red: <BoardCell>[
      BoardCell(row: 7, column: 1),
      BoardCell(row: 7, column: 2),
      BoardCell(row: 7, column: 3),
      BoardCell(row: 7, column: 4),
      BoardCell(row: 7, column: 5),
    ],
    PlayerColor.green: <BoardCell>[
      BoardCell(row: 1, column: 7),
      BoardCell(row: 2, column: 7),
      BoardCell(row: 3, column: 7),
      BoardCell(row: 4, column: 7),
      BoardCell(row: 5, column: 7),
    ],
    PlayerColor.yellow: <BoardCell>[
      BoardCell(row: 7, column: 13),
      BoardCell(row: 7, column: 12),
      BoardCell(row: 7, column: 11),
      BoardCell(row: 7, column: 10),
      BoardCell(row: 7, column: 9),
    ],
    PlayerColor.blue: <BoardCell>[
      BoardCell(row: 13, column: 7),
      BoardCell(row: 12, column: 7),
      BoardCell(row: 11, column: 7),
      BoardCell(row: 10, column: 7),
      BoardCell(row: 9, column: 7),
    ],
  };

  static const BoardCell finishCell = BoardCell(row: 7, column: 7);

  static int globalIndexFor({
    required PlayerColor color,
    required int pathPosition,
  }) {
    assert(pathPosition >= 0);
    assert(pathPosition < ClassicRules.commonPathLength);

    final int offset = startOffsets[color]!;
    return (offset + pathPosition) % ClassicRules.commonPathLength;
  }

  static BoardCell cellFor({
    required PlayerColor color,
    required int pathPosition,
  }) {
    if (pathPosition < ClassicRules.commonPathLength) {
      return commonPath[
          globalIndexFor(color: color, pathPosition: pathPosition)];
    }

    if (pathPosition < ClassicRules.finishProgress) {
      return homeLanes[color]![
          pathPosition - ClassicRules.commonPathLength];
    }

    if (pathPosition == ClassicRules.finishProgress) {
      return finishCell;
    }

    throw RangeError.range(
      pathPosition,
      0,
      ClassicRules.finishProgress,
      'pathPosition',
    );
  }

  static bool isSafeGlobalIndex(int globalIndex) {
    return ClassicRules.safeGlobalIndices.contains(globalIndex);
  }
}
