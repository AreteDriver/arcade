# Tanuki Arena Specification

## Overview

Tanuki is the **second boss** in the vertical slice. This yokai teaches **observation over appearance** — it uses visual deception but the telegraph semantics remain honest.

**Scene Path:** `Assets/Game/Scenes/TanukiArena.unity`

---

## Boss Design Summary

### Tanuki (狸)
*"The trickster who cannot lie"*

A shapeshifting raccoon dog that transforms into various creatures. Its disguises are convincing, but its attack telegraphs follow the global semantic rules — illusions shimmer blue, real attacks flash white.

### Core Lesson
**Watch the signals, not the appearance.** Visual deception ≠ semantic deception.

### Key Invariant
From INVARIANTS.md:
> *"Visual deception is allowed (Tanuki). Semantic deception is forbidden."*

The Tanuki can *look* like anything. It cannot make white flash mean something other than "deflect now."

### Behavior Loop
```
Intro → Idle → Transforming → Disguised → FakeAttack? → RealAttack → Idle → ...
                                  ↓
                          [Player attacks]
                                  ↓
                              Counter
```

| State | Duration | Trigger |
|-------|----------|---------|
| Intro | 1.0s | Encounter start |
| Idle | 1.5s | After attack completes |
| Transforming | 0.5s | After idle |
| Disguised | 2.0-4.0s (random) | After transforming |
| FakeAttack | 0.8s | 40% chance from Disguised |
| RealAttack | Attack duration | After Disguised or FakeAttack |
| Counter | Attack duration | Player attacked during Disguised |
| Staggered | Via deflect | Successful deflect |
| Defeated | Terminal | HP reaches 0 |

### Health System
- **3 HP** (unlike Shirime's 1-hit defeat)
- Damage only during Staggered state
- Each hit after stagger removes 1 HP

---

## Scene Hierarchy

```
TanukiArena (scene root)
├── --- ENVIRONMENT ---
├── Arena
│   ├── Floor
│   ├── Walls
│   ├── TricksterRoad (transition path visual)
│   └── Decorations (forest elements)
├── Lighting
│   ├── Directional Light
│   └── Fog (optional atmosphere)
├── --- GAMEPLAY ---
├── Player (prefab instance)
├── Tanuki (boss prefab)
├── TanukiEncounter (controller)
├── --- CAMERA ---
├── Main Camera
├── --- UI ---
└── Canvas
    ├── HealthDisplay (boss HP)
    ├── DeathPanel
    └── VictoryPanel
```

---

## Arena Layout

### Dimensions
| Property | Value | Notes |
|----------|-------|-------|
| Shape | Rectangular | More space for movement |
| Size | 25 x 20 units | Wider arena for dodging |
| Floor Height | Y = 0 | Flat |
| Wall Height | 3 units | Invisible colliders |

### Spawn Points
| Entity | Position | Rotation |
|--------|----------|----------|
| Player | (0, 0, -8) | (0, 0, 0) facing +Z |
| Tanuki | (0, 0, 6) | (0, 180, 0) facing -Z |

### Theme: Trickster Road
A forest path setting. The "road" between the mortal world and the spirit world where yokai play tricks on travelers.

**Visual Elements:**
- Dappled lighting (suggests forest canopy)
- Fog at edges (mysterious atmosphere)
- Torii gate fragments (optional decoration)
- Leaf particles (subtle movement)

### Floor
| Property | Value |
|----------|-------|
| Mesh | Plane or custom |
| Scale | (25, 1, 20) |
| Material | Earth/dirt texture, dark |
| Collider | BoxCollider |

---

## Tanuki Boss Prefab

**Path:** `Assets/Game/Prefabs/Bosses/Tanuki.prefab`

### Hierarchy
```
Tanuki (root)
├── Model
│   ├── TrueForm (raccoon dog mesh)
│   └── Disguises (swapped during transform)
│       ├── Disguise_0 (e.g., Oni silhouette)
│       ├── Disguise_1 (e.g., Shirime silhouette)
│       ├── Disguise_2 (e.g., Kappa silhouette)
│       ├── Disguise_3 (e.g., Human silhouette)
│       └── Disguise_4 (e.g., Stone statue)
├── HitBox
└── AttackOrigin
```

### Root Components

#### TanukiBoss Script
| Property | Value | Notes |
|----------|-------|-------|
| Real Attack | Ref to TanukiSlash.asset | Main attack |
| Counter Attack | Ref to TanukiCounter.asset | Punish attack |
| Idle Duration | 1.5 | Pause between cycles |
| Transform Duration | 0.5 | Transformation animation |
| Disguised Min Duration | 2.0 | Minimum disguise time |
| Disguised Max Duration | 4.0 | Maximum disguise time |
| Fake Attack Duration | 0.8 | Feint duration |
| Fake Attack Chance | 0.4 | 40% chance of feint |
| Health Points | 3 | Total HP |

#### AttackRunner Script
Added automatically.

#### HitDetector Script
| Property | Value |
|----------|-------|
| Target Layers | Player (8) |
| Debug Draw | true |

### Tag & Layer
| Property | Value |
|----------|-------|
| Tag | `Boss` |
| Layer | `Boss` (9) |

### Disguise System

When `OnTransform` fires with index 0-4:
1. Disable `TrueForm` mesh
2. Enable `Disguise_[index]` mesh
3. Play transformation VFX (poof of smoke/leaves)

When returning to Idle after attack:
1. Disable current disguise
2. Enable `TrueForm` mesh
3. Play reveal VFX

**Important:** Disguise is purely visual. Hitbox and attack origins remain constant.

---

## Attack Definitions

Create in `Assets/Game/ScriptableObjects/Attacks/Tanuki/`

### TanukiSlash.asset (Real Attack)

The main attack after disguise ends.

| Property | Value | Notes |
|----------|-------|-------|
| Attack Id | `tanuki_slash` | |
| Display Name | `Trickster Slash` | Shown on death |
| **Timing** | | |
| Startup Frames | 25 | 0.417s |
| Active Frames | 8 | 0.133s |
| Recovery Frames | 20 | 0.333s |
| **Telegraph** | | |
| Telegraph | PerfectDeflectWindow | White flash |
| Telegraph Lead Frames | 5 | |
| **Damage** | | |
| Damage | 1 | |
| Unblockable | false | |
| Correct Response | Deflect | |
| **Hitbox** | | |
| Hitbox Offset | (0, 1, 2) | |
| Hitbox Size | (4, 2, 3) | Wide slash |

### TanukiCounter.asset (Counter Attack)

Fast punish when player attacks during Disguised state.

| Property | Value | Notes |
|----------|-------|-------|
| Attack Id | `tanuki_counter` | |
| Display Name | `Trickster Counter` | Shown on death |
| **Timing** | | |
| Startup Frames | 12 | 0.2s (fast!) |
| Active Frames | 6 | 0.1s |
| Recovery Frames | 18 | 0.3s |
| **Telegraph** | | |
| Telegraph | PerfectDeflectWindow | White flash |
| Telegraph Lead Frames | 3 | Short warning |
| **Damage** | | |
| Damage | 1 | |
| Unblockable | false | |
| Correct Response | Deflect | |
| **Hitbox** | | |
| Hitbox Offset | (0, 1, 1.5) | |
| Hitbox Size | (3, 2, 2.5) | |

### TanukiFakeAttack (Visual Only)

**Not a real AttackDefinition** — this is a visual-only feint.

| Property | Value |
|----------|-------|
| Duration | 0.8s |
| Telegraph | **Illusion (Blue Shimmer)** |
| Damage | 0 (never hits) |
| Visual | Threatening animation |

**Implementation:**
During FakeAttack state:
1. Emit `TelegraphSemantic.Illusion` (blue shimmer)
2. Play attack animation
3. No hitbox spawned
4. Transition to RealAttack after 0.8s

This teaches players: **Blue shimmer = safe to ignore.**

---

## TanukiEncounter Controller

### Component: TanukiEncounter

| Property | Reference To |
|----------|--------------|
| Boss | Tanuki GameObject |
| Player | Player GameObject |
| Deflect System | Player's DeflectSystem |
| Death Feedback | Player's DeathFeedbackSystem |
| Boss Hit Detector | Tanuki's HitDetector |
| Player Hit Detector | Player's attack HitDetector |

### Key Difference from Shirime

Tanuki encounter has **Player Hit Detector** for the player's attacks:
- When player attacks hit boss hitbox
- Check if boss `IsVulnerable` (Staggered state)
- If vulnerable, call `TakeDamage()`

### Wiring Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     TanukiEncounter                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Player.OnActionExecuted ──┬──► Strike: Boss.NotifyPlayerAttacked()
│                            └──► Deflect: DeflectSystem.StartDeflect()
│                                                                 │
│  BossHitDetector.OnHit ────────► DeflectSystem.TryDeflect()     │
│                                       │                         │
│                          ┌────────────┴────────────┐            │
│                          ▼                         ▼            │
│                    Perfect/Standard             Miss            │
│                          │                         │            │
│                          ▼                         ▼            │
│                Boss.ApplyStagger()    DeathFeedback.TriggerDeath()
│                                                                 │
│  PlayerHitDetector.OnHit ──► If Boss.IsVulnerable:              │
│                                    Boss.TakeDamage()            │
│                                       │                         │
│                                       ▼                         │
│                              If HP <= 0: Boss.Defeat()          │
│                                                                 │
│  Boss.OnDefeated ──────────────────────────► Victory!           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Player Attack System

Unlike Shirime (where player only deflects), Tanuki requires the player to **attack during stagger** to deal damage.

### Player Attack HitDetector

Add to Player prefab or as child:

| Property | Value |
|----------|-------|
| Script | HitDetector |
| Target Layers | Boss (9) |
| Attached to | Player's AttackOrigin |

### Player AttackDefinition

Create: `Assets/Game/ScriptableObjects/Attacks/Player/PlayerSlash.asset`

| Property | Value |
|----------|-------|
| Attack Id | `player_slash` |
| Display Name | `Slash` |
| Startup Frames | 8 |
| Active Frames | 5 |
| Recovery Frames | 12 |
| Hitbox Offset | (0, 1, 1) |
| Hitbox Size | (2, 1.5, 2) |

### Attack Flow
1. Player presses Strike
2. PlayerController transitions to Attacking
3. Player's AttackRunner executes PlayerSlash
4. On Active frame, PlayerHitDetector checks for Boss collider
5. If boss is Staggered → TakeDamage()

---

## Telegraph Usage

### Semantic Mapping in This Fight

| Signal | Meaning | When Used |
|--------|---------|-----------|
| White Flash | Deflect now | RealAttack, Counter |
| Blue Shimmer | Illusion, ignore | FakeAttack |
| High Chime | Strike window | Staggered state |

### Teaching Moment

The Tanuki fight explicitly teaches:
1. **White flash** = Real threat, deflect
2. **Blue shimmer** = Fake, don't panic
3. **High chime** = Attack now (boss vulnerable)

Players who react to every visual threat will:
- Waste deflects on fake attacks
- Miss strike windows during stagger
- Take longer to defeat the boss

Players who read telegraphs will:
- Ignore blue shimmers
- Deflect white flashes
- Attack during high chimes

---

## Camera Setup

### Main Camera
| Property | Value |
|----------|-------|
| Position | (0, 10, -14) |
| Rotation | (35, 0, 0) |
| Projection | Perspective |
| FOV | 55 |
| Clear Flags | Solid Color |
| Background | Dark green-brown (#1a1f1a) |

### Framing
Slightly wider than Shirime arena to accommodate:
- Larger arena
- Transformation effects
- More lateral movement

---

## Lighting

### Directional Light
| Property | Value |
|----------|-------|
| Rotation | (45, -45, 0) |
| Color | Pale moonlight (#E8E8FF) |
| Intensity | 0.7 |
| Shadow Type | Soft Shadows |

### Ambient
| Property | Value |
|----------|-------|
| Source | Gradient |
| Sky Color | Dark blue (#0a0a1a) |
| Equator Color | Forest green (#0a1a0a) |
| Ground Color | Earth brown (#1a0f0a) |

### Fog (Optional)
| Property | Value |
|----------|-------|
| Mode | Exponential |
| Color | Mist gray (#2a2a2a) |
| Density | 0.02 |

Creates mysterious forest atmosphere.

---

## UI Requirements

### Health Display

Shows Tanuki's remaining HP.

| Element | Description |
|---------|-------------|
| Position | Top center |
| Style | 3 icons (full/empty) or health bar |
| Update | On TakeDamage() |

```
    ♦ ♦ ♦    (3 HP)
    ♦ ♦ ◇    (2 HP)
    ♦ ◇ ◇    (1 HP)
```

### DeathPanel

Same as Shirime. Shows attack name and correct response.

### VictoryPanel

| Element | Content |
|---------|---------|
| Text | "TANUKI DEFEATED" |
| Subtext | "You see through the illusion." |

---

## Victory Condition

Tanuki is defeated when:
1. Player deflects an attack (any result)
2. Boss enters Staggered state
3. Player attacks during Stagger
4. HP decreases
5. When HP reaches 0, boss is Defeated

**3 successful stagger + attack cycles required.**

---

## Testing Checklist

### Setup Verification
- [ ] Scene loads without errors
- [ ] Player spawns correctly
- [ ] Tanuki spawns with 3 HP
- [ ] HP display shows 3 full icons

### Disguise System
- [ ] Tanuki transforms after Idle
- [ ] Random disguise selected (0-4)
- [ ] Model swaps correctly
- [ ] Returns to true form after attack

### Attack Patterns
- [ ] RealAttack triggers after disguise duration
- [ ] FakeAttack triggers ~40% of time
- [ ] FakeAttack emits blue shimmer (Illusion)
- [ ] RealAttack emits white flash
- [ ] Counter triggers when player attacks during Disguised

### Combat Flow
- [ ] Deflecting RealAttack → Stagger
- [ ] Deflecting Counter → Stagger
- [ ] Attacking during Stagger → Damage
- [ ] HP decreases correctly
- [ ] 0 HP → Defeat

### Death Scenarios
- [ ] Missing RealAttack deflect → Death panel shows "Trickster Slash"
- [ ] Missing Counter deflect → Death panel shows "Trickster Counter"
- [ ] Deflecting FakeAttack → No effect (it's an illusion)

### Telegraph Verification
- [ ] Blue shimmer ONLY on FakeAttack
- [ ] White flash on RealAttack and Counter
- [ ] High chime during Stagger (strike window)

---

## Gate 9 Acceptance Criteria

From PROJECT_PLAN.md:

> **Gate 9:** 10 Tanuki clears, explainable deaths

Every death must be one of:
- "I attacked when it was disguised" (Counter)
- "I tried to deflect an illusion and got hit by the real attack"
- "I missed the deflect timing on the real attack"

No deaths should be "I don't know what happened" or "The blue thing killed me."

---

## Implementation Order

1. Create scene with arena and lighting
2. Place Player prefab
3. Create Tanuki prefab with disguise models
4. Create attack ScriptableObjects
5. Implement FakeAttack blue shimmer emission
6. Add TanukiEncounter with both HitDetectors
7. Add HP UI display
8. Wire Player attack → Boss damage
9. Test full 3-HP combat loop
10. Verify telegraph semantics
