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
  final int pathPosition;
  final TokenStatus status;

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
