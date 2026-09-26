# Normal Ludo Rules

This document is the rule source of truth for the game engine.

## Confirmed scope

- 2 to 4 players.
- 4 tokens per player.
- Normal Ludo and Power Ludo share the same base movement/rule engine.
- Local / Pass-and-Play supports:
  - 2 human players on one device.
  - 3 human players on one device.
  - 4 human players on one device.

## Rule decisions to finalize before the game engine

The project plan intentionally leaves the following decisions open because Ludo variants differ:

- Whether a 6 is required to leave base.
- Whether rolling 6 grants another roll.
- Whether capturing grants another roll.
- Which cells are safe.
- Whether exact roll is required to finish.
- What happens after three consecutive 6s.
- Whether same-color tokens form a block.
- Whether blocks may be passed.
- Player timeout behavior for online matches.
- Whether a match ends on the first winner or continues for 2nd/3rd place.

No engine implementation should silently invent these rules. They must be agreed here first.
