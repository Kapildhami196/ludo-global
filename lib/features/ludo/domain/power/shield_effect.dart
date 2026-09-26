class ShieldEffect {
  const ShieldEffect({
    required this.tokenId,
    required this.ownerPlayerId,
    required this.activatedAtTurnSerial,
  });

  final int tokenId;
  final String ownerPlayerId;
  final int activatedAtTurnSerial;
}
