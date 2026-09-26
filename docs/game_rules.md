# Normal Ludo Rules — Classic V1

This document is the rule source of truth for the Normal Ludo engine.

## Confirmed scope

- 2 to 4 players.
- 4 tokens per player.
- Normal Ludo and Power Ludo share the same base movement/rule engine.
- Local / Pass-and-Play supports:
  - 2 human players on one device.
  - 3 human players on one device.
  - 4 human players on one device.

## Classic V1 rule decisions

These rules are now implemented and covered by domain tests.

### Starting and movement

- A token must roll **6** to leave base.
- Leaving base places the token on that color's starting square.
- A roll of **6** grants another roll after the selected legal move.
- Three consecutive sixes by the same player forfeit the third roll and immediately pass the turn.
- A token must use the **exact roll** needed to reach the center. A roll that overshoots is not legal.
- Reaching the center does not independently grant another roll.

### Board route

- The shared track contains **52 cells**.
- Each color uses the same shared track with a different start offset:
  - Red: global index 0.
  - Green: global index 13.
  - Yellow: global index 26.
  - Blue: global index 39.
- Token progress is stored relative to its own starting square:
  - -1 = base.
  - 0–51 = shared track.
  - 52–56 = that color's five-cell home lane.
  - 57 = finished in the center.

### Safe cells

The eight safe shared-track indices are:

`0, 8, 13, 21, 26, 34, 39, 47`

These include all four color starting squares and four star/safe squares.

- Opponents are never captured on a safe cell.
- Different colors may coexist on a safe cell.
- A safe cell does not act as a blockade.

### Capture

- Landing on an opponent token on a non-safe shared cell sends that token back to base.
- A successful capture grants an extra roll.
- Captures do not occur in a home lane or in the center.

### Stacks and blockades

- Tokens of the same color may share a shared-track cell.
- Two or more same-color opponent tokens on the same non-safe cell form a blockade.
- A token may not land on or pass through an opponent blockade.
- A player's own stacked tokens do not block that player's movement in Classic V1.

### Winning

- The first player to move all four tokens into the center wins.
- Classic V1 ends immediately when the first winner is determined.
- 2nd/3rd-place continuation can be added later as a separate match configuration.

## Online-only rules

Turn timers, disconnect handling, reconnection, and server-authoritative validation are intentionally deferred to the online multiplayer phase.
