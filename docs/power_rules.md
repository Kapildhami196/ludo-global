# Power Ludo Rules — V1

Power Ludo uses every finalized Normal Ludo rule and adds a separate power
layer. The Normal Ludo engine remains the source of truth for dice, legal
movement, capture, safe cells, home entry, turn switching, and winning.

## Power inventory

Each player starts a Power Ludo match with **one charge of each power**:

- Double Distance ×1
- Shield ×1
- Dice Control ×1
- Bonus Roll ×1

A charge is consumed when the power is successfully activated. A power cannot
be activated when no charge remains.

## Double Distance

- Used **after the dice is rolled** and before selecting a token.
- The selected token moves **2× the rolled dice distance**.
- It can only target a token that has already left base.
- It cannot be used only to release a token from base.
- Exact-finish and blockade rules still apply to the doubled movement.
- If no active/home-path token can legally move the doubled distance, the power
  is unavailable for that roll.
- Normal extra-turn rules still use the original dice value.

Example: roll 3 → activate Double Distance → selected token moves 6 spaces.

## Shield

- Used before rolling.
- Targets one of the current player's tokens on the **shared track**.
- Base, home-lane, and finished tokens are not eligible.
- A protected token cannot be captured.
- The shield remains active through opponents' turns.
- It expires when the shield owner next receives the turn.
- A shield does not change safe-cell or blockade rules.

## Dice Control

- Used before a normal dice roll.
- The player chooses a value from **1 through 6**.
- The chosen value is processed exactly like a normal roll.
- Choosing 6 can release a token and can grant the normal extra roll.
- A controlled 6 also counts toward the three-consecutive-sixes rule.

## Bonus Roll

- Used before rolling to queue one future extra roll.
- The queued bonus waits until the player's turn would otherwise pass.
- A natural extra turn from rolling 6 or capturing happens first and does not
  waste the queued Bonus Roll.
- When the turn would pass normally, Bonus Roll keeps the same player and
  returns the game to the roll phase.
- A three-consecutive-sixes forfeiture cannot be cancelled by Bonus Roll.

## Engineering rules

- Powers are domain rules, not UI-only effects.
- `PowerLudoEngine` composes `LudoGameEngine`; it does not duplicate Normal
  Ludo movement rules.
- UI animations only visualize a power action that the domain layer already
  approved.
- Power inventory, shields, and queued effects live in `PowerLudoState`, not
  in Normal Ludo state.
- The shared game engine exposes generic movement-distance and protected-token
  inputs so additional rule layers can compose it without adding mode checks.
