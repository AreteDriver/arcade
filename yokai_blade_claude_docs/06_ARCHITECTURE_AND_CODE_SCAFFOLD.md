# YOKAI BLADE — Code + Architecture (Claude Code Share Doc)
Senior engineer framing: **data-driven combat**, **semantic telegraphs**, **testable invariants**, **tight vertical slice scope**.

This document is written to be pasted into Claude Code to generate real code scaffolding and iterate safely.

---

## 0) Assumptions (Make Explicit in Code)
- Game is a **pattern mastery** action title with strict telegraph semantics.
- Boss behavior is **data-driven** (attack definitions + state machine graph).
- Core invariants are enforced by **automated tests** (semantic telegraph mapping never changes).
- Vertical slice = **Shirime → Tanuki → Oni**, including approach scenes and transitions.

> Engine choice can vary. This doc provides **engine-agnostic architecture** + **Unity C# scaffolding** (most common for collaboration) and notes for adapting to Godot/Unreal.

---

## 1) Repository Layout (Recommended)

```
YokaiBlade/
  docs/
    00_MASTER_PROMPT.md
    01_BOSS_PROVERBS.md
    02_TELEGRAPH_AUDIO_RULES.md
    03_VERTICAL_SLICE_PITCH.md
    04_BOSS_INTRO_SCRIPTS.md
    05_VERTICAL_SLICE_IMPLEMENTATION_SPEC.md
    06_ARCHITECTURE_AND_CODE_SCAFFOLD.md   <-- this file
  src/
    Core/
      Combat/
      Telegraphs/
      Boss/
      Audio/
      UI/
      Input/
      Data/
      Util/
    Game/
      Scenes/
      Prefabs/
      ScriptableObjects/ (or Resources/Data)
      Shaders/
      Audio/
    Tests/
      Core/
      Integration/
  tools/
    tuning/
    build/
```

**Rule:** “Core” is engine-light and deterministic where possible; “Game” is engine-specific.

---

## 2) Core Concepts (The Non-Negotiables)

### 2.1 Semantic Telegraphs (Truth Layer)
Telegraphs are not VFX; they are **semantic truth**:
- `PerfectDeflectWindow`
- `UndodgeableHazard`
- `IllusionNoDamage`
- `ArenaWideThreat`
- `StrikeWindowOpen`

Everything else (VFX/SFX/UI) renders this truth.

### 2.2 Data-Driven Attacks
Every attack is a **definition**, not hard-coded logic.

Each attack defines:
- Telegraph semantic
- Timing windows (startup/active/recovery)
- Deflect window frames (perfect + standard)
- Hit volumes (hurtbox/hitbox)
- Damage + knockback + status
- Audio event IDs
- VFX event IDs
- Camera shake profile (if any)
- “Death feedback” labels

### 2.3 Boss as State Machine + Attack Scheduler
Boss logic is:
- State graph (phases + sub-states)
- Scheduler selects next attack based on rules
- Transition guards (HP thresholds, time, player position, meter state)

---

## 3) Data Schemas (Engine-Agnostic)

### 3.1 TelegraphSemantic
```json
{
  "id": "PerfectDeflectWindow",
  "vfx": "FX_Telegraph_WhiteFlash_1f",
  "sfx": "SFX_Deflect_PerfectCue",
  "ui":  "UI_None"
}
```

### 3.2 AttackDefinition
```json
{
  "id": "Shirime_EyeBeam",
  "bossId": "Shirime",
  "semantic": "PerfectDeflectWindow",
  "startupMs": 900,
  "activeMs": 120,
  "recoveryMs": 800,
  "perfectDeflectWindowMs": 33,
  "standardDeflectWindowMs": 120,
  "damage": 20,
  "knockback": { "x": 0, "y": 2.5 },
  "hitShape": { "type": "Capsule", "radius": 0.4, "length": 18.0 },
  "audio": {
    "telegraphCue": "SFX_Telegraph_WhiteFlash",
    "attackFire": "SFX_Shirime_BeamFire"
  },
  "vfx": {
    "telegraph": "FX_WhiteFlash_1f",
    "fire": "FX_Beam",
    "impact": "FX_BeamImpact"
  },
  "deathFeedback": {
    "name": "Eye Beam",
    "response": "DEFLECT_PERFECT"
  }
}
```

### 3.3 BossStateGraph (simplified)
```json
{
  "bossId": "Oni",
  "states": [
    { "id": "P1", "onEnter": ["PlayIntro"], "attacks": ["Oni_Slam", "Oni_Sweep", "Oni_Grab"] },
    { "id": "P2", "guard": "hp<=0.5", "attacks": ["Oni_CounterStance", "Oni_QuickJabChain"] },
    { "id": "P3", "guard": "hp<=0.25", "attacks": ["Oni_Barehand_ChainA", "Oni_Barehand_ChainB"] }
  ],
  "transitions": [
    { "from": "P1", "to": "P2", "when": "hp<=0.5" },
    { "from": "P2", "to": "P3", "when": "hp<=0.25" }
  ]
}
```

---

## 4) Systems Architecture (Runtime)

### 4.1 Combat Loop (High-Level)
```
Input → PlayerController → CombatResolver
     → DeflectSystem / DodgeSystem
     → HitSystem (collisions → damage)
     → MeterSystem (gain/spend)
     → BossAI (attack scheduler)
     → TelegraphSystem (semantic events → audio/vfx)
     → DeathFeedbackSystem (on player death)
```

### 4.2 Determinism & Testability
- Timing windows should be based on a single clock:
  - `FixedUpdate` ticks OR engine time with quantization to frames
- All windows computed from `AttackTimeline` data to avoid per-boss drift.

---

## 5) Vertical Slice: Encounter Director
Vertical slice needs a lightweight **EncounterDirector** that:
- Loads approach scene
- Plays inscription / intro
- Starts boss fight
- On victory, transitions to next scene

### Interface
```csharp
public interface IEncounterDirector {
  void StartEncounter(string encounterId);
  void OnBossDefeated(string bossId);
}
```

---

## 6) Unity C# Scaffolding (Suggested)
> These are minimal skeletons intended for Claude Code to expand.

### 6.1 Core Enums & Models
```csharp
// src/Core/Telegraphs/TelegraphSemantic.cs
public enum TelegraphSemantic {
  PerfectDeflectWindow,
  UndodgeableHazard,
  IllusionNoDamage,
  ArenaWideThreat,
  StrikeWindowOpen
}

public enum DeathResponse {
  DEFLECT_PERFECT,
  DEFLECT,
  DODGE,
  MOVE_POSITION,
  STRIKE_WINDOW
}
```

```csharp
// src/Core/Data/AttackDefinition.cs
using UnityEngine;

[CreateAssetMenu(menuName="YokaiBlade/AttackDefinition")]
public class AttackDefinition : ScriptableObject {
  public string id;
  public string bossId;
  public TelegraphSemantic semantic;

  [Header("Timing (ms)")]
  public int startupMs;
  public int activeMs;
  public int recoveryMs;
  public int perfectDeflectWindowMs;
  public int standardDeflectWindowMs;

  [Header("Combat")]
  public int damage;
  public Vector2 knockback;

  [Header("FX IDs")]
  public string telegraphVfx;
  public string fireVfx;
  public string impactVfx;

  [Header("Audio IDs")]
  public string telegraphSfx;
  public string fireSfx;

  [Header("Death Feedback")]
  public string feedbackName;
  public DeathResponse response;
}
```

### 6.2 Telegraph System (Semantic → Render)
```csharp
// src/Core/Telegraphs/TelegraphSystem.cs
using System;
using UnityEngine;

public sealed class TelegraphEvent {
  public TelegraphSemantic Semantic { get; }
  public string VfxId { get; }
  public string SfxId { get; }
  public float Duration { get; }
  public TelegraphEvent(TelegraphSemantic semantic, string vfxId, string sfxId, float duration) {
    Semantic = semantic; VfxId = vfxId; SfxId = sfxId; Duration = duration;
  }
}

public interface ITelegraphSystem {
  event Action<TelegraphEvent> OnTelegraph;
  void Emit(TelegraphEvent e);
}

public class TelegraphSystem : MonoBehaviour, ITelegraphSystem {
  public event Action<TelegraphEvent> OnTelegraph;
  public void Emit(TelegraphEvent e) => OnTelegraph?.Invoke(e);
}
```

### 6.3 Attack Timeline Runner
```csharp
// src/Core/Boss/AttackRunner.cs
using System.Collections;
using UnityEngine;

public interface IAttackRunner {
  Coroutine RunAttack(AttackDefinition def, Transform boss, Transform player);
}

public class AttackRunner : MonoBehaviour, IAttackRunner {
  [SerializeField] private TelegraphSystem telegraphs;
  [SerializeField] private FxRouter fx;
  [SerializeField] private AudioRouter audio;

  public Coroutine RunAttack(AttackDefinition def, Transform boss, Transform player) {
    return StartCoroutine(CoRun(def, boss, player));
  }

  private IEnumerator CoRun(AttackDefinition def, Transform boss, Transform player) {
    // Telegraph (semantic truth)
    telegraphs.Emit(new TelegraphEvent(def.semantic, def.telegraphVfx, def.telegraphSfx, def.startupMs / 1000f));
    fx.Play(def.telegraphVfx, boss.position);
    audio.Play(def.telegraphSfx, boss.position);

    yield return new WaitForSeconds(def.startupMs / 1000f);

    // Fire
    fx.Play(def.fireVfx, boss.position);
    audio.Play(def.fireSfx, boss.position);

    // TODO: spawn hit volumes / projectiles based on def
    yield return new WaitForSeconds(def.activeMs / 1000f);

    yield return new WaitForSeconds(def.recoveryMs / 1000f);
  }
}
```

### 6.4 Boss Brain (State Machine + Scheduler)
```csharp
// src/Core/Boss/BossBrain.cs
using System.Collections.Generic;
using UnityEngine;

public class BossBrain : MonoBehaviour {
  [SerializeField] private string bossId;
  [SerializeField] private List<AttackDefinition> attacks;
  [SerializeField] private AttackRunner runner;
  [SerializeField] private BossHealth health;

  private bool busy;

  void Update() {
    if (busy) return;

    // Phase logic (minimal MVP)
    // TODO: swap attack pools based on health thresholds
    var next = PickNextAttack();
    if (next == null) return;

    busy = true;
    StartCoroutine(RunAndClear(next));
  }

  private AttackDefinition PickNextAttack() {
    if (attacks == null || attacks.Count == 0) return null;
    return attacks[Random.Range(0, attacks.Count)];
  }

  private System.Collections.IEnumerator RunAndClear(AttackDefinition def) {
    yield return runner.RunAttack(def, transform, null);
    busy = false;
  }
}
```

### 6.5 Deflect System (Collision → Window Check)
```csharp
// src/Core/Combat/DeflectSystem.cs
using UnityEngine;

public class DeflectSystem : MonoBehaviour {
  public bool TryDeflect(AttackDefinition attack, float timeSinceTelegraphMs) {
    // Perfect window: center around attack fire time, or defined by attack timeline.
    // MVP: interpret timeSinceTelegraphMs relative to startup.
    float t = timeSinceTelegraphMs;
    float perfectStart = attack.startupMs - attack.perfectDeflectWindowMs * 0.5f;
    float perfectEnd   = attack.startupMs + attack.perfectDeflectWindowMs * 0.5f;

    return (t >= perfectStart && t <= perfectEnd);
  }
}
```

### 6.6 Death Feedback System
```csharp
// src/Core/UI/DeathFeedbackSystem.cs
using UnityEngine;
using TMPro;

public class DeathFeedbackSystem : MonoBehaviour {
  [SerializeField] private CanvasGroup panel;
  [SerializeField] private TMP_Text attackName;
  [SerializeField] private TMP_Text responseText;

  public void Show(string name, DeathResponse response) {
    // 1s freeze is handled by Time.timeScale or a dedicated freeze manager
    attackName.text = name;
    responseText.text = response.ToString().Replace('_', ' ');
    panel.alpha = 1;
    panel.blocksRaycasts = true;
  }
}
```

---

## 7) Audio Architecture (Mix Guarantees)
Implement a simple audio routing layer:

- `AudioRouter.Play(eventId, position)`
- Mix buses:
  - `TelegraphBus`
  - `SFXBus`
  - `MusicBus`
  - `AmbienceBus`

**Guarantee:** During threat moments, `TelegraphBus` is sidechained to reduce `MusicBus` and `AmbienceBus`.

### Example (conceptual)
```csharp
public class AudioRouter : MonoBehaviour {
  public void Play(string id, Vector3 pos) { /* map id→clip/event */ }
  public void DuckMusic(float db, float duration) { /* sidechain or volume ramp */ }
}
```

---

## 8) Automated Tests (Treat Invariant Violations as Bugs)

### 8.1 Telegraph Semantic Mapping Test
- Ensure each `TelegraphSemantic` maps to stable `SFX`/`VFX` IDs.
- Assert no boss overrides semantic mapping.

### 8.2 Attack Window Tests
- Given `AttackDefinition`, computed deflect windows must match spec.
- Prevent “silent timing drift.”

### 8.3 Mix Audibility Test (Pragmatic)
- Offline: validate audio routing is correct (telegraph cues always go through TelegraphBus).
- Runtime debug HUD: show current bus levels and active ducks.

---

## 9) Slice Content Specs (Minimal Data Set)

### 9.1 Shirime Data
- Attacks:
  - `Shirime_PoliteWait` (non-damaging behavior state)
  - `Shirime_EyeBeam` (single, perfect-deflect end condition)
  - `Shirime_PunishFlash` (triggered if player attacks too early; fair tell)

**Victory Condition:** perfect deflect on EyeBeam OR survive punish and then EyeBeam cycle.

### 9.2 Tanuki Data
- Attacks:
  - `Tanuki_DecoyRush`
  - `Tanuki_CounterStance` (punishes blind swings)
  - `Tanuki_TellTrueStrikeWindow` (rewards patience)

**Rule:** visuals may lie; semantic telegraphs do not.

### 9.3 Oni Data
- Phase 1 heavy attacks
- Phase 2 counter stance
- Phase 3 bare-handed chains

---

## 10) Claude Code Tasks (Copy/Paste)
Use these tasks as directives for Claude Code:

1. Generate Unity project folder structure and core scripts under `src/Core`.
2. Implement `TelegraphSystem`, `AttackRunner`, `BossBrain`, `DeflectSystem`, `MeterSystem` (stub), `DeathFeedbackSystem`.
3. Implement ScriptableObject data pipeline: create example `AttackDefinition` assets for Shirime/Tanuki/Oni.
4. Implement basic collision/hit volume spawning for beam and melee arcs.
5. Add a minimal `EncounterDirector` to sequence scenes and boss intros.
6. Add tests: telegraph mapping invariant + deflect window tests.
7. Add debug overlay: current boss state + last telegraph semantic + bus ducking status.

---

## 11) Notes for Godot / Unreal Adaptation
- Replace ScriptableObjects with:
  - Godot: `.tres` resources / JSON + `Resource` classes
  - Unreal: DataAssets/DataTables + GameplayTags
- Replace coroutines with:
  - Godot: `await get_tree().create_timer()`
  - Unreal: Timers / latent actions
- Keep semantics identical.

---

## 12) Definition of Done (Slice)
- Player can complete Shirime → Tanuki → Oni in a single run.
- Every death shows attack + correct response.
- Telegraph cues remain readable in all scenes.
- No boss violates semantic telegraph mapping.
