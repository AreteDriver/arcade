# EVE Rebellion - Project Instructions

## Project Overview
EVE Online arcade shooter suite built with Rust and Bevy. Features multiple campaigns, faction selection, procedural audio, and WASM support.

**Stack**: Rust, Bevy 0.15, bevy_egui
**Version**: 1.5.x
**Platforms**: Linux, Windows, macOS, Web (WASM)

---

## Architecture

```
src/
├── main.rs           # Entry point, plugin registration
├── core/             # Game states, resources, events
├── entities/         # ECS components (Player, Enemy, Projectile)
├── systems/          # Game logic (collision, spawning, scoring)
├── ui/               # Menus, HUD, overlays
├── campaigns/        # Campaign-specific logic
│   ├── elder_fleet/  # Minmatar/Amarr campaign
│   └── caldari_gallente/ # CG campaign + Nightmare mode
├── audio/            # Procedural sound generation
├── assets/           # Asset loading, ship sprites
└── esi/              # EVE API integration
```

### Key Systems
- **GameState**: MainMenu → FactionSelect → Playing → Victory/Death
- **Scoring**: Chain combos, style grades, berserk mode
- **Combat**: Shield → Armor → Hull damage model
- **Campaigns**: Elder Fleet (13 stages), CG (5 missions + Nightmare)

---

## Development Workflow

```bash
# Build
cargo build

# Run (debug)
cargo run

# Run (release)
cargo run --release

# Test
cargo test

# Lint
cargo fmt --check
cargo clippy

# WASM build
./build-wasm.sh
```

---

## Code Conventions
- Bevy 0.15 ECS patterns (systems, components, resources)
- Systems named: `update_*`, `spawn_*`, `handle_*`, `check_*`
- No `.unwrap()` in game logic — use `.unwrap_or_default()` or proper error handling
- Components in `entities/`, systems in `systems/`
- States as enums with `States` derive

---

## Asset Pipeline
- Ship sprites from EVE Image Server (cached in ~/.cache/eve_rebellion/)
- Sprites embedded in binary for WASM builds
- Procedural audio generated at startup (no external audio files)

---

## Campaigns

| Campaign | Factions | Stages | Special |
|----------|----------|--------|---------|
| Elder Fleet | Minmatar vs Amarr | 13 | Tribe bonuses |
| Caldari/Gallente | Caldari vs Gallente | 5 | T3 unlocks |
| Shiigeru Nightmare | Caldari | Endless | Survival mode |
| Endless Mode | All | Infinite | High score chase |

---

## CCP Attribution
```
EVE Online and the EVE logo are registered trademarks of CCP hf.
All ship images and EVE-related content are property of CCP.
This is a fan project, not affiliated with or endorsed by CCP hf.
```
