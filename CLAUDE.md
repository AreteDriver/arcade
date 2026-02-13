# CLAUDE.md — Machine Shop of Tomorrow

## Project Overview
Physics sandbox game for kids (6-12). Build, fix, and invent fantastical machines.  
**Engine:** Godot 4.3+ | **Language:** GDScript | **Platform:** Android (primary)

## Key Documents
- `docs/CONCEPT.md` — Full game design document (READ THIS FIRST)
- `prompts/01_core_engine.md` — Phase 1: Base systems, components, ports, wires
- `prompts/02_juice_and_feedback.md` — Phase 2: Visual/audio feedback, particles
- `prompts/03_discovery_mode.md` — Phase 3: Structured gameplay, World 1
- `prompts/04_content_and_polish.md` — Phase 4: Full content, sandbox, Android export

## Architecture Decisions
- **Component Graph** — Machines are directed graphs. Nodes = components, edges = typed wires.
- **Port Types** — Energy (yellow), Flow (blue), Signal (green). Only matching types connect.
- **State Machine** — Every component: IDLE → ACTIVE → BROKEN | OVERLOADED
- **Signals over references** — Components communicate via Godot signals, never direct calls.
- **JSON serialization** — All save data is JSON. Machine layouts, player progress, inventions.

## Code Conventions
- snake_case for variables/functions, PascalCase for classes
- Typed everything: `var speed: float = 0.0`, `func get_ports() -> Array[Port]:`
- @export_group for organized inspector panels
- Comment all public methods and exported vars
- Scene files (.tscn) live next to their scripts
- Resources (.tres) in res://content/

## Performance Budget
- Max 150 RigidBody2D simultaneously
- Max 500 particles visible
- Target 60fps on mid-range Android 2020+
- Object pool particles and flow objects

## Current Phase
Phase 3 — Discovery Mode. See `prompts/03_discovery_mode.md` for detailed task.
- Phase 1 (Core Engine) — Complete
- Phase 2 (Juice & Feedback) — Complete
- Phase 3 (Discovery Mode) — Complete (5 new components, 4 challenge types, menus, World 1)
- Phase 4 (Content & Polish) — Next

## How to Work
1. Read the relevant prompt file for the current phase
2. Read `docs/CONCEPT.md` for design context
3. Implement in order — each phase builds on the previous
4. Test in Godot editor before moving to next phase
5. Update this file's "Current Phase" when advancing
