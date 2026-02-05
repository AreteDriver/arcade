# YOKAI BLADE — Project Plan

## Primary Goal

**Vertical Slice (Shirime → Tanuki → Oni) playable end-to-end**

---

## Technical Defaults

| Setting | Value |
|---------|-------|
| Engine | Unity LTS |
| Language | C# |
| Target | PC (controller + keyboard) |
| Timing | Fixed timestep or quantized frame clock |

---

## Build Order (Do Not Reorder)

### Phase 1: Core Systems

1. **Telegraph System** (BLOCKER)
   - `TelegraphSemantic` enum
   - `TelegraphCatalog` mapping asset
   - `TelegraphSystem.Emit()` event bus
   - Debug overlay

2. **Input System**
   - Actions: Move, Dodge, Deflect, Strike
   - Buffering windows + priority rules
   - PlayerController with deterministic update

3. **Attack Data Pipeline**
   - `AttackDefinition` ScriptableObject
   - Data validation at load
   - No hard-coded timings

4. **Attack Runner / Timeline**
   - Startup → Active → Recovery
   - Telegraph emission at startup
   - Hit volume spawning
   - Deflect/hit callbacks

5. **Deflect System**
   - Perfect + standard windows
   - Meter gain + stagger rewards
   - Optional reflect behavior

6. **Death Feedback System**
   - Freeze manager
   - Death panel (attack name + response)
   - Fast retry loop

### Phase 2: Vertical Slice Bosses

1. **Shirime** (First Playable)
   - Graybox arena
   - Bow → Wait → EyeBeam/Punish state machine
   - Victory on perfect deflect

2. **Tanuki**
   - Arena + Trickster Road transition
   - Visual deception, honest semantics
   - Counter punishes aggression

3. **Oni**
   - Flat empty arena
   - Three phases: heavy → counter → barehand
   - Pure combat validation

### Phase 3: Polish & QA

- Audio mix (telegraph audibility)
- Debug tooling
- Gate validation

---

## Gates (Must Pass)

| Gate | Requirement |
|------|-------------|
| 1 | Project builds, enters Boot scene |
| 2 | Semantic mapping stable, no override paths |
| 3 | Input buffering + priorities validated |
| 4 | Attack data validation passes |
| 5 | Attack timing stable at 30/60/120 fps |
| 6 | Deflect timing windows validated |
| 7 | Death feedback triggers correctly |
| 8 | 10 Shirime clears, 0 unclear deaths |
| 9 | 10 Tanuki clears, explainable deaths |
| 10 | 5 Oni clears, 0 semantic inconsistencies |

---

## Stop Conditions

Stop immediately if:
- A new feature doesn't serve the slice
- More than one major subsystem modified at once
- Any semantic invariant is violated
- Tuning changes made without notes

---

## Folder Structure

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
