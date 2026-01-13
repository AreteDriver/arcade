# EVE Rebellion: Python → Rust Porting Priority

Features from EVE_Rebellion (Python/Pygame) to port to eve_rebellion_rust (Rust/Bevy).

## Priority 1: Ammo Type System
**Effort:** Low (~150-200 LOC) | **Value:** High | **Risk:** None

| Aspect | Details |
|--------|---------|
| What | 5 ammo types with shield/armor damage multipliers |
| Why first | Foundation for tactical depth, damage pipeline already exists |
| Dependencies | None - DamageType enum and ProjectileDamage already in Rust |
| Key files | `src/entities/projectile.rs`, `src/core/events.rs` |

**Tasks:**
- [ ] Add `AmmoType` enum (Sabot, EMP, Plasma, Fusion, Barrage)
- [ ] Create damage multiplier table (shield_mult, armor_mult, fire_rate)
- [ ] Add ammo switching input (D-pad or number keys)
- [ ] Update HUD to show current ammo type
- [ ] Color projectiles by ammo type

---

## Priority 2: Leaderboard + Achievements
**Effort:** Low-Medium (~530-600 LOC) | **Value:** Medium | **Risk:** Low

| Aspect | Details |
|--------|---------|
| What | Top 10 persistent scores, 30 achievements |
| Why second | Polish feature, low risk, SaveData already exists |
| Dependencies | SaveData extension only |
| Key files | `src/core/save.rs`, `src/ui/menu.rs` |

**Tasks:**
- [ ] Extend `SaveData` with `unlocked_achievements: HashSet<String>`
- [ ] Define achievement enum with unlock conditions
- [ ] Add achievement check on run completion
- [ ] Create achievement popup notification (egui)
- [ ] Add achievements list screen to menu

---

## Priority 3: Triglavian Faction
**Effort:** Medium (~380-450 LOC) | **Value:** High | **Risk:** Medium

| Aspect | Details |
|--------|---------|
| What | 5 Triglavian ships with disintegrator ramping mechanic |
| Why third | Prerequisite for Abyssal Depths, isolated implementation |
| Dependencies | Enemy AI system (exists) |
| Key files | `src/entities/enemy.rs`, `src/systems/combat.rs` |

**Novel mechanic - Disintegrator ramping:**
```
damage = base * (1.0 + (ramp_max - 1.0) * min(time_on_target / ramp_time, 1.0))
```

**Tasks:**
- [ ] Add `DisintegratorRamp` component (target, time_on_target, ramp_max)
- [ ] Implement ramping damage calculation in combat system
- [ ] Add 5 Triglavian enemy variants to roster
- [ ] Visual: beam intensity scales with ramp
- [ ] Audio: pitch rises with damage ramp
- [ ] Reset ramp on target switch

---

## Priority 4: Refugee Economy + Upgrades
**Effort:** Medium-High (~500-700 LOC) | **Value:** High | **Risk:** Medium

| Aspect | Details |
|--------|---------|
| What | Collect refugees from kills → spend on 8 ship upgrades |
| Why fourth | Major progression loop, multiple system hooks |
| Dependencies | Kill events, SaveData, UI menu |
| Key files | `src/core/save.rs`, `src/systems/scoring.rs`, new `src/ui/upgrades.rs` |

**Tasks:**
- [ ] Add `ResourcePool` resource (skill_points, refugees)
- [ ] Extend `SaveData` with upgrade_state, total_refugees
- [ ] Hook refugee generation into transport kill events
- [ ] Define 8 upgrades with costs (gyro, armor, ammo unlocks, etc.)
- [ ] Create upgrade shop UI (egui)
- [ ] Apply upgrade stat modifiers to player ship
- [ ] T2 ship unlock prerequisites

---

## Priority 5: Abyssal Depths Mode
**Effort:** Very High (~1050-1200 LOC) | **Value:** Very High | **Risk:** High

| Aspect | Details |
|--------|---------|
| What | Triglavian roguelike: 3 rooms, timer, hazards, extraction |
| Why last | Uses all previous systems, largest scope |
| Dependencies | Triglavian faction, economy (optional), campaign system |
| Key files | New `src/modes/abyssal.rs`, `src/systems/hazards.rs` |

**New systems required:**
1. **Abyssal State Machine** - room progression, timer, extraction gate
2. **Environmental Hazards** - 3 types (deviant_automata, tachyon_cloud, ephialtes_cloud)
3. **Extraction Gate** - 2-second channel, interruptible
4. **Timer HUD** - countdown with critical warning at 30s

**Tasks:**
- [ ] Create `AbyssalRunState` (current_room, timer, extraction_progress)
- [ ] Implement room-based wave spawning
- [ ] Add 5-minute timer with game-over on expiry
- [ ] Create `AbyssalHazard` component with AOE damage pulses
- [ ] Implement extraction gate entity and channel mechanic
- [ ] Add tier/filament selection (5 tiers)
- [ ] Abyssal-specific HUD overlays
- [ ] Integration with Triglavian enemies

---

## Estimated Total

| Metric | Value |
|--------|-------|
| Total LOC | 2,610 - 3,150 |
| Python reference | 2,553 LOC |
| Systems touched | 8-10 |
| New files | 3-5 |

## Reference

Python source: `/home/arete/projects/EVE_Rebellion/`
- `constants.py` - Ammo types, upgrade costs
- `high_scores.py` - Leaderboard + achievements
- `abyssal_mode.py` - Abyssal Depths implementation
- `upgrade_screen.py` - Economy UI
