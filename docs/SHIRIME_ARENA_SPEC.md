# Shirime Arena Specification

## Overview

Shirime is the **first playable boss** in the vertical slice. This yokai teaches **positioning** — it punishes frontal attacks and rewards patience.

**Scene Path:** `Assets/Game/Scenes/ShirimeArena.unity`

---

## Boss Design Summary

### Shirime (尻目)
*"The eye that watches from behind"*

A yokai that appears as a man who drops his pants to reveal a giant eye where his rear should be. Absurd, but deadly serious about combat semantics.

### Core Lesson
**Do not attack recklessly.** Wait for the right moment.

### Behavior Loop
```
Bow (intro) → Wait → EyeBeam OR Punish → Wait → ...
                ↑                              |
                └──────────────────────────────┘
```

| State | Duration | Trigger |
|-------|----------|---------|
| Bow | 2.0s | Encounter start |
| Wait | 1.0-3.0s (random) | After attack or stagger |
| EyeBeam | Attack duration | Player didn't attack during Wait |
| Punish | Attack duration | Player attacked during Wait |
| Staggered | Via deflect | Successful deflect |
| Defeated | Terminal | Perfect deflect while staggered |

---

## Scene Hierarchy

```
ShirimeArena (scene root)
├── --- ENVIRONMENT ---
├── Arena
│   ├── Floor
│   ├── Walls (invisible boundaries)
│   └── Decorations (optional)
├── Lighting
│   ├── Directional Light
│   └── Ambient Settings
├── --- GAMEPLAY ---
├── Player (prefab instance)
├── Shirime (boss prefab)
├── ShirimeEncounter (controller)
├── --- CAMERA ---
├── Main Camera
│   └── Cinemachine (optional)
├── --- UI ---
└── Canvas
    ├── DeathPanel
    └── VictoryPanel
```

---

## Arena Layout (Graybox)

### Dimensions
| Property | Value | Notes |
|----------|-------|-------|
| Shape | Circular | Intimate, focused |
| Diameter | 20 units | ~10m real-world |
| Floor Height | Y = 0 | Flat, no elevation |
| Wall Height | 3 units | Invisible colliders |

### Spawn Points
| Entity | Position | Rotation |
|--------|----------|----------|
| Player | (0, 0, -7) | (0, 0, 0) facing +Z |
| Shirime | (0, 0, 5) | (0, 180, 0) facing -Z |

### Floor GameObject
| Property | Value |
|----------|-------|
| Mesh | Cylinder (flattened) or Plane |
| Scale | (20, 0.1, 20) |
| Material | Graybox floor (dark gray) |
| Collider | MeshCollider or BoxCollider |
| Layer | Default |

### Wall Boundaries
Invisible colliders to keep player in arena:

| Property | Value |
|----------|-------|
| Shape | 4 BoxColliders forming square, or CylinderCollider |
| Height | 3 units |
| Material | None (invisible) |
| Layer | Default |

---

## Shirime Boss Prefab

**Path:** `Assets/Game/Prefabs/Bosses/Shirime.prefab`

### Hierarchy
```
Shirime (root)
├── Model (visual)
├── HitBox (receives player attacks)
└── AttackOrigin (spawns attack hitboxes)
```

### Root Components

#### Transform
| Property | Value |
|----------|-------|
| Position | (0, 0, 5) in scene |
| Rotation | (0, 180, 0) facing player |
| Scale | (1, 1, 1) |

#### ShirimeBoss Script
| Property | Value | Notes |
|----------|-------|-------|
| Eye Beam Attack | Ref to EyeBeam.asset | See Attack Definitions |
| Punish Attack | Ref to Punish.asset | See Attack Definitions |
| Bow Duration | 2.0 | Intro animation time |
| Wait Min Duration | 1.0 | Minimum wait time |
| Wait Max Duration | 3.0 | Maximum wait time |
| Stagger Duration | 1.0 | Overridden by deflect system |

#### AttackRunner Script
Added automatically by ShirimeBoss if missing.

#### HitDetector Script
| Property | Value |
|----------|-------|
| Target Layers | Player layer (8) |
| Debug Draw | true (for development) |

### Tag & Layer
| Property | Value |
|----------|-------|
| Tag | `Boss` |
| Layer | `Boss` (9) |

### Model (Child)
Placeholder for graybox:

| Property | Value |
|----------|-------|
| Mesh | Capsule |
| Scale | (1.5, 2, 1.5) |
| Material | Red/orange tint |

### HitBox (Child)
For receiving player attacks:

| Property | Value |
|----------|-------|
| Collider | CapsuleCollider (trigger) |
| Center | (0, 1, 0) |
| Radius | 0.75 |
| Height | 2.0 |
| Tag | `Boss` |
| Layer | `Boss` |

---

## Attack Definitions

Create these ScriptableObjects in `Assets/Game/ScriptableObjects/Attacks/Shirime/`

### EyeBeam.asset

The primary attack. Fires when player waits patiently.

| Property | Value | Notes |
|----------|-------|-------|
| Attack Id | `shirime_eyebeam` | |
| Display Name | `Eye Beam` | Shown on death panel |
| **Timing** | | |
| Startup Frames | 30 | 0.5s windup |
| Active Frames | 10 | 0.167s danger |
| Recovery Frames | 20 | 0.333s cooldown |
| **Telegraph** | | |
| Telegraph | PerfectDeflectWindow | White flash |
| Telegraph Lead Frames | 5 | Flash 5 frames before hit |
| **Damage** | | |
| Damage | 1 | One-shot kill |
| Unblockable | false | Can be deflected |
| Correct Response | Deflect | |
| **Hitbox** | | |
| Hitbox Offset | (0, 1, 2) | In front of boss |
| Hitbox Size | (3, 2, 4) | Wide beam |

**Total Duration:** 1.0s (60 frames)

### Punish.asset

Counter-attack when player strikes during Wait.

| Property | Value | Notes |
|----------|-------|-------|
| Attack Id | `shirime_punish` | |
| Display Name | `Punish` | Shown on death panel |
| **Timing** | | |
| Startup Frames | 15 | 0.25s fast counter |
| Active Frames | 8 | 0.133s |
| Recovery Frames | 25 | 0.417s |
| **Telegraph** | | |
| Telegraph | PerfectDeflectWindow | White flash |
| Telegraph Lead Frames | 3 | Shorter warning |
| **Damage** | | |
| Damage | 1 | One-shot kill |
| Unblockable | false | Can be deflected |
| Correct Response | Deflect | |
| **Hitbox** | | |
| Hitbox Offset | (0, 1, 1.5) | Closer range |
| Hitbox Size | (2, 2, 3) | Narrower |

**Total Duration:** 0.8s (48 frames)

---

## ShirimeEncounter Controller

**Path:** `Assets/Game/Prefabs/Encounters/ShirimeEncounter.prefab` (or in scene)

### Component: ShirimeEncounter

| Property | Reference To |
|----------|--------------|
| Boss | Shirime GameObject |
| Player | Player GameObject |
| Deflect System | Player's DeflectSystem component |
| Death Feedback | Player's DeathFeedbackSystem component |
| Boss Hit Detector | Shirime's HitDetector component |

### Wiring Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     ShirimeEncounter                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Player.OnActionExecuted ──────┬──► If Strike: Boss.NotifyPlayerAttacked()
│                                └──► If Deflect: DeflectSystem.StartDeflect()
│                                                                 │
│  BossHitDetector.OnHit ────────────► DeflectSystem.TryDeflect()
│                                           │                     │
│                              ┌────────────┴────────────┐        │
│                              ▼                         ▼        │
│                         Perfect/Standard            Miss        │
│                              │                         │        │
│                              ▼                         ▼        │
│                    Boss.ApplyStagger()    DeathFeedback.TriggerDeath()
│                              │                    Player.Die()  │
│                              ▼                                  │
│                    If Boss.CanBeDefeated ───► Boss.Defeat()     │
│                                                                 │
│  Boss.OnDefeated ──────────────────────────► Victory!           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Camera Setup

### Main Camera
| Property | Value |
|----------|-------|
| Position | (0, 8, -12) |
| Rotation | (30, 0, 0) |
| Projection | Perspective |
| FOV | 60 |
| Clear Flags | Solid Color |
| Background | Dark gray (#1a1a1a) |

### Framing
Camera should capture:
- Full arena floor
- Both player and boss at all times
- Slight top-down angle for spatial clarity

### Optional: Cinemachine
For polish, add:
- CinemachineVirtualCamera
- Follow: Player transform
- LookAt: Midpoint between player and boss
- Body: Framing Transposer
- Aim: Composer

---

## Lighting

### Directional Light
| Property | Value |
|----------|-------|
| Rotation | (50, -30, 0) |
| Color | Warm white (#FFF5E6) |
| Intensity | 1.0 |
| Shadow Type | Soft Shadows |

### Ambient
| Property | Value |
|----------|-------|
| Source | Color |
| Ambient Color | Dark purple (#1a0a1a) |
| Ambient Intensity | 0.3 |

### Atmosphere
Dark, intimate. Player should feel enclosed with the yokai.

---

## UI Requirements

### DeathPanel

Displays on player death. Managed by DeathFeedbackSystem.

| Element | Content |
|---------|---------|
| Attack Name | `_lastDeath.AttackName` ("Eye Beam" or "Punish") |
| Response Icon | Icon for `_lastDeath.CorrectResponse` (Deflect icon) |
| Retry Prompt | "Press any button to retry" |

### VictoryPanel

Displays on boss defeat.

| Element | Content |
|---------|---------|
| Text | "SHIRIME DEFEATED" |
| Subtext | "You have learned patience." |
| Continue Prompt | "Press any button to continue" |

---

## Layer & Tag Setup

Ensure these exist in Project Settings:

### Tags
- `Player`
- `Boss`

### Layers
| Layer | Name |
|-------|------|
| 8 | Player |
| 9 | Boss |
| 10 | BossAttack |
| 11 | PlayerAttack |

### Physics Matrix
| | Player | Boss | BossAttack |
|---|--------|------|------------|
| Player | - | - | **YES** |
| Boss | - | - | - |
| BossAttack | **YES** | - | - |

---

## Victory Condition

Shirime is defeated when:
1. Player successfully deflects an attack (Perfect or Standard)
2. Boss enters Staggered state
3. `Boss.CanBeDefeated` returns true (boss is staggered)
4. Encounter calls `Boss.Defeat()`

**Note:** Unlike multi-HP bosses, Shirime is defeated on the first successful stagger. This teaches that patience + perfect timing = victory.

---

## Testing Checklist

### Setup Verification
- [ ] Scene loads without errors
- [ ] Player spawns at correct position
- [ ] Boss spawns at correct position, facing player
- [ ] Camera frames both entities

### Input Verification
- [ ] WASD moves player
- [ ] Deflect input triggers DeflectSystem
- [ ] Strike input triggers NotifyPlayerAttacked

### Combat Flow
- [ ] Boss starts in Bow state
- [ ] Boss transitions to Wait after bow
- [ ] Attacking during Wait triggers Punish
- [ ] Not attacking during Wait triggers EyeBeam
- [ ] White flash appears before attacks hit
- [ ] Successful deflect staggers boss
- [ ] Perfect deflect during stagger defeats boss

### Death Flow
- [ ] Missing deflect triggers death
- [ ] Screen freezes briefly
- [ ] Death panel shows attack name
- [ ] Death panel shows correct response icon
- [ ] Retry resets encounter

### Victory Flow
- [ ] Boss defeat triggers Victory panel
- [ ] "SHIRIME DEFEATED" displays

---

## Gate 8 Acceptance Criteria

From PROJECT_PLAN.md:

> **Gate 8:** 10 Shirime clears, 0 unclear deaths

Every death must be explainable:
- "I attacked when I shouldn't have" (Punish)
- "I missed the deflect timing" (EyeBeam)

If a player dies and cannot explain why, the telegraph system has failed.

---

## Implementation Order

1. Create scene, add floor and walls
2. Add lighting and camera
3. Place Player prefab
4. Create Shirime prefab with components
5. Create attack ScriptableObjects
6. Add ShirimeEncounter, wire references
7. Create UI panels
8. Test full loop
9. Iterate on timing/feel
