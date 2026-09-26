import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_global/features/ludo/domain/entities/game_config.dart';

void main() {
  group('LudoGameConfig', () {
    test('normal local game disables powers', () {
      const LudoGameConfig config = LudoGameConfig(
        mode: LudoGameMode.normal,
        matchType: LudoMatchType.localPassAndPlay,
        playerCount: 4,
      );

      expect(config.powersEnabled, isFalse);
      expect(config.isSameDevice, isTrue);
    });

    test('power local game enables powers', () {
      const LudoGameConfig config = LudoGameConfig(
        mode: LudoGameMode.power,
        matchType: LudoMatchType.localPassAndPlay,
        playerCount: 3,
      );

      expect(config.powersEnabled, isTrue);
      expect(config.isSameDevice, isTrue);
    });

    test('supports the same-device player counts required for V1', () {
      for (final int playerCount in <int>[2, 3, 4]) {
        final LudoGameConfig config = LudoGameConfig(
          mode: LudoGameMode.normal,
          matchType: LudoMatchType.localPassAndPlay,
          playerCount: playerCount,
        );

        expect(config.playerCount, playerCount);
      }
    });
  });
}
