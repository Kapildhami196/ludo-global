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
}
