# Player Prefab Specification

## Overview

The Player prefab is the playable character for Yokai Blade. It handles input, movement, combat actions (deflect, strike, dodge), and receives damage from boss attacks.

**Prefab Path:** `Assets/Game/Prefabs/Player.prefab`

---

## GameObject Hierarchy

```
Player (root)
├── Model (visual mesh)
├── HurtBox (receives damage)
└── AttackOrigin (spawns player attack hitboxes)
```

---

## Root GameObject: Player

### Transform
| Property | Value |
|----------|-------|
| Position | (0, 0, 0) |
| Rotation | (0, 0, 0) |
| Scale | (1, 1, 1) |

### Tag & Layer
| Property | Value |
|----------|-------|
| Tag | `Player` |
| Layer | `Player` (create if needed) |

---

## Required Components

### 1. CharacterController

Standard Unity CharacterController for movement.

| Property | Value | Notes |
|----------|-------|-------|
| Slope Limit | 45 | |
| Step Offset | 0.3 | |
| Skin Width | 0.08 | |
| Min Move Distance | 0.001 | |
| Center | (0, 1, 0) | Centered on character |
| Radius | 0.5 | |
| Height | 2.0 | |

### 2. PlayerInput (Unity Input System)

| Property | Value |
|----------|-------|
| Actions | `YokaiBlade` InputActionAsset (see below) |
| Default Map | `Gameplay` |
| Behavior | `Send Messages` or `Invoke Unity Events` |

### 3. PlayerInputHandler

Script: `YokaiBlade.Core.Input.PlayerInputHandler`

| Property | Value |
|----------|-------|
| Config | Reference to `InputConfig` ScriptableObject |

### 4. PlayerController

Script: `YokaiBlade.Core.Input.PlayerController`

| Property | Value | Notes |
|----------|-------|-------|
| Input Config | Reference to `InputConfig` | Same as PlayerInputHandler |
| Move Speed | 5.0 | Units per second |
| Log State Changes | true | Enable for debugging, disable for release |

### 5. DeflectSystem

Script: `YokaiBlade.Core.Combat.DeflectSystem`

| Property | Value | Notes |
|----------|-------|-------|
| Perfect Window | 0.05 | 3 frames at 60fps |
| Standard Window | 0.15 | 9 frames at 60fps |
| Perfect Meter Gain | 20 | |
| Standard Meter Gain | 5 | |
| Perfect Stagger Duration | 1.0 | Seconds boss is staggered |
| Standard Stagger Duration | 0.3 | |

### 6. DeathFeedbackSystem

Script: `YokaiBlade.Core.Combat.DeathFeedbackSystem`

| Property | Value | Notes |
|----------|-------|-------|
| Freeze Duration | 1.0 | Time freeze on death |
| Panel Display Duration | 2.0 | Death panel visibility |

### 7. Collider (HurtBox)

On child GameObject `HurtBox`:

| Property | Value |
|----------|-------|
| Type | CapsuleCollider |
| Is Trigger | true |
| Center | (0, 1, 0) |
| Radius | 0.5 |
| Height | 2.0 |
| Direction | Y-Axis |

---

## Child GameObjects

### Model

Placeholder for visual representation.

| Property | Value |
|----------|-------|
| Components | MeshFilter, MeshRenderer |
| Mesh | Capsule (placeholder) or character model |
| Material | Player material (create simple colored material) |

For graybox:
```
Capsule mesh, scale (1, 1, 1), white/blue material
```

### HurtBox

Receives damage from boss attacks.

| Property | Value |
|----------|-------|
| Tag | `Player` |
| Layer | `Player` |
| Components | CapsuleCollider (trigger) |

### AttackOrigin

Origin point for player attacks (strike).

| Property | Value |
|----------|-------|
| Position | (0, 1, 0.5) | Slightly in front |
| Components | None (transform only) |

---

## Input Action Asset

Create: `Assets/Game/ScriptableObjects/YokaiBlade.inputactions`

### Action Map: Gameplay

| Action | Type | Bindings |
|--------|------|----------|
| Move | Value (Vector2) | Left Stick, WASD |
| Deflect | Button | West Button (X/Square), Left Mouse |
| Strike | Button | South Button (A/Cross), Right Mouse |
| Dodge | Button | East Button (B/Circle), Space |

### Binding Details

**Move:**
```
Gamepad: <Gamepad>/leftStick
Keyboard: WASD composite
  Up: W
  Down: S
  Left: A
  Right: D
```

**Deflect:**
```
Gamepad: <Gamepad>/buttonWest
Keyboard: <Mouse>/leftButton
Alternative: <Keyboard>/leftShift
```

**Strike:**
```
Gamepad: <Gamepad>/buttonSouth
Keyboard: <Mouse>/rightButton
Alternative: <Keyboard>/j
```

**Dodge:**
```
Gamepad: <Gamepad>/buttonEast
Keyboard: <Keyboard>/space
```

---

## InputConfig ScriptableObject

Create: `Assets/Game/ScriptableObjects/InputConfig.asset`

Menu: `Create > YokaiBlade > Input Config`

| Property | Value |
|----------|-------|
| Deflect Buffer Window | 0.15 |
| Strike Buffer Window | 0.10 |
| Dodge Buffer Window | 0.10 |
| Perfect Deflect Window | 0.05 |
| Standard Deflect Window | 0.15 |
| Action Cooldown | 0.05 |

---

## Layer Setup

In Project Settings > Tags and Layers:

| Layer | Name | Purpose |
|-------|------|---------|
| 8 | Player | Player character |
| 9 | Boss | Boss characters |
| 10 | BossAttack | Boss attack hitboxes |
| 11 | PlayerAttack | Player attack hitboxes |

### Physics Matrix (Project Settings > Physics)

| | Player | Boss | BossAttack | PlayerAttack |
|---|--------|------|------------|--------------|
| Player | - | - | **YES** | - |
| Boss | - | - | - | **YES** |
| BossAttack | **YES** | - | - | - |
| PlayerAttack | - | **YES** | - | - |

---

## Wiring Checklist

Before the prefab is complete:

- [ ] Create `Player` tag
- [ ] Create `Player` layer (8)
- [ ] Create InputActionAsset with all bindings
- [ ] Create InputConfig ScriptableObject
- [ ] Assign InputConfig to both PlayerInputHandler and PlayerController
- [ ] Assign InputActionAsset to PlayerInput component
- [ ] Set HurtBox tag to `Player`
- [ ] Set HurtBox layer to `Player`

---

## Integration with Encounters

Encounters (e.g., `ShirimeEncounter`) expect these references:

```csharp
[SerializeField] private PlayerController _player;
[SerializeField] private DeflectSystem _deflectSystem;
[SerializeField] private DeathFeedbackSystem _deathFeedback;
```

All three components are on the Player root GameObject.

### Event Flow

```
PlayerInput → PlayerInputHandler → InputBuffer
                                      ↓
                              PlayerController
                                      ↓
                         OnActionExecuted event
                                      ↓
                              Encounter script
                                      ↓
                    DeflectSystem.StartDeflect()
                                      ↓
                    Boss attack hits HurtBox
                                      ↓
                    DeflectSystem.TryDeflect()
                                      ↓
                    Result: Perfect/Standard/Miss
```

---

## State Machine Reference

The `PlayerController` manages these states:

| State | Can Move | Can Deflect | Can Strike | Can Dodge |
|-------|----------|-------------|------------|-----------|
| Idle | Yes | Yes | Yes | Yes |
| Moving | Yes | Yes | Yes | Yes |
| Attacking | No | **Yes** | No | No |
| Deflecting | No | No | No | No |
| Dodging | No | No | No | No |
| Stunned | No | No | No | No |
| Recovering | Yes | Yes | Yes | Yes |
| Dead | No | No | No | No |

**Key Invariant:** Deflect can cancel Attack (priority rule).

---

## Testing the Prefab

1. Drop prefab into a test scene
2. Add a floor collider
3. Press Play
4. Verify:
   - WASD/stick moves character
   - Left click/X triggers deflect (check console log)
   - Right click/A triggers strike (check console log)
   - Space/B triggers dodge (check console log)
   - State transitions logged correctly

---

## Common Issues

### "No InputConfig assigned!"
Assign the InputConfig ScriptableObject to PlayerInputHandler.

### Character falls through floor
Ensure CharacterController is configured, not just Rigidbody.

### Inputs not registering
Check PlayerInput component has correct InputActionAsset assigned.
Check Action names match exactly: "Move", "Deflect", "Strike", "Dodge".

### Deflect not working in encounters
Ensure DeflectSystem is on Player root, not a child.
Ensure encounter has reference to DeflectSystem.
