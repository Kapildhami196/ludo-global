# Normal Ludo Rules — Gameplay Rules V2

This document is the rule source of truth for Normal Ludo.

## Match setup

- 2 to 4 players.
- 4 tokens per player.
- 2-player matches use opposite seats: **Red vs Yellow**.
- 3-player matches use Red, Green, and Yellow.
- 4-player matches use Red, Green, Yellow, and Blue.
- The starting player is chosen randomly.
- Turns then advance in player-list order.

## Starting and movement

- A token must roll **6** to leave base.
- Leaving base places the token on that color's starting square.
- A roll of **6** grants one extra roll.
- If a 6 has no legal move, the player still receives the extra roll.
- Three consecutive sixes: the first two rolls/moves remain; the third six is forfeited and the turn immediately passes.
- A token must use the exact roll needed to reach the center.
- Finishing a token grants one extra roll.
- Extra-roll reasons never stack. A move that qualifies for multiple bonuses still grants only one next roll.
- When a human player has exactly one legal token, it is highlighted briefly and then moved automatically.

## Board route

- The shared track contains 52 cells.
- Start offsets:
  - Red: 0
  - Green: 13
  - Yellow: 26
  - Blue: 39
- Logical token progress:
  - -1 = base
  - 0–51 = shared track
  - 52–56 = home lane
  - 57 = finished

## Safe cells

Safe shared-track indices:

`0, 8, 13, 21, 26, 34, 39, 47`

- Opponents are never captured on a safe cell.
- Different colors may coexist on a safe cell.
- Safe cells do not form opponent blockades.

## Capture

- Landing exactly on an opponent token on a non-safe shared cell sends that token back to base.
- A capture grants one extra roll.
- Captures do not occur in a home lane or center.
- Capture + six, capture + finish, or any other combination still gives a maximum of one extra roll.

## Stacks

- Two, three, or four same-color tokens may share a cell.
- Stacked tokens do not create a blockade.
- Opponents may pass through or land on a cell containing multiple same-color tokens.
- Normal safe-cell and capture rules still apply.
- The owner may move any token away from their own stack.

## Winning

- A player wins after all four tokens reach the center.
- The current implementation ends the match when the first winner is determined.

## Local pass-and-play

- Turns change directly when the previous human player's turn ends.
- There is no Pass-the-Phone confirmation overlay.

## Online rule reserved for multiplayer phase

- Turn timer: **20 seconds**.
- Networking, disconnect/reconnect, and server-authoritative validation remain a future phase.
