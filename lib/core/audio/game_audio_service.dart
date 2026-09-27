import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'game_sound.dart';

class GameAudioService {
  GameAudioService._();

  static final GameAudioService instance = GameAudioService._();

  final Map<GameSound, AudioPlayer> _players =
      <GameSound, AudioPlayer>{};

  Future<void>? _preloadFuture;

  Future<void> preload() {
    return _preloadFuture ??= _preloadAll();
  }

  Future<void> _preloadAll() async {
    for (final GameSound sound in GameSound.values) {
      final AudioPlayer player = AudioPlayer();
      try {
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(sound.assetPath));
        await player.setVolume(sound.volume);
        _players[sound] = player;
      } catch (_) {
        await player.dispose();
      }
    }
  }

  Future<void> play(GameSound sound) async {
    try {
      await preload();
      final AudioPlayer? player = _players[sound];
      if (player == null) {
        return;
      }

      await player.stop();
      await player.seek(Duration.zero);
      await player.setVolume(sound.volume);
      await player.resume();
    } catch (_) {
      // Audio is non-critical. A playback failure must never block gameplay.
    }
  }

  Future<void> playSequence(
    List<(GameSound, Duration)> sequence,
  ) async {
    for (final (GameSound sound, Duration delay) in sequence) {
      unawaited(play(sound));
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
    }
  }

  Future<void> dispose() async {
    for (final AudioPlayer player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    _preloadFuture = null;
  }
}
