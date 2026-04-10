# Arcade — CLAUDE.md

## Project Overview

**Type**: Game development monorepo
**Language**: Rust (Bevy), C# (Unity), GDScript (Godot), Python
**Purpose**: Collection of game projects across multiple engines
**Owner**: AreteDriver

---

## Architecture

```
arcade/
├── eve-rebellion/          # Bevy 0.15 / Rust — EVE Online arcade shooter (v2.0.0, 274 tests)
├── yokai-blade/            # Unity / C# — Japanese mythology action game
├── chronicle-rpg/          # Godot — EVE Chronicle RPG
├── dust-rts/               # Unity / C# — DUST 514 inspired RTS
├── rts-prototype/          # Bevy / Rust — RTS prototype
├── sprocket-science/       # Godot — Physics puzzle game
└── README.md
```

Each game is self-contained with its own build system and dependencies.

---

## Common Commands

### eve-rebellion (Bevy/Rust)
```bash
cd eve-rebellion
cargo run
cargo test
cargo build --release --target wasm32-unknown-unknown  # WASM build
```

---

## Coding Standards

Per-game conventions based on engine:
- **Rust/Bevy**: cargo fmt, clippy, ECS patterns
- **C#/Unity**: Unity conventions
- **GDScript/Godot**: Godot style guide

---

## Git Conventions

- Conventional commits
- Branch: main
- Games were consolidated from standalone repos (YokaiBlade, Dust_RTS, etc.)
