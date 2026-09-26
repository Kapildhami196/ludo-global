import 'player_color.dart';
import 'token_status.dart';

class LudoToken {
  const LudoToken({
    required this.id,
    required this.color,
    this.pathPosition = -1,
    this.status = TokenStatus.base,
  });

  final int id;
  final PlayerColor color;

  /// Progress relative to this token's own starting square.
  ///
  /// - -1: in base
  /// - 0..51: common path
  /// - 52..56: colored home lane
  /// - 57: finished in the center
  final int pathPosition;
  final TokenStatus status;

  bool get isInBase => status == TokenStatus.base;
  bool get isFinished => status == TokenStatus.finished;

  LudoToken copyWith({
    int? pathPosition,
    TokenStatus? status,
  }) {
    return LudoToken(
      id: id,
      color: color,
      pathPosition: pathPosition ?? this.pathPosition,
      status: status ?? this.status,
    );
  }
}
