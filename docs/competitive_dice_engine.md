# Competitive Dice Engine

The competitive dice system is enabled only for Normal Local Human matches.

Its goal is to make local matches more active without selecting a winner or
forcing a die result. Every roll remains a weighted random choice from 1 to 6.

## Architecture

```text
LocalGameScreen
  -> LudoGameEngine
    -> CompetitiveDiceEngine
      -> MatchSituationAnalyzer
      -> CompetitiveDiceTuning
      -> DiceWeights
      -> WeightedDiceRoller
```

The existing LudoGameEngine remains responsible for legal movement, captures,
safe cells, blockades, exact finish, extra turns, and winning.

## Balanced tuning profile

The default profile is `CompetitiveDiceTuning.balanced`.

| Situation | Weight change |
| --- | ---: |
| Base weight per face | 100 |
| Six drought at 3 rolls | +15 to 6 |
| Six drought at 5 rolls | +20 additional |
| Six drought at 7 rolls | +25 additional |
| All tokens in base | +25 to 6 |
| Exact capture | +35 |
| Escape to safety/home | +15 |
| Enter home lane | +12 |
| Exact finish | +20 |
| Create blockade | +12 |
| Stale match useful action | +15 |
| Significantly behind useful action | +10 |
| Opponent near win defensive action | +20 |
| Current player near win exact finish | +20 |

A strong assisted outcome starts a two-roll cooldown. During cooldown adaptive
boosts run at 35% strength.

No single die face may exceed 40% final probability.

## Important fairness properties

- There is no desired winner or loser input.
- Player color and player index do not change tuning values.
- Leading players are not assigned negative weights.
- A useful number becomes more likely but is never guaranteed.
- Power Ludo Dice Control remains a separate explicit forced-value mechanic.
- Computer mode and Power Local mode currently retain their existing dice path.

## Decision inspection

`CompetitiveDiceEngine.decisionFor(...)` returns a
`DiceDecisionSnapshot` containing:

- the analyzed match context;
- the player's current dice history;
- final capped weights;
- final probabilities for faces 1 through 6.

This is intended for automated calibration, debugging, and future analytics.

## Phase 4 calibration tests

`competitive_dice_simulation_test.dart` uses fixed random seeds and large
sample sizes to keep calibration reproducible.

The suite verifies:

- neutral rolls remain approximately uniform;
- capture opportunities increase the relevant action rate without dominating;
- an extreme boost is constrained by the 40% cap;
- equivalent Red and Yellow situations receive equal weights;
- cooldown measurably lowers immediate repeat assistance;
- all decision probabilities sum to 1.

When tuning values change, run:

```bash
flutter analyze
flutter test
```

Do not tune from a single match. Use repeated simulations and play-test data.
