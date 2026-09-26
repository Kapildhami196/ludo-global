enum AiDifficulty {
  easy,
  medium,
  hard,
}

extension AiDifficultyLabel on AiDifficulty {
  String get label => switch (this) {
        AiDifficulty.easy => 'Easy',
        AiDifficulty.medium => 'Medium',
        AiDifficulty.hard => 'Hard',
      };

  String get description => switch (this) {
        AiDifficulty.easy => 'Relaxed • Mostly random legal moves',
        AiDifficulty.medium => 'Balanced • Captures and safe moves',
        AiDifficulty.hard => 'Strategic • Plans around danger and home',
      };
}
