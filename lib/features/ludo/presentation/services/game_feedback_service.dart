import 'package:flutter/services.dart';

class GameFeedbackService {
  const GameFeedbackService({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
  });

  final bool soundEnabled;
  final bool hapticsEnabled;

  Future<void> tap() async {
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.click);
    }
    if (hapticsEnabled) {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> diceRoll() async {
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.click);
    }
    if (hapticsEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> tokenStep() async {
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.click);
    }
    if (hapticsEnabled) {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> capture() async {
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.alert);
    }
    if (hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  Future<void> home() async {
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.click);
    }
    if (hapticsEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> win() async {
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.alert);
    }
    if (hapticsEnabled) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 90));
      await HapticFeedback.mediumImpact();
    }
  }
}
