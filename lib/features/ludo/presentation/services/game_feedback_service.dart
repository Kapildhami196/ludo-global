import 'dart:async';

import 'package:flutter/services.dart';

import '../../../../core/audio/game_audio_service.dart';
import '../../../../core/audio/game_sound.dart';

class GameFeedbackService {
  const GameFeedbackService({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
  });

  final bool soundEnabled;
  final bool hapticsEnabled;

  Future<void> tap() async {
    if (soundEnabled) {
      unawaited(GameAudioService.instance.play(GameSound.buttonTap));
    }
    if (hapticsEnabled) {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> diceRoll() async {
    if (soundEnabled) {
      unawaited(
        GameAudioService.instance.playSequence(
          const <(GameSound, Duration)>[
            (GameSound.diceRoll, Duration(milliseconds: 560)),
            (GameSound.diceLand, Duration.zero),
          ],
        ),
      );
    }
    if (hapticsEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> tokenStep() async {
    if (soundEnabled) {
      unawaited(GameAudioService.instance.play(GameSound.pawnStep));
    }
  }

  Future<void> pawnRelease() async {
    if (soundEnabled) {
      unawaited(GameAudioService.instance.play(GameSound.pawnRelease));
    }
    if (hapticsEnabled) {
      await HapticFeedback.lightImpact();
    }
  }

  Future<void> capture() async {
    if (soundEnabled) {
      unawaited(GameAudioService.instance.play(GameSound.capture));
    }
    if (hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  Future<void> returnHome() async {
    if (soundEnabled) {
      unawaited(GameAudioService.instance.play(GameSound.returnWhoosh));
    }
    if (hapticsEnabled) {
      await HapticFeedback.lightImpact();
    }
  }

  Future<void> home() async {
    if (soundEnabled) {
      unawaited(GameAudioService.instance.play(GameSound.home));
    }
    if (hapticsEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> powerPickup() async {
    if (soundEnabled) {
      unawaited(GameAudioService.instance.play(GameSound.powerPickup));
    }
    if (hapticsEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> shield() async {
    if (soundEnabled) {
      unawaited(GameAudioService.instance.play(GameSound.shield));
    }
    if (hapticsEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> diceControl() async {
    if (soundEnabled) {
      unawaited(GameAudioService.instance.play(GameSound.diceControl));
    }
    if (hapticsEnabled) {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> doubleDistance() async {
    if (soundEnabled) {
      unawaited(GameAudioService.instance.play(GameSound.doubleDistance));
    }
    if (hapticsEnabled) {
      await HapticFeedback.lightImpact();
    }
  }

  Future<void> bonusRoll() async {
    if (soundEnabled) {
      unawaited(GameAudioService.instance.play(GameSound.bonusRoll));
    }
    if (hapticsEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> win() async {
    if (soundEnabled) {
      unawaited(GameAudioService.instance.play(GameSound.winner));
    }
    if (hapticsEnabled) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 90));
      await HapticFeedback.mediumImpact();
    }
  }
}
