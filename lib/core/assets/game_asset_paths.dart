import '../../features/ludo/domain/entities/player_color.dart';
import '../../features/ludo/domain/entities/power_type.dart';

abstract final class GameAssetPaths {
  static const String pawnRed = 'assets/game/pawns/pawn_red.svg';
  static const String pawnGreen = 'assets/game/pawns/pawn_green.svg';
  static const String pawnYellow = 'assets/game/pawns/pawn_yellow.svg';
  static const String pawnBlue = 'assets/game/pawns/pawn_blue.svg';

  static const String dice1 = 'assets/game/dice/dice_1.svg';
  static const String dice2 = 'assets/game/dice/dice_2.svg';
  static const String dice3 = 'assets/game/dice/dice_3.svg';
  static const String dice4 = 'assets/game/dice/dice_4.svg';
  static const String dice5 = 'assets/game/dice/dice_5.svg';
  static const String dice6 = 'assets/game/dice/dice_6.svg';

  static const String doubleDistance = 'assets/game/powers/double_distance.png';
  static const String shield = 'assets/game/powers/shield.png';
  static const String diceControl = 'assets/game/powers/dice_control.png';
  static const String bonusRoll = 'assets/game/powers/bonus_roll.png';

  static const String ludoBoard = 'assets/game/board/ludo_global_board.svg';
  static const String safeStar = 'assets/game/board/safe_star.svg';
  static const String directionArrow = 'assets/game/board/direction_arrow.svg';
  static const String centerGoal = 'assets/game/board/center_goal.svg';

  static String pawnFor(PlayerColor color) {
    return switch (color) {
      PlayerColor.red => pawnRed,
      PlayerColor.green => pawnGreen,
      PlayerColor.yellow => pawnYellow,
      PlayerColor.blue => pawnBlue,
    };
  }

  static String diceFor(int value) {
    return switch (value) {
      1 => dice1,
      2 => dice2,
      3 => dice3,
      4 => dice4,
      5 => dice5,
      6 => dice6,
      _ => throw ArgumentError.value(
          value,
          'value',
          'Dice value must be between 1 and 6.',
        ),
    };
  }

  static String powerFor(PowerType type) {
    return switch (type) {
      PowerType.doubleDistance => doubleDistance,
      PowerType.shield => shield,
      PowerType.diceControl => diceControl,
      PowerType.bonusRoll => bonusRoll,
    };
  }
}
