# YOKAI BLADE

A folklore-true Japanese action game where even the jokes can kill you.

## Vision

YOKAI BLADE is about **discipline through strangeness**. Every enemy is real. Every myth is sincere. Some are terrifying. Some are ridiculous. All are dangerous.

The player may laugh — but the blade must remain steady.

## Combat

Built on the **Sacred Loop**:
1. Pressure
2. Read
3. Deflect
4. Exploit
5. Reset

Deflection is not defense. Deflection is respect, timing, and intent.

## Current Milestone

**Vertical Slice: The Three Trials**
- Shirime (Etiquette Trial) — patience and restraint
- Tanuki (Deception Trial) — pattern over appearance
- Oni (Truth Trial) — pure mastery

## Technical Stack

- **Engine:** Unity LTS
- **Language:** C#
- **Target:** PC (controller + keyboard)

## Project Structure

```
Assets/
  Core/           # Engine-agnostic game systems
    Combat/       # Attack, deflect, damage systems
    Telegraphs/   # Global signal language
    Boss/         # Boss state machines and behaviors
    Audio/        # Sound management
    Input/        # Input handling and buffering
    Data/         # ScriptableObject definitions
    UI/           # Interface systems
    Util/         # Shared utilities
  Game/           # Game-specific content
    Scenes/
    Prefabs/
    ScriptableObjects/
  Tests/
    EditMode/
    PlayMode/
docs/             # Design documentation
tools/            # Build and dev tools
```

## Documentation

- [System Invariants](docs/INVARIANTS.md) — non-negotiable contracts
- [Project Plan](docs/PROJECT_PLAN.md) — build order and gates
- [Telegraph Semantics](docs/TELEGRAPH_SEMANTICS.md) — global signal language

## Core Principles

1. **Telegraph semantics never lie** — comedy doesn't excuse dishonesty
2. **Death teaches** — no tutorials, only truth
3. **Mastery through discipline** — power is earned through understanding

## Setup

1. Open project in Unity LTS (2022.3+)
2. Open `Assets/Game/Scenes/Boot.unity`
3. Enter Play mode

## License

[TBD]
