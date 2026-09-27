# Power Ludo Rules — Gameplay Rules V2

Power Ludo uses every Normal Ludo rule and adds collectible board powers.

The official Ludo World description confirms the effects of Double Distance,
Dice Control, Protection Shield, and Bonus Roll. Ludo Global uses those
effects with the finalized pickup/spawn rules below.

## Power acquisition

Players start with **zero held powers**.

Four pickups exist on the shared track:

- Double Distance
- Shield
- Dice Control
- Bonus Roll

Initial pickup positions are randomly selected from a predefined approved cell
pool.

Approved pickup cells never include:

- player starting squares;
- safe/star squares;
- home lanes;
- the center.

Only one pickup may occupy a board square.

A token must **land exactly** on a pickup. Passing over it does not collect it.

After collection, that pickup immediately relocates to another random approved
empty power cell. It cannot remain on the same cell and cannot overlap another
pickup.

## Held powers

Double Distance, Shield, and Dice Control are added to the collecting player's
inventory. Multiple collected charges can accumulate.

Bonus Roll is never stored in inventory; it triggers immediately on landing.

## Double Distance

- Must already have a collected Double Distance charge.
- Activated after rolling and before choosing a token.
- Moves the selected eligible token by 2× the rolled value.
- Cannot release a token from base.
- Exact finish and blockade rules still apply.
- The original die value still controls normal six/consecutive-six behavior.

## Shield

- Must already have a collected Shield charge.
- Activated before rolling.
- Targets one of the player's active shared-track tokens.
- Base, home-lane, and finished tokens cannot be shielded.
- Protection lasts until the owner receives their next turn.
- A shielded token cannot be captured.
- An opponent **may land on the same unsafe square** as a shielded token.
  Both tokens coexist while the shield is active.
- When the shield expires, normal capture rules resume on future moves.

## Dice Control

- Must already have a collected Dice Control charge.
- Activated before rolling.
- Player chooses any value from 1 through 6.
- The selected value behaves exactly like a natural roll.
- Controlled 6 grants the normal extra roll and counts toward the
  three-consecutive-sixes rule.

## Bonus Roll

- Exists only as a board pickup.
- Landing exactly on Bonus Roll grants an immediate extra roll.
- It is collected and relocated immediately.
- It is not manually activated and is not stored.
- If the same move already earned an extra roll from a six, capture, or finish,
  the bonuses do not stack; the player still receives only one extra roll.

## Power fairness

Humans and computer players use the same inventory and pickup rules. AI cannot
use powers it has not collected.
