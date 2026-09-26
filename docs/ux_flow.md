# UX Flow

## Primary flow

```text
Splash
↓
Home
↓
Choose Mode
├── Normal Ludo
└── Power Ludo
↓
Choose Match Type
├── Local / Pass-and-Play
├── Play vs Computer
├── Online Match
├── Private Room
└── Play with Friends
↓
Player Setup / Lobby
↓
Game
↓
Result
```

## Local / Pass-and-Play

Available in both Normal and Power modes:

```text
Local / Pass-and-Play
├── 2 Human Players — Same Device
├── 3 Human Players — Same Device
└── 4 Human Players — Same Device
```

Example four-player turn sequence:

```text
Red
↓
Green
↓
Yellow
↓
Blue
↓
Red
```

The basic same-device local experience should not require internet access.

## Game screen states

- Waiting for roll
- Dice rolling
- Selecting a legal token
- Token moving
- Resolving capture
- Extra roll / turn continuation
- Next player's turn
- Token finished
- Match finished

Power mode additionally includes power availability, power selection, target selection, power-active feedback, and unavailable/exhausted states.
