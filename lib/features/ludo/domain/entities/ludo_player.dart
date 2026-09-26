import 'ludo_token.dart';
import 'player_color.dart';

class LudoPlayer {
  const LudoPlayer({
    required this.id,
    required this.name,
    required this.color,
    required this.tokens,
  });

  final String id;
  final String name;
  final PlayerColor color;
  final List<LudoToken> tokens;

  bool get hasFinished =>
      tokens.isNotEmpty && tokens.every((token) => token.isFinished);

  LudoPlayer copyWith({
    String? name,
    List<LudoToken>? tokens,
  }) {
    return LudoPlayer(
      id: id,
      name: name ?? this.name,
      color: color,
      tokens: tokens ?? this.tokens,
    );
  }
}
