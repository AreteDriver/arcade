# YOKAI BLADE — Vertical Slice Implementation Spec (Shirime → Tanuki → Oni)

Senior engineering view: define scope, acceptance criteria, and build order.

## 1) Scope

Deliver a playable slice with:
- Walk-up + inscriptions
- Three boss fights: Shirime, Tanuki, Oni
- Transitions between arenas
- Core combat loop implemented (deflect, strike window, meter, death feedback)
- Audio telegraph system adhering to invariants

Target runtime: 45–60 minutes for first-time player.

## 2) Shared Systems Required

### 2.1 Global Telegraph System
- Central mapping: {telegraph_type -> VFX + SFX + gameplay semantic}
- Enforce invariants via automated tests (see §7)

### 2.2 Deflect System
- Perfect deflect window (frame-accurate)
- Standard deflect window (wider, less reward)
- Reward hooks:
  - meter gain
  - boss stagger / opening
  - projectile reflect (where applicable)

### 2.3 Strike Window System
- Boss exposes “strike window” state
- High-chime cue + visual highlight
- Damage multipliers or vulnerability as needed

### 2.4 Meter System
- No passive regen
- Gain from mastery actions only
- Spend on defined abilities (at least 1 for slice)
- Optional: “punish misuse” hook for Tanuki (light) and Oni (counter stance)

### 2.5 Death Feedback
- 1 second freeze
- Show attack name
- Show response icon
- Optional ghost replay (MVP: show icon + short caption)
- Must be skip-fast for repeated attempts

## 3) Encounter Specs

### 3.1 Shirime — Etiquette Trial
**Primary objective:** teach restraint and reading.

- Arena: quiet road clearing
- Music: none until commitment
- Behavior:
  - Passive approach + bow + wait loop
  - If player attacks before “show”:
    - Flash (blindness debuff)
    - Spawn a short ambush wave or deliver a punish attack (keep fair tells)
  - If player waits:
    - Shirime reveals and fires single beam with perfect-deflect tell
    - Perfect deflect ends encounter immediately (win condition)
- Acceptance:
  - Players who wait and deflect win consistently
  - Players who swing immediately learn quickly why it fails (clear death feedback)

### 3.2 Tanuki — Deception Trial
**Primary objective:** punish assumptions; enforce telegraph trust.

- Arena: forest clearing with decoys
- Visual deception:
  - False forms, decoy clones, wrong silhouettes
  - NEVER false telegraph semantics
- Mechanics:
  - Attack patterns that look similar but share truthful cues
  - “Guessing” punished via counters
- Acceptance:
  - Skilled players succeed by reading telegraph syntax, not appearance
  - Telegraph audio remains audible through mix

### 3.3 Oni — Truth Trial
**Primary objective:** pure execution; no gimmicks.

- Arena: flat, empty
- Phases:
  1) telegraphed heavy attacks (teach respect)
  2) counter stance + tighter windows
  3) bare-handed rapid chains (final proof)
- Acceptance:
  - No environmental hazards
  - Losses feel deserved; cues consistent
  - Victory feels clean and final

## 4) Transitions / Narrative Beats

- Shrine inscription before Shirime (proverb)
- Trickster Road: subtle environment inconsistencies (no UI)
- Gate of Jigoku: silence drop + “skill remains” proverb

## 5) Audio Checklist

- Shirime: minimal ambience, no music until commitment
- Tanuki: playful rhythm, no parody; telegraph cues sacrosanct
- Oni: minimal motif; emphasize weight and spacing

## 6) Performance / Streaming Considerations

- Ensure cues survive stream compression
- Avoid relying on stereo-only tells
- Keep boss intros skippable after first view

## 7) Engineering Acceptance Tests (Recommended)

- Unit test: telegraph semantic mapping cannot change per boss
- Snapshot tests: deflect window duration equals spec per attack
- Audio mix test: telegraph cues peak above music by N dB during threat
- Replay test: death feedback must include (attack_name, response_type)

## 8) Deliverables

- Playable build (PC)
- 10–15 minute capture-ready “best run” sequence
- Design notes + tuning table (attack timings, windows, damage)
