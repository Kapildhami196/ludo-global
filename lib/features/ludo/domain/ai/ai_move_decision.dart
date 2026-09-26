class AiMoveDecision {
  const AiMoveDecision({
    required this.tokenId,
    required this.score,
    this.reason = '',
  });

  final int tokenId;
  final double score;
  final String reason;
}
