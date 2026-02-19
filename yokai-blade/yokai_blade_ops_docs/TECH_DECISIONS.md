# TECH_DECISIONS.md (Lock File)

This file prevents churn. Update only with an explicit reason and date.

## Core
- Engine: Unity LTS (exact version: __________)
- Render Pipeline: URP
- Language: C#
- Platform (Phase 1): PC
- Baseline Controller: Xbox layout
- Baseline FPS for tuning: 60

## Timing / Determinism
- Timing authority: Fixed timestep (e.g., 50/60 Hz) OR quantized frame clock
- All attack windows are defined in data (not animations)
- Combat logic runs in deterministic update order

## Input
- Unity Input System
- Actions: Move, Dodge, Deflect, Strike, Interact, Pause
- Priority: Deflect > Dodge > Strike
- Buffering windows: (document numbers in tuning file)

## Audio
- Mixer buses: Telegraph, SFX, Music, Ambience
- Telegraph bus sidechains Music/Ambience during threat moments
- No “comedy sounds” allowed

## Data
- AttackDefinition: ScriptableObject assets (authoritative)
- Boss graphs: ScriptableObject / JSON (choose one, document here)
- Tuning values tracked in CSV/JSON and versioned

## Build / CI
- Repo: Git
- CI: build + unit tests + playmode smoke tests
- Commit standard: conventional commits

## Decision Log
| Date | Decision | Reason | Owner |
|------|----------|--------|-------|
| ____ | ____ | ____ | ____ |
