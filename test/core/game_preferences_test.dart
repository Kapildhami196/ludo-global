import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_global/core/settings/game_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('game preferences default sound and haptics to enabled', () async {
    final settings = await GamePreferences.load();

    expect(settings.soundEnabled, isTrue);
    expect(settings.hapticsEnabled, isTrue);
  });

  test('game preferences persist sound and haptics choices', () async {
    await GamePreferences.setSoundEnabled(false);
    await GamePreferences.setHapticsEnabled(false);

    final settings = await GamePreferences.load();

    expect(settings.soundEnabled, isFalse);
    expect(settings.hapticsEnabled, isFalse);
  });
}
