# YOKAI BLADE — Project Checklist + Execution Plan (Claude Code)

This is a **stepwise, gated build plan**. Claude must follow order and stop at gates.
Treat invariants as API contracts; violations are bugs.

---

## 0) Ground Rules (Non‑Negotiable)

- **Primary goal:** Vertical Slice (Shirime → Tanuki → Oni) playable end-to-end
- **No art polish** until slice passes readability + fairness QA gates (graybox only)
- **No new mechanics** unless they improve the vertical slice
- **Telegraph semantics never lie** (global contract)
- **Audio telegraph cues are sacred** (must cut through any mix)
- **Death feedback must explain failure within 1 second**

### Chosen defaults (edit only if already decided elsewhere)
- Engine: Unity LTS
- Language: C#
- Target: PC (controller + keyboard)
- Timing authority: Fixed timestep or quantized frame clock (documented in code)

---

## 1) Repo + Project Setup (Day 0–1)

### Checklist
- [ ] Create Unity LTS project and commit baseline
- [ ] Enforce folder layout (below)
- [ ] Add `.editorconfig` + formatting rules
- [ ] Add CI (build + tests) placeholder
- [ ] Add `docs/` with invariants and this plan

### Folder Layout (Exact)
```
Assets/
  Core/
    Combat/
    Telegraphs/
    Boss/
    Audio/
    Input/
    Data/
    UI/
    Util/
  Game/
    Scenes/
    Prefabs/
    ScriptableObjects/
  Tests/
    EditMode/
    PlayMode/
docs/
tools/
```

**Gate 1:** Project builds + enters Boot scene. No warnings treated as “known debt” unless documented.

---

## 2) Core Systems — Build Order (Do Not Reorder)

### 2.1 Telegraph System (BLOCKER)
**Intent:** Central semantic truth layer. No per-boss overrides.

Checklist
- [ ] Define `TelegraphSemantic` enum
- [ ] Define mapping asset: `TelegraphCatalog` (semantic → SFX/VFX IDs)
- [ ] `TelegraphSystem.Emit(semantic, context)` event bus
- [ ] Debug overlay prints last semantic emitted

Acceptance
- [ ] One semantic always produces the same meaning everywhere
- [ ] Bosses cannot override semantic meaning

**Gate 2:** Unit test passes: semantic mapping stable + no override paths exist.

---

### 2.2 Input System
Checklist
- [ ] Define actions: Move, Dodge, Deflect, Strike
- [ ] Define buffering windows + priority rules
- [ ] Implement PlayerController with deterministic update order

Acceptance
- [ ] Deflect always wins priority when overlapping inputs
- [ ] Buffered inputs replay consistently across frame rates

**Gate 3:** Input test scene validates buffering + priorities.

---

### 2.3 Attack Data Pipeline (Data-Driven)
Checklist
- [ ] `AttackDefinition` ScriptableObject: timing, semantic, damage, response
- [ ] Author 3 sample attacks as assets
- [ ] Validate assets at load (no missing IDs, sane windows)

Acceptance
- [ ] No hard-coded attack timings
- [ ] Attack windows computed from data only

**Gate 4:** Data validation logs zero errors; sample attacks run in test harness.

---

### 2.4 Attack Runner / Timeline
Checklist
- [ ] Implement Startup → Active → Recovery timeline
- [ ] Emit telegraph at startup begin
- [ ] Spawn hit volumes / projectiles during active
- [ ] Provide callbacks for deflect and hit results

Acceptance
- [ ] Running the same attack 20x yields same timing
- [ ] Timing not tied to animation speed

**Gate 5:** Regression test: attack timing stable at 30/60/120 fps.

---

### 2.5 Deflect System
Checklist
- [ ] Perfect deflect window + standard deflect window
- [ ] Reward hooks: meter gain + stagger/strike window
- [ ] Reflect behavior optionally per attack

Acceptance
- [ ] Perfect deflect is reliable (no “sometimes”)
- [ ] Missed deflect produces explainable hit

**Gate 6:** Practice dummy validates deflect timing windows.

---

### 2.6 Death Feedback System
Checklist
- [ ] Freeze manager (1 second)
- [ ] Death panel: attack name + response icon
- [ ] Fast retry loop

Acceptance
- [ ] Player can infer “what happened” within 1 second
- [ ] No tutorial text required

**Gate 7:** Death feedback triggered from synthetic test events + real hits.

---

## 3) Vertical Slice — Phase Delivery

### Phase 1: SHIRIME ONLY (First playable)
Checklist
- [ ] Graybox Shirime arena
- [ ] EncounterDirector loads arena + plays intro line + starts fight
- [ ] Shirime state machine: Bow → Wait → EyeBeam OR Punish if attacked early
- [ ] Victory on perfect deflect (EyeBeam)
- [ ] No music until player commits

Acceptance
- [ ] Wait+deflect wins consistently
- [ ] Attack early triggers punish clearly (fair tells)
- [ ] No randomness in core loop

**Gate 8 (Slice Gate A):** 10 consecutive clears by developer at baseline tuning; 0 unclear deaths logged.

---

### Phase 2: TANUKI
Checklist
- [ ] Tanuki arena + transition “Trickster Road”
- [ ] Visual deception only; semantics never lie
- [ ] Counter punishes blind aggression
- [ ] Reward patience with strike window

Acceptance
- [ ] Guessing fails; reading succeeds
- [ ] Telegraph audio remains readable under full mix

**Gate 9 (Slice Gate B):** 10 clears; at least 3 first-time testers report deaths as explainable.

---

### Phase 3: ONI
Checklist
- [ ] Oni arena (flat, empty)
- [ ] 3 phases: heavy telegraphs → counter stance → barehand chains
- [ ] No gimmicks, no hazards
- [ ] Minimal music motif

Acceptance
- [ ] Losses feel deserved
- [ ] Fight validates entire combat system without novelty

**Gate 10 (Slice Gate C):** 5 clears without UI assist; 0 semantic inconsistencies.

---

## 4) Audio & Mix (Parallel, but Must Meet Gates)

Checklist
- [ ] Buses: Telegraph / SFX / Music / Ambience
- [ ] Sidechain telegraph bus against music+ambience during threat
- [ ] “No comedy sounds” enforced (audit)
- [ ] Test under laptop speakers + stream compression

Acceptance
- [ ] Telegraph cues always audible
- [ ] Shirime reveal remains mostly silent

---

## 5) Tooling (Mandatory)

Checklist
- [ ] Debug overlay shows: boss state, attack id, last semantic, deflect window active
- [ ] Logging for: attack fired, telegraph emitted, deflect result, death feedback payload
- [ ] Simple tuning table export (CSV) for attack windows

---

## 6) QA Gates (Definition of Done for Slice)

**Hard gates**
- [ ] Semantic mapping tests pass
- [ ] Timing regression tests pass (30/60/120)
- [ ] Audio audibility checks pass
- [ ] Death feedback always populated correctly

**Manual gates**
- [ ] 10 Shirime clears
- [ ] 10 Tanuki clears
- [ ] 5 Oni clears

---

## 7) Weekly Cadence (Suggested)

Week 1: Setup + Telegraph + Input  
Week 2: Attack pipeline + Runner + Deflect  
Week 3: Shirime playable + Death feedback + basic audio routing  
Week 4: Tanuki + Oni + QA passes + capture-ready build

---

## 8) Stop Conditions (Prevent Thrash)

Claude must stop if:
- A new feature doesn’t serve the slice
- More than one major subsystem is modified at once
- Any semantic invariant is violated
- Tuning changes are made without notes
