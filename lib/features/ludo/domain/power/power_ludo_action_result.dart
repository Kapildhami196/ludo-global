import '../entities/ludo_game_event.dart';
import 'power_game_event.dart';
import 'power_ludo_state.dart';

class PowerLudoActionResult {
  const PowerLudoActionResult({
    required this.state,
    this.gameEvents = const <LudoGameEvent>[],
    this.powerEvents = const <PowerGameEvent>[],
  });

  final PowerLudoState state;
  final List<LudoGameEvent> gameEvents;
  final List<PowerGameEvent> powerEvents;
}
