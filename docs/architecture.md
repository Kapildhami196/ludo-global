# Architecture

## Core decision

Ludo Global uses **one shared game engine**.

- **Normal Ludo** applies the classic rule set.
- **Power Ludo** uses the same engine and composes a separate power-rule layer.

This avoids duplicated movement, capture, turn, home-lane, and winner logic.

## Layers

```text
UI
↓
State management
↓
LudoGameEngine
├── Movement rules
├── Turn rules
├── Capture rules
├── Finish rules
└── Power rules (Power mode only)
```

The domain/game engine must not depend on Flutter widgets. Rendering and animation consume game events/state but do not decide legal moves.

## Board rendering

The board is intended to be mostly static, with independent moving/effect layers:

```text
Stack
├── CustomPaint      # board
├── TokenLayer       # pieces
├── AnimationLayer   # movement
└── EffectLayer      # captures/powers/celebration
```

Logical token state stores a path position, not screen x/y coordinates. The presentation layer maps logical positions to board coordinates.

## Initial feature structure

```text
lib/
├── app/
├── core/
│   ├── animation/
│   ├── audio/
│   ├── theme/
│   └── utils/
└── features/
    ├── home/
    └── ludo/
        ├── domain/
        │   ├── entities/
        │   ├── engine/
        │   └── rules/
        └── presentation/
            ├── state/
            ├── screens/
            └── widgets/
```

## Multiplayer principle

Online multiplayer is a later phase. The eventual server must be authoritative for dice results, turn ownership, legal moves, captures, powers, timers, and the winner.
