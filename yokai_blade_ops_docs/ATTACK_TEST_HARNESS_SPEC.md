# Attack Test Harness (Must Build Early)

## Purpose
A deterministic harness for tuning and QA. Avoids “feel-only” tuning.

## Scene
`Assets/Game/Scenes/AttackTest.unity`

## UI Controls (simple)
- Dropdown: Boss
- Dropdown: Attack ID
- Buttons: Play Once / Loop / Stop
- Slider: Time scale (0.5x–1.5x) [dev only]
- Toggle: Show hitboxes/hurtboxes
- Toggle: Show deflect windows (perfect/standard)
- Toggle: Simulate stream compression mix (audio preset)

## Runtime Overlay (always visible in this scene)
- Current attack ID
- Current phase (startup/active/recovery)
- Time since telegraph (ms)
- Perfect window active? (bool)
- Standard window active? (bool)
- Last telegraph semantic
- Bus levels: Telegraph/SFX/Music/Ambience + ducking state

## Metrics to Log (CSV in /logs)
- deflect_attempt_time_ms
- was_perfect
- was_success
- player_distance
- frame_rate

## Acceptance Criteria
- Same attack run 20 times yields identical window timings
- 30/60/120 fps does not change window results
- Telegraph cues remain audible under “compressed” preset
