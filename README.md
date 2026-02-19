# Arcade

Game development monorepo — Bevy/Rust, Unity/C#, Godot/GDScript.

## Games

| Game | Engine | Language | Status |
|------|--------|----------|--------|
| [eve-rebellion](eve-rebellion/) | Bevy 0.15 | Rust | Active — v1.9.0, 163 tests, WASM deployed |
| [yokai-blade](yokai-blade/) | Unity | C# | Active |
| [sprocket-science](sprocket-science/) | Godot | GDScript | Active |
| [rts-prototype](rts-prototype/) | Godot | GDScript | Archived |
| [dust-rts](dust-rts/) | Unity | C# | Archived |

## Structure

Each game lives in its own top-level directory with full git history preserved via `git subtree`.

```
arcade/
├── eve-rebellion/       # EVE Online arcade shooters — 4 campaigns, procedural audio
├── yokai-blade/         # Sekiro-inspired action game with Japanese yokai
├── sprocket-science/    # Godot sandbox builder
├── rts-prototype/       # RTS prototype (archived)
└── dust-rts/            # RTS game (archived)
```
