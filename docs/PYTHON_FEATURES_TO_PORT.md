# Python Features to Port to Rust

Analysis of `/home/arete/projects/EVE_Rebellion/` (Python/Pygame) for features to integrate into the Rust/Bevy version.

---

## High Priority - Visual Effects

### 1. Rarity System for Powerups
**Python Location**: `sprites.py` lines 5115-5530

The Python version has a tiered rarity system with visual scaling:

| Rarity | Glow Mult | Orbitals | Pulse Speed |
|--------|-----------|----------|-------------|
| Common | 0.6 | 4 | 0.10 |
| Uncommon | 0.8 | 6 | 0.12 |
| Rare | 1.0 | 8 | 0.15 |
| Epic | 1.3 | 12 | 0.18 |

**Features**:
- Orbital particles circling the powerup (count scales with rarity)
- Pulsing glow effect (speed scales with rarity)
- Corona ring for epic items
- Energy arc tendrils for rare items

**Port to Rust**: Add `PowerupRarity` component, scale visual effects in render system.

---

### 2. Enhanced Damage Visuals
**Python Location**: `sprites.py` and `visual_effects.py`

Three-layer damage feedback matching EVE's Shield → Armor → Hull system:

| Layer | Effect | Color |
|-------|--------|-------|
| Shield | Hexagonal ripple outward | Blue/cyan |
| Armor | Spark burst + metal fragments | Orange/gold |
| Hull | Fire/smoke particles, structural cracks | Red/black |

**Features**:
- Shield impacts show hex-grid distortion
- Armor hits spray sparks in hit direction
- Hull damage shows persistent fire trails
- Screen shake on hull breaches

**Port to Rust**: Extend damage system with visual effect spawning per layer.

---

### 3. Background Ship Traffic
**Python Location**: `space_background.py`

Procedural side-profile ship silhouettes flying in background:

```
Minmatar (allies): Rust/orange, fly left→right
Amarr (enemies): Gold, fly right→left
```

**Ship Classes**:
- Frigates: 25px base, 50% spawn weight
- Cruisers: 45px base, 35% spawn weight
- Battleships: 70px base, 15% spawn weight

**Features**:
- Distance-based alpha (far = faint, close = visible)
- Engine glow with flicker animation
- Parallax movement (closer = faster)
- Max 8 ships on screen, spawn every 120 frames

**Port to Rust**: Add `BackgroundShip` entity with parallax layer, spawn system.

---

## Medium Priority - Polish

### 4. Powerup Pickup Effects
**Python Location**: `sprites.py` - `PowerupPickupEffect` class

Multi-phase pickup animation:
1. Flash (instant white burst)
2. Shockwave (expanding ring)
3. Particles (color-matched to powerup type)
4. Screen shake for rare/epic

**Port to Rust**: Add `PickupEffectBundle` spawned on powerup collection.

---

### 5. Buff Expiration Warnings
**Python Location**: `game.py` - HUD drawing

When active buff has <2 seconds remaining:
- Rapid pulse on HUD icon
- Red border flash
- Countdown text overlay
- Screen-edge glow in buff color

**Port to Rust**: Add timer check in buff system, trigger warning visual state.

---

### 6. Active Buff Visualization on Player
**Python Location**: `game.py` - `_draw_player_powerup_glow()`

| Buff | Visual Effect |
|------|---------------|
| Invulnerability | Golden hexagonal shield bubble |
| Overdrive | Speed lines trailing behind |
| Rapid Fire | Weapon barrel orange glow |
| Magnet | Blue tractor beam tendrils |

**Port to Rust**: Add buff-specific sprite overlays or shader effects.

---

## Low Priority - Controller

### 7. Steam Deck Controller Presets ✅ DONE
**Python Location**: `controller_input.py`

Auto-detection of Steam Deck with tuned settings:
- Back buttons (L4/R4/L5/R5) mapped
- Adjusted deadzones for Steam Deck sticks
- Quick-toggle for pause using Steam button

**Ported to Rust**: Added to `systems/joystick.rs`
- `ControllerProfile` resource with per-controller tuning
- Auto-detection via ioctl JSIOCGNAME (Steam Deck, Xbox, PlayStation)
- Steam Deck profile: tighter deadzones (0.12/0.15), responsive triggers
- `BackButtonConfig` with L4/L5/R4/R5 action mappings
- `BackButtonEvent` for game systems to handle back button presses

---

## Already in Rust (Skip)

These Python features already exist or are better in Rust:
- ✅ EVE ship sprites (Rust uses CCP image server)
- ✅ Campaign system (Rust has 3 modules)
- ✅ Abilities (Rust has 12 types)
- ✅ Save system (Rust has proper persistence)
- ✅ WASM support (Rust has web builds)
- ✅ Berserk system (Rust-only feature)

---

## Implementation Order

1. ~~**Background ship traffic**~~ ✅ DONE - Added to `ui/backgrounds.rs`
2. ~~**Rarity system**~~ ✅ DONE - Added to `entities/collectible.rs`
   - Common/Uncommon/Rare/Epic tiers
   - Size and glow scaling by rarity
   - Pulse animation speed varies by tier
   - Orbital particles for rare/epic items
   - Rotation effect for rare/epic
3. ~~**Damage visuals**~~ ✅ DONE - Added to `systems/effects.rs`
   - Shield: Blue expanding ripple rings with hex particles
   - Armor: Orange directional spark spray with gravity
   - Hull: Fire and smoke particles rising upward
   - Enhanced screen shake on hull damage
   - DamageLayerEvent tracks which layer absorbed damage
4. ~~**Pickup effects**~~ ✅ DONE - Added to `systems/effects.rs`
   - Phase 1: Instant flash (white -> color fade)
   - Phase 2: Expanding shockwave ring (ease-out curve)
   - Phase 3: Particle burst (color-matched, sparkle variation)
   - Intensity scales with rarity (size, count, duration)
   - Epic: Extra sparkle particles + screen shake + flash
   - Rare: Screen shake + colored flash
   - Uncommon: Light screen shake
5. ~~**Buff warnings**~~ ✅ DONE - Added to `ui/hud.rs`
   - Countdown text overlay when buff < 2 seconds remaining
   - Dramatic pulsing on HUD icon (8-20 Hz based on urgency)
   - Color transitions (orange to red flash)
   - Screen edge warning overlay (colored border pulses when expiring)
   - Timer bar color changes as buff depletes
6. ~~**Active buff visuals**~~ ✅ DONE - Added to `systems/effects.rs`
   - Invulnerability: Golden hexagonal shield bubble (pulsing, rotating)
   - Overdrive: Cyan speed lines trailing behind player
   - Damage Boost: Red orbiting aura particles spiraling inward
   - All effects follow player and despawn when buff expires

---

## Notes

- Python version will be deprecated after porting
- Rust version uses Bevy 0.15 ECS architecture
- All new features should follow existing Rust patterns in `src/`
