# Computer / AI Mode

Computer mode is fully offline and uses deterministic game rules plus a
rule-based decision layer. It does not require machine learning, a remote
service, or an internet connection.

## Match setup

- One human player always occupies Player 1 / Red.
- Total match size can be 2, 3, or 4 players.
- Remaining seats are computer players.
- Normal Ludo and Power Ludo both support computer opponents.
- Difficulty is selected before the match.

## Difficulty levels

### Easy

- Chooses from legal moves mostly at random.
- In Power Ludo, powers are used occasionally and may not be optimal.
- Intended for new/casual players.

### Medium

Move scoring favors:

- capturing an opponent;
- finishing a token;
- entering the home lane;
- landing on safe cells;
- releasing a token from base;
- forward progress.

Power use is conservative and prefers clear tactical value.

### Hard

Uses all Medium priorities plus:

- estimates immediate capture danger from opponents within 1–6 spaces;
- rewards useful same-color stacks;
- gives extra weight to advanced/home-lane tokens;
- uses Dice Control when it creates strong tactical value;
- shields threatened advanced tokens;
- compares Double Distance against the best normal move before spending it;
- collects Bonus Roll from the board like a human; Bonus Roll activates immediately on exact landing rather than being manually queued.

## Architecture

`LudoAiStrategy` only chooses among moves that `LudoGameEngine` has already
declared legal. It may simulate immutable engine results for scoring, but it
does not mutate game state or bypass rules.

`PowerLudoAiStrategy` sits above `PowerLudoEngine`. Power decisions are
validated by the same Power engine used for human players. AI therefore cannot
use a power it has not collected, shield an invalid token, move through a
blockade, or ignore exact-finish rules. Board pickups are collected and
relocated by the shared Power engine for both humans and computers.

## Turn flow

Human turn:

1. Human rolls.
2. Engine returns legal tokens.
3. Human selects a highlighted token.
4. Engine resolves the move.

Computer turn:

1. A short thinking delay is shown.
2. Computer rolls automatically, or a Power AI may choose a legal pre-roll
   power.
3. Engine returns legal tokens.
4. AI scores legal actions according to difficulty.
5. The selected move is submitted back to the engine.
6. The same token/dice/capture/home animations used for human play run.
7. Extra turns are handled automatically until control returns to the human.

## Testing

The AI domain tests verify that:

- Easy always returns a legal token.
- Medium prefers a direct capture over an ordinary move.
- Hard prioritizes finishing a token.
- Hard Power AI uses Dice Control to release a base token when valuable.
- Hard Power AI recognizes a Double Distance capture opportunity.

The UI flow test verifies that computer setup opens a playable offline
Normal Ludo match.
