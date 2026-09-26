import 'ludo_game_event.dart';
import 'ludo_game_state.dart';

class LudoGameActionResult {
  const LudoGameActionResult({
    required this.state,
    this.events = const <LudoGameEvent>[],
  });

  final LudoGameState state;
  final List<LudoGameEvent> events;
}
