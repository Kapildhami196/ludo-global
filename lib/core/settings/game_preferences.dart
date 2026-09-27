import 'package:shared_preferences/shared_preferences.dart';

class GamePreferences {
  GamePreferences._();

  static const String _soundKey = 'game_sound_enabled';
  static const String _hapticsKey = 'game_haptics_enabled';

  static Future<({bool soundEnabled, bool hapticsEnabled})>
      load() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return (
      soundEnabled: prefs.getBool(_soundKey) ?? true,
      hapticsEnabled: prefs.getBool(_hapticsKey) ?? true,
    );
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, enabled);
  }

  static Future<void> setHapticsEnabled(bool enabled) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsKey, enabled);
  }
}
