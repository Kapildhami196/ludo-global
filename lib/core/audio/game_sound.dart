enum GameSound {
  buttonTap('audio/game/button_tap.wav', 0.45),
  diceRoll('audio/game/dice_roll.wav', 0.58),
  diceLand('audio/game/dice_land.wav', 0.72),
  pawnStep('audio/game/pawn_step.wav', 0.28),
  pawnRelease('audio/game/pawn_release.wav', 0.58),
  capture('audio/game/capture.wav', 0.78),
  returnWhoosh('audio/game/return_whoosh.wav', 0.52),
  home('audio/game/home.wav', 0.66),
  powerPickup('audio/game/power_pickup.wav', 0.62),
  shield('audio/game/shield.wav', 0.66),
  diceControl('audio/game/dice_control.wav', 0.58),
  doubleDistance('audio/game/double_distance.wav', 0.62),
  bonusRoll('audio/game/bonus_roll.wav', 0.68),
  winner('audio/game/winner.wav', 0.78);

  const GameSound(this.assetPath, this.volume);

  final String assetPath;
  final double volume;
}
