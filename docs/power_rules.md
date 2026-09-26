# Power Ludo Rules

Power Ludo starts with all finalized Normal Ludo rules and adds a power layer.

## Initial powers

### Double Distance
The selected move uses twice the normal dice movement distance.

### Shield
Temporarily protects a selected eligible token from capture.

### Dice Control
Allows the player to choose/control the dice value when the power is legally available.

### Bonus Roll
Grants an additional roll when the power is legally available.

## Engineering rules

- Powers are domain rules, not UI-only effects.
- The engine validates whether a power can be used.
- UI animations only visualize an already-approved power action.
- Power quantities, duration, targeting restrictions, and stacking rules must be explicitly defined before implementation.
- Normal Mode must not contain power-specific branches beyond the game-mode composition boundary.
