# Oni Arena Specification

## Overview

Oni is the **third and final boss** in the vertical slice. This yokai is the **ultimate combat validation** — a multi-phase fight that tests all skills learned from Shirime and Tanuki.

**Scene Path:** `Assets/Game/Scenes/OniArena.unity`

---

## Boss Design Summary

### Oni (鬼)
*"The demon who respects strength"*

A towering red demon wielding a massive iron club. Unlike the teaching bosses, Oni is a pure combat challenge. No tricks, no gimmicks — just honest, brutal combat across three escalating phases.

### Core Lesson
**Everything you've learned, applied at once.** Timing, patience, observation, aggression — all tested.

### Key Invariant
From PROJECT_PLAN.md:
> *"Pure combat validation"*

Oni follows all semantic rules perfectly. No visual deception, no special mechanics. If a player fails here, they haven't mastered the fundamentals.

### Behavior Loop (Per Phase)
```
Phase 1 (Heavy):    Idle → HeavyWindup → HeavyStrike → Idle → ...
Phase 2 (Counter):  Idle → CounterStance OR HeavyWindup → ...
Phase 3 (Barehand): Idle → ComboWindup → ComboChain(x3) → Idle → ...
```

| State | Duration | Trigger |
|-------|----------|---------|
| Intro | 1.5s | Encounter start |
| Idle | 1.0s | After attack completes |
| HeavyWindup | Attack startup | Phase 1 always, Phase 2 50% |
| HeavyStrike | Attack active | After HeavyWindup |
| CounterStance | 2.0s | Phase 2 only, 50% |
| CounterStrike | Attack duration | Player attacked during CounterStance |
| ComboWindup | Attack startup | Phase 3 combo start |
| ComboChain | Attack duration | Combo hits 1-3 |
| Staggered | Via deflect | Successful deflect |
| Defeated | Terminal | Phase 3 HP reaches 0 |

### Health System (Multi-Phase)
| Phase | HP | Attack Pattern |
|-------|-----|----------------|
| Phase 1: Heavy | 2 HP | Heavy strikes only |
| Phase 2: Counter | 2 HP | Counter stance + heavy strikes |
| Phase 3: Barehand | 3 HP | 3-hit combos |

**Total HP:** 7 (across all phases)

When a phase's HP reaches 0, Oni advances to the next phase instead of being defeated.

---

## Scene Hierarchy

```
OniArena (scene root)
├── --- ENVIRONMENT ---
├── Arena
│   ├── Floor
│   ├── Walls
│   └── Pillars (destroyed during fight - optional VFX)
├── Lighting
│   ├── Directional Light
│   └── Point Lights (red accent)
├── --- GAMEPLAY ---
├── Player (prefab instance)
├── Oni (boss prefab)
├── OniEncounter (controller)
├── --- CAMERA ---
├── Main Camera
├── --- UI ---
└── Canvas
    ├── PhaseDisplay
    ├── HealthDisplay (per phase)
    ├── DeathPanel
    └── VictoryPanel
```

---

## Arena Layout

### Dimensions
| Property | Value | Notes |
|----------|-------|-------|
| Shape | Square | Wide open, no hiding |
| Size | 30 x 30 units | Largest arena |
| Floor Height | Y = 0 | Flat |
| Wall Height | 5 units | High walls, oppressive |

### Theme: Empty Dojo
A stark, minimalist fighting arena. No decorations, no distractions. Just floor, walls, and the demon.

**Visual Elements:**
- Dark wooden floor (blood-stained optional)
- Red paper lanterns at corners (dim)
- Torn banners on walls
- Scorch marks on floor

### Spawn Points
| Entity | Position | Rotation |
|--------|----------|----------|
| Player | (0, 0, -12) | (0, 0, 0) facing +Z |
| Oni | (0, 0, 10) | (0, 180, 0) facing -Z |

### Floor
| Property | Value |
|----------|-------|
| Mesh | Plane or custom |
| Scale | (30, 1, 30) |
| Material | Dark wood texture |
| Collider | BoxCollider |

---

## Oni Boss Prefab

**Path:** `Assets/Game/Prefabs/Bosses/Oni.prefab`

### Hierarchy
```
Oni (root)
├── Model
│   ├── Body (main mesh)
│   ├── Club (weapon - Phase 1 & 2)
│   └── Hands (barehand visuals - Phase 3)
├── HitBox
└── AttackOrigin
```

### Root Components

#### OniBoss Script
| Property | Value | Notes |
|----------|-------|-------|
| **Phase 1 - Heavy** | | |
| Heavy Strike | Ref to OniHeavyStrike.asset | Main attack |
| **Phase 2 - Counter** | | |
| Counter Strike | Ref to OniCounterStrike.asset | Punish attack |
| Counter Stance Duration | 2.0 | Seconds in stance |
| **Phase 3 - Barehand** | | |
| Combo Hit 1 | Ref to OniComboHit1.asset | First hit |
| Combo Hit 2 | Ref to OniComboHit2.asset | Second hit |
| Combo Hit 3 | Ref to OniComboHit3.asset | Third hit (delayed) |
| **Health** | | |
| Phase 1 Health | 2 | Heavy phase HP |
| Phase 2 Health | 2 | Counter phase HP |
| Phase 3 Health | 3 | Barehand phase HP |
| **Timing** | | |
| Idle Duration | 1.0 | Pause between attacks |

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

---

## Attack Definitions

Create in `Assets/Game/ScriptableObjects/Attacks/Oni/`

### OniHeavyStrike.asset (Phase 1 & 2)

Massive overhead club slam. Slow but devastating.

| Property | Value | Notes |
|----------|-------|-------|
| Attack Id | `oni_heavy_strike` | |
| Display Name | `Crushing Blow` | Shown on death |
| **Timing** | | |
| Startup Frames | 45 | 0.75s (slow, readable) |
| Active Frames | 12 | 0.2s |
| Recovery Frames | 35 | 0.583s (punishable) |
| **Telegraph** | | |
| Telegraph | PerfectDeflectWindow | White flash |
| Telegraph Lead Frames | 8 | Longer warning |
| **Damage** | | |
| Damage | 1 | |
| Unblockable | false | |
| Correct Response | Deflect | |
| **Hitbox** | | |
| Hitbox Offset | (0, 0, 3) | Forward slam |
| Hitbox Size | (5, 4, 5) | Wide impact |

### OniCounterStrike.asset (Phase 2)

Fast counter when player attacks during CounterStance.

| Property | Value | Notes |
|----------|-------|-------|
| Attack Id | `oni_counter_strike` | |
| Display Name | `Demon Counter` | Shown on death |
| **Timing** | | |
| Startup Frames | 10 | 0.167s (very fast!) |
| Active Frames | 6 | 0.1s |
| Recovery Frames | 20 | 0.333s |
| **Telegraph** | | |
| Telegraph | PerfectDeflectWindow | White flash |
| Telegraph Lead Frames | 2 | Minimal warning |
| **Damage** | | |
| Damage | 1 | |
| Unblockable | false | |
| Correct Response | Deflect | |
| **Hitbox** | | |
| Hitbox Offset | (0, 1, 2) | |
| Hitbox Size | (4, 3, 4) | |

### OniComboHit1.asset (Phase 3)

First hit of barehand combo.

| Property | Value | Notes |
|----------|-------|-------|
| Attack Id | `oni_combo_1` | |
| Display Name | `Demon Fist I` | Shown on death |
| **Timing** | | |
| Startup Frames | 20 | 0.333s |
| Active Frames | 5 | 0.083s |
| Recovery Frames | 8 | 0.133s (chains fast) |
| **Telegraph** | | |
| Telegraph | PerfectDeflectWindow | White flash |
| Telegraph Lead Frames | 4 | |
| **Damage** | | |
| Damage | 1 | |
| Unblockable | false | |
| Correct Response | Deflect | |
| **Hitbox** | | |
| Hitbox Offset | (0, 1.5, 2) | |
| Hitbox Size | (3, 2, 3) | |

### OniComboHit2.asset (Phase 3)

Second hit, faster than first.

| Property | Value | Notes |
|----------|-------|-------|
| Attack Id | `oni_combo_2` | |
| Display Name | `Demon Fist II` | Shown on death |
| **Timing** | | |
| Startup Frames | 15 | 0.25s |
| Active Frames | 5 | 0.083s |
| Recovery Frames | 8 | 0.133s |
| **Telegraph** | | |
| Telegraph | PerfectDeflectWindow | White flash |
| Telegraph Lead Frames | 3 | |
| **Damage** | | |
| Damage | 1 | |
| Unblockable | false | |
| Correct Response | Deflect | |
| **Hitbox** | | |
| Hitbox Offset | (1, 1.5, 2) | Offset right |
| Hitbox Size | (3, 2, 3) | |

### OniComboHit3.asset (Phase 3)

Third hit, delayed for rhythm break.

| Property | Value | Notes |
|----------|-------|-------|
| Attack Id | `oni_combo_3` | |
| Display Name | `Demon Fist III` | Shown on death |
| **Timing** | | |
| Startup Frames | 30 | 0.5s (DELAYED!) |
| Active Frames | 8 | 0.133s |
| Recovery Frames | 25 | 0.417s |
| **Telegraph** | | |
| Telegraph | PerfectDeflectWindow | White flash |
| Telegraph Lead Frames | 5 | |
| **Damage** | | |
| Damage | 1 | |
| Unblockable | false | |
| Correct Response | Deflect | |
| **Hitbox** | | |
| Hitbox Offset | (0, 2, 2.5) | |
| Hitbox Size | (4, 3, 4) | Larger finisher |

**Combo Rhythm:** Fast → Fast → SLOW

This rhythm break tests if players can read telegraphs vs. pattern-memorize.

---

## Phase Breakdown

### Phase 1: Heavy (2 HP)

**Lesson Tested:** Timing (from Shirime)

- Only uses HeavyStrike
- Long windups, clear telegraphs
- Players who learned deflect timing from Shirime will succeed
- 2 successful deflect → attack cycles to clear

**Transition:** When HP reaches 0, Oni throws away club, enters Phase 2

### Phase 2: Counter (2 HP)

**Lesson Tested:** Patience (from Shirime)

- 50% chance: CounterStance (punishes aggression)
- 50% chance: HeavyStrike (same as Phase 1)
- CounterStance glows red (Hazard telegraph)
- If player attacks during CounterStance → instant CounterStrike

**Transition:** When HP reaches 0, Oni discards club entirely, enters Phase 3

### Phase 3: Barehand (3 HP)

**Lesson Tested:** Observation (from Tanuki)

- 3-hit combo chains
- Hits 1 & 2 are fast (predictable rhythm)
- Hit 3 is DELAYED (rhythm break)
- Players who learned to watch telegraphs vs. patterns will succeed
- 3 successful deflect → attack cycles to clear

---

## OniEncounter Controller

### Component: OniEncounter

| Property | Reference To |
|----------|--------------|
| Boss | Oni GameObject |
| Player | Player GameObject |
| Deflect System | Player's DeflectSystem |
| Death Feedback | Player's DeathFeedbackSystem |
| Boss Hit Detector | Oni's HitDetector |
| Player Hit Detector | Player's attack HitDetector |

### Wiring Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                       OniEncounter                              │
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
│                          ┌────────────┴────────────┐            │
│                          ▼                         ▼            │
│                    HP > 0                      HP == 0          │
│                          │                         │            │
│                          ▼                         ▼            │
│                   TransitionIdle        If Phase 3: Defeat()    │
│                                         Else: AdvancePhase()    │
│                                                                 │
│  Boss.OnPhaseChanged ─────────────────────► Update UI           │
│  Boss.OnDefeated ─────────────────────────► Victory!            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## CounterStance System

### Visual Indicator
When Oni enters CounterStance:
- Emit `TelegraphSemantic.Hazard` (red glow)
- Stance animation (raised guard)
- Lasts 2 seconds or until player attacks

### Behavior
| Scenario | Result |
|----------|--------|
| Player attacks during CounterStance | Instant CounterStrike |
| Player waits out CounterStance | Return to Idle safely |
| Player deflects CounterStrike | Stagger (standard flow) |

### Teaching
This tests Shirime's lesson: **patience over aggression**. Players who learned not to attack recklessly will recognize the red glow and wait.

---

## Camera Setup

### Main Camera
| Property | Value |
|----------|-------|
| Position | (0, 12, -18) |
| Rotation | (30, 0, 0) |
| Projection | Perspective |
| FOV | 50 |
| Clear Flags | Solid Color |
| Background | Dark red-black (#1a0a0a) |

### Framing
Wider than previous arenas due to:
- Larger arena size
- Oni's size and attack reach
- Need to see full combo animations

---

## Lighting

### Directional Light
| Property | Value |
|----------|-------|
| Rotation | (60, -30, 0) |
| Color | Pale red-white (#FFE8E8) |
| Intensity | 0.8 |
| Shadow Type | Soft Shadows |

### Point Lights (Corners)
4 red point lights at arena corners.

| Property | Value |
|----------|-------|
| Color | Blood red (#FF2200) |
| Intensity | 0.4 |
| Range | 15 |

### Ambient
| Property | Value |
|----------|-------|
| Source | Color |
| Ambient Color | Deep red (#1a0505) |
| Ambient Intensity | 0.2 |

### Atmosphere
Oppressive, intimate, final. The red lighting builds tension.

---

## UI Requirements

### Phase Display

Shows current phase with visual indicator.

| Position | Top center, above health |
|----------|--------------------------|
| Style | Phase name + icon |
| Update | On OnPhaseChanged |

```
    Phase 1: HEAVY
    ████████░░  (2/2 HP)

    Phase 2: COUNTER
    ████░░░░░░  (1/2 HP)

    Phase 3: BAREHAND
    ██████░░░░  (2/3 HP)
```

### Health Display

Per-phase health bar.

| Element | Description |
|---------|-------------|
| Position | Top center |
| Style | Segmented bar (HP pips) |
| Color | Phase-specific (gray/yellow/red) |
| Update | On TakeDamage() |

### DeathPanel

Same as previous bosses. Shows attack name and correct response.

### VictoryPanel

| Element | Content |
|---------|---------|
| Text | "ONI DEFEATED" |
| Subtext | "You have proven your mastery." |
| Secondary | "The demon acknowledges your strength." |

---

## Victory Condition

Oni is defeated when:
1. All three phases completed
2. Phase 3 HP reaches 0
3. Boss transitions to Defeated state

**Total requirement:** 7 successful stagger + attack cycles across all phases.

---

## Testing Checklist

### Setup Verification
- [ ] Scene loads without errors
- [ ] Player spawns correctly
- [ ] Oni spawns with Phase 1 active (2 HP)
- [ ] Phase/HP display shows correctly

### Phase 1 Testing
- [ ] Only HeavyStrike used
- [ ] Deflect → Stagger → Attack → Damage works
- [ ] 2 damage clears Phase 1
- [ ] Transition to Phase 2 triggers

### Phase 2 Testing
- [ ] CounterStance triggers ~50% of time
- [ ] Red glow appears during CounterStance
- [ ] Attacking during CounterStance triggers CounterStrike
- [ ] CounterStrike can be deflected
- [ ] HeavyStrike still used ~50%
- [ ] 2 damage clears Phase 2

### Phase 3 Testing
- [ ] 3-hit combo executes
- [ ] Combo rhythm is Fast → Fast → SLOW
- [ ] Each hit can be deflected individually
- [ ] 3 damage defeats Oni

### Death Scenarios
- [ ] Missing HeavyStrike → Death panel shows "Crushing Blow"
- [ ] Missing CounterStrike → Death panel shows "Demon Counter"
- [ ] Missing Combo Hit 1 → Death panel shows "Demon Fist I"
- [ ] Missing Combo Hit 2 → Death panel shows "Demon Fist II"
- [ ] Missing Combo Hit 3 → Death panel shows "Demon Fist III"

### Telegraph Verification
- [ ] White flash on ALL attacks
- [ ] Red glow ONLY during CounterStance
- [ ] No telegraph on Idle/Intro states

---

## Gate 10 Acceptance Criteria

From PROJECT_PLAN.md:

> **Gate 10:** 5 Oni clears, 0 semantic inconsistencies

Every death must follow established semantic rules:
- White flash = deflect window
- Red glow = do not attack
- All attacks can be deflected
- No mystery damage

If any player reports semantic confusion during Oni fight, the telegraph system has failed its final validation.

---

## Implementation Order

1. Create scene with arena (30x30, dark dojo theme)
2. Add lighting (dramatic red accents)
3. Place Player prefab
4. Create Oni prefab with all components
5. Create all 5 attack ScriptableObjects
6. Implement phase transition system
7. Add CounterStance with Hazard telegraph
8. Add OniEncounter controller
9. Add Phase/HP UI displays
10. Wire Player attack → Boss damage
11. Test all three phases
12. Verify all telegraphs

---

## Visual Polish (Optional)

### Phase Transitions
- Screen flash on phase change
- Oni roar animation
- Club discard animation (Phase 1 → 2)
- Sleeves torn off (Phase 2 → 3)

### Impact Effects
- Camera shake on HeavyStrike hit/block
- Floor crack particles on ComboHit3
- Red energy trails on barehand attacks

### Defeat Sequence
- Oni kneels
- Red energy dissipates
- Respectful bow to player
- Fade to victory screen
