# YOKAI BLADE — Telegraph Semantic Reference

> This document defines the **global telegraph language**. It is absolute and inviolable.

---

## Visual Telegraphs

### White Flash (1 frame)
- **Meaning:** Perfect deflect window is NOW
- **Duration:** Exactly 1 frame
- **Player response:** Press deflect immediately
- **Implementation:** Must be frame-accurate, tied to fixed timestep

### Red Glow
- **Meaning:** Undodgeable hazard approaching
- **Duration:** Visible throughout threat window
- **Player response:** Reposition (cannot deflect)
- **Implementation:** Must persist until hazard resolves

### Blue Shimmer
- **Meaning:** Illusion — never damages
- **Duration:** While illusion is active
- **Player response:** Safe to ignore, focus on real threats
- **Implementation:** Used by deception bosses (Tanuki, Kitsune)

---

## Audio Telegraphs

### Low Bass Cue
- **Meaning:** Arena-wide threat incoming
- **Timing:** Plays before threat activates
- **Player response:** Prepare for major attack or repositioning
- **Implementation:** Must sidechain against music/ambience

### High Chime
- **Meaning:** Strike window is opening
- **Timing:** Plays when boss becomes vulnerable
- **Player response:** Attack now
- **Implementation:** Clear and distinct from other audio

---

## Semantic Rules

### Rule 1: One Meaning, Always
Each semantic signal has exactly one interpretation. There are no exceptions.

```
WRONG: "White flash means deflect, except for Boss X where it means dodge"
RIGHT: "White flash always means deflect window"
```

### Rule 2: No Per-Boss Overrides
Bosses can vary their attacks, timing, and patterns. They cannot change what signals mean.

```
WRONG: Boss.OverrideTelegraphMeaning(TelegraphSemantic.WhiteFlash, "dodge")
RIGHT: Boss uses different attacks, all following global semantics
```

### Rule 3: Visual Deception ≠ Semantic Deception
Tanuki can look like other enemies. Tanuki cannot make white flash mean something else.

```
ALLOWED: Tanuki visually appears as Oni
FORBIDDEN: Tanuki's "fake white flash" that doesn't mean deflect
```

### Rule 4: Comedy Doesn't Excuse Dishonesty
Shirime is absurd. Shirime still telegraphs honestly.

```
ALLOWED: Funny animation before attack
FORBIDDEN: Hiding real threat timing behind comedy
```

---

## Implementation Notes

### TelegraphSemantic Enum
```csharp
public enum TelegraphSemantic
{
    None,
    PerfectDeflectWindow,  // White flash
    UndodgeableHazard,     // Red glow
    Illusion,              // Blue shimmer
    ArenaWideThreat,       // Low bass
    StrikeWindowOpen       // High chime
}
```

### TelegraphCatalog
ScriptableObject mapping each semantic to:
- VFX prefab reference
- SFX audio clip reference
- Duration (where applicable)
- Priority (for overlapping signals)

### TelegraphSystem.Emit()
```csharp
// Central emission point - all telegraphs go through here
TelegraphSystem.Emit(TelegraphSemantic semantic, TelegraphContext context);
```

No boss, attack, or system should emit visual/audio cues directly. All signals route through the telegraph system to ensure semantic consistency.
