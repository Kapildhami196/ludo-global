# Ludo Global

Ludo Global is a Flutter board game project with two game modes:

- **Normal Ludo** — classic Ludo rules.
- **Power Ludo** — Normal Ludo plus special powers such as Double Distance, Shield, Dice Control, and Bonus Roll.

## Planned play modes

- Local / Pass-and-Play
  - 2 human players on the same device
  - 3 human players on the same device
  - 4 human players on the same device
- Play vs Computer
- Online Match
- Private Room
- Play with Friends

## Engineering direction

The project uses **one shared Ludo game engine**. Normal Mode uses the classic rule set, while Power Mode composes an additional power-rule layer on top of the same engine.

The initial development order is:

1. Project foundation and architecture
2. Responsive Ludo board and 16 starting tokens
3. Normal Ludo game engine
4. Local Pass-and-Play for 2–4 human players
5. Dice, token, capture, audio, and haptic polish
6. Power Ludo
7. Computer AI
8. Online multiplayer

See the `docs/` directory for the detailed rules, architecture, UX flow, and roadmap.
