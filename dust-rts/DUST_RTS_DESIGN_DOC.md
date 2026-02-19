# DUST Orbital Command: RTS Design Document

## The Vision

A top-down real-time strategy game where corporate factions wage war for planetary control. Combined arms warfare — infantry squads, tanks, dropships, and orbital strikes — all visible on one battlefield. The DUST 514 fantasy realized as an RTS.

**The Pitch:**
> Command a mercenary corporation in planetary conquest. Deploy infantry squads, roll tanks across contested terrain, call dropships for rapid insertion, and rain orbital fire from ships in the sky above. Every asset costs ISK. Every loss hurts. Victory means territory, contracts, and the resources to fight the next war.

**Core Inspirations:**
- Company of Heroes (squad-based, cover, combined arms)
- Wargame: Red Dragon (deck building, no base building, deployment)
- Supreme Commander (scale, strategic zoom)
- DUST 514 / EVE (faction warfare, war economy, orbital strikes)
- Command & Conquer (superweapons, clear faction identity)

---

## Part 1: Core Design Pillars

### Pillar 1: Combined Arms That Matters

Every unit type has a role. No unit type dominates.

```
INFANTRY
  └── Takes and holds territory
  └── Operates in buildings, rough terrain
  └── Vulnerable in the open
  └── Cheap, replaceable, essential

VEHICLES
  └── Dominates open ground
  └── Cannot take capture points
  └── Vulnerable to infantry AT and air
  └── Expensive, powerful, limited

AIRCRAFT
  └── Rapid response, recon, strikes
  └── Vulnerable to AA
  └── Cannot hold ground
  └── High impact, high cost

ORBITAL
  └── Devastating strikes
  └── Requires ground control (uplinks)
  └── Long cooldowns
  └── War-winning potential
```

**The Triangle:**
- Infantry beats territory
- Vehicles beat infantry (in the open)
- Aircraft beats vehicles
- AA beats aircraft
- Infantry (with AT) beats vehicles (in cover)
- Orbital beats everything (but requires infantry to capture uplinks)

### Pillar 2: Territory Is Everything

The map is divided into sectors. Controlling sectors provides:
- **Resources** (to build more units)
- **Spawn points** (to reinforce closer to the front)
- **Uplink access** (to call orbital strikes)
- **Victory points** (to win the match)

```
MAP LAYOUT (Example)
┌─────────────────────────────────────────────┐
│  [YOUR BASE]                                │
│       │                                     │
│    [SECTOR A] ←── fuel depot               │
│       │                                     │
│    [SECTOR B] ←── uplink                   │
│       │                                     │
│ ══════╪══════════ front line ══════════════│
│       │                                     │
│    [SECTOR C] ←── uplink                   │
│       │                                     │
│    [SECTOR D] ←── fuel depot               │
│       │                                     │
│                              [ENEMY BASE]   │
└─────────────────────────────────────────────┘
```

Sectors are captured by infantry standing on control points. Vehicles cannot capture — they can only support infantry.

### Pillar 3: War Economy

Everything costs resources. Losses matter.

**Two Resources:**
- **NANITE PASTE (NP)** — For infantry, light vehicles. Regenerates slowly. Boosted by fuel depots.
- **ISK** — For heavy vehicles, aircraft, orbital strikes. Earned from territory control and kills.

**The Economy Loop:**
```
Control territory → Earn resources → Build units → 
Take more territory → Lose units → Need more resources → 
Control territory...
```

Turtling doesn't work. Aggression is rewarded. But reckless losses cripple your economy.

### Pillar 4: Orbital Integration

The sky is not empty. Ships orbit above, waiting for targeting data.

**Orbital Uplinks:**
- Scattered across the map (3-5 per map)
- Must be captured and held by infantry
- Once held, enables orbital strike requests
- Limited uses per match (3-5 strikes total)
- Strike power scales with how many uplinks you control

**Orbital Strike Types:**
| Strike | Effect | Cost | Cooldown |
|--------|--------|------|----------|
| Precision Strike | Small radius, high damage | Low ISK | 60 sec |
| Bombardment | Large radius, medium damage | Medium ISK | 120 sec |
| EMP Strike | Disables vehicles/turrets | Medium ISK | 90 sec |
| Orbital Laser | Line of devastation | High ISK | 180 sec |

**The Fantasy:** You fight tooth and nail to capture an uplink. Your infantry holds it against a counterattack. And then you call down the wrath of God on the enemy tank column pushing toward Sector C.

### Pillar 5: Faction Identity

Three factions with distinct aesthetics and playstyles:

**AMARR LOYALISTS**
- Aesthetic: Gold, religious iconography, laser weapons
- Playstyle: Durable, expensive, slow but powerful
- Strength: Armor, sustained damage
- Weakness: Mobility, early aggression

**CALDARI CORPORATE**
- Aesthetic: Grey/blue, corporate efficiency, missiles/railguns
- Playstyle: Balanced, versatile, good ranged
- Strength: Flexibility, ranged combat, shields
- Weakness: Close combat, raw power

**MINMATAR REPUBLIC**
- Aesthetic: Rust, salvaged tech, projectile weapons
- Playstyle: Fast, aggressive, hit-and-run
- Strength: Speed, flanking, guerrilla tactics
- Weakness: Durability, sustained engagements

(Gallente could be 4th faction later — drones, hybrid weapons, balanced)

---

## Part 2: Unit Roster

### Infantry Units

**INFANTRY SQUAD (All Factions)**
```
Cost: 100 NP
Squad Size: 4 soldiers
Health: Low (per soldier)
Damage: Low (rifles)
Role: Capture points, garrison buildings, basic combat

Abilities:
- Garrison: Enter buildings for cover bonus
- Capture: Take control points
- Throw Grenade: AoE damage, cooldown
```

**ASSAULT SQUAD**
```
Cost: 150 NP
Squad Size: 4 soldiers
Health: Medium
Damage: Medium (CQC weapons)
Role: Breaching, close combat, aggressive pushes

Abilities:
- Breach: Clear garrisoned building
- Sprint: Temporary speed boost
- Flashbang: Stun enemies briefly
```

**HEAVY WEAPONS SQUAD**
```
Cost: 200 NP
Squad Size: 3 soldiers
Health: Medium
Damage: High (HMG + AT launcher)
Role: Anti-vehicle, suppression, defensive

Abilities:
- Deploy: Set up HMG for increased damage/accuracy
- AT Rocket: Single high-damage shot vs vehicles
- Suppression: Reduces enemy accuracy in cone
```

**SNIPER TEAM**
```
Cost: 150 NP
Squad Size: 2 soldiers
Health: Low
Damage: Very High (single target)
Role: Recon, counter-infantry, officer sniping

Abilities:
- Camouflage: Invisible when stationary
- Called Shot: Bonus damage to specific target
- Spot: Reveals enemies for all units
```

**LOGISTICS SQUAD (Support)**
```
Cost: 175 NP
Squad Size: 3 soldiers
Health: Low
Damage: Low
Role: Healing, repairs, support

Abilities:
- Repair: Fix damaged vehicles
- Heal: Restore infantry health
- Resupply: Restore ability cooldowns
```

### Vehicle Units

**LIGHT ATTACK VEHICLE (LAV)**
```
Cost: 250 NP
Crew: 2 (driver + gunner)
Health: Medium
Damage: Medium (autocannon)
Role: Recon, infantry support, flanking

Abilities:
- High Speed: Fastest ground vehicle
- Scout: Reveals large area while moving
```

**ARMORED PERSONNEL CARRIER (APC)**
```
Cost: 300 NP
Crew: 2 + 6 passengers
Health: High
Damage: Low (light MG)
Role: Infantry transport, forward deployment

Abilities:
- Transport: Carry one infantry squad
- Spawn Point: Infantry can reinforce here
- Smoke: Obscures vision
```

**MAIN BATTLE TANK (MBT)**
```
Cost: 500 ISK
Crew: 3
Health: Very High
Damage: Very High (main cannon)
Role: Breakthrough, anti-vehicle, area denial

Abilities:
- Armor: Resistant to small arms
- Main Gun: Devastating to vehicles and structures
- Hull Down: Increased defense when stationary
```

**HEAVY ASSAULT VEHICLE (HAV)**
```
Cost: 700 ISK
Crew: 4
Health: Extreme
Damage: Extreme
Role: Siege, breakthrough, terror weapon

Abilities:
- Siege Mode: Increased range, immobile
- Multi-Turret: Engages multiple targets
- Inspire Fear: Nearby enemies have reduced morale
```

### Aircraft Units

**DROPSHIP**
```
Cost: 400 ISK
Crew: 2 + 12 passengers
Health: Medium
Damage: Low (door guns)
Role: Rapid deployment, extraction

Abilities:
- Transport: Carry up to 3 squads or 1 light vehicle
- Fast Insert: Deploy troops anywhere on map
- Extraction: Pick up units under fire
```

**GUNSHIP**
```
Cost: 600 ISK
Crew: 3
Health: Medium
Damage: Very High (rockets, cannon)
Role: Ground attack, anti-vehicle

Abilities:
- Strafe Run: High damage along a line
- Loiter: Circle area providing sustained fire
- Vulnerable: Must retreat after attack run
```

**FIGHTER**
```
Cost: 500 ISK
Crew: 1
Health: Low
Damage: High (vs air)
Role: Air superiority, intercept

Abilities:
- Intercept: Engage enemy aircraft
- Escort: Protect friendly aircraft
- Ground Attack: Limited anti-ground capability
```

### Defensive Structures

**GUN TURRET**
```
Cost: 200 NP
Health: Medium
Damage: Medium
Role: Point defense, area denial

- Auto-targets enemies in range
- Can be hacked/disabled by enemy infantry
- Destroyed by vehicles easily
```

**SHIELD GENERATOR**
```
Cost: 400 ISK
Health: High
Effect: Creates shield bubble

- Blocks projectiles (not units)
- Can be overloaded by sustained fire
- Infantry must destroy generator directly
```

**UPLINK STATION**
```
Cost: Map-placed (not buildable)
Health: Very High
Effect: Enables orbital strikes

- Must be captured and held
- Takes 30 seconds to capture
- Defended by auto-turrets initially
```

---

## Part 3: Game Modes

### Mode 1: Conquest (Primary)

**Objective:** Control the majority of sectors to drain enemy Victory Points.

**Rules:**
- Each team starts with 500 VP
- Control 3+ of 5 sectors = enemy loses 1 VP/second
- Control all 5 = enemy loses 3 VP/second
- First to 0 VP loses
- Match time: 20-30 minutes

**Why It Works:**
- Encourages constant fighting over territory
- Comeback potential (recapture sectors)
- Clear win condition
- Matches have natural pacing

### Mode 2: Assault

**Objective:** Attackers must capture 3 objectives in sequence. Defenders must hold until time runs out.

**Rules:**
- Attackers have unlimited reinforcements (but cost still matters)
- Defenders have limited reinforcements
- Each objective has time limit
- Capture extends time
- Final objective is the enemy HQ

**Why It Works:**
- Asymmetric gameplay
- Clear narrative (invasion)
- Different strategies for each side
- Climactic endings

### Mode 3: Skirmish (Quick Play)

**Objective:** Destroy the enemy HQ.

**Rules:**
- Both teams have an HQ structure
- HQ has massive health
- Destroying HQ wins instantly
- Alternative: VP drain from kills

**Why It Works:**
- Faster matches (10-15 min)
- Clear objective
- Good for learning

### Mode 4: Planetary Conquest (Campaign)

**Objective:** Control a planet through connected battles.

**Rules:**
- Planet divided into territories
- Each territory is one match
- Winning gives you the territory
- Bonuses for controlling adjacent territories
- Control 70% to win planet

**Why It Works:**
- Meta-progression
- Stakes beyond single match
- EVE-like territory warfare
- Reason to keep playing

---

## Part 4: Core Mechanics

### 4.1 Cover System

Cover is life for infantry.

**Cover Types:**
- **No Cover:** Full damage, default in open
- **Light Cover:** 25% damage reduction, bushes, fences
- **Heavy Cover:** 50% damage reduction, walls, craters
- **Garrison:** 75% damage reduction, inside buildings

**Cover Mechanics:**
- Infantry automatically use nearby cover
- Moving breaks cover temporarily
- Some weapons ignore cover (flamers, grenades)
- Vehicles provide moving cover for nearby infantry

```
COVER EXAMPLE
                    
  Enemy fire →→→→→→→→
                    ↓
              ┌─────────┐
              │ WALL    │ ← Heavy cover
              └─────────┘
                  ○○○○ ← Infantry behind wall
                         takes 50% less damage
```

### 4.2 Suppression System

Volume of fire matters, not just damage.

**How It Works:**
- Units under heavy fire become "suppressed"
- Suppressed units: -50% accuracy, -50% speed, won't advance
- Suppression decays when fire stops
- Some units resist suppression (vehicles, heroes)

**Tactical Implications:**
- LMGs suppress, rifles kill
- Suppress then flank
- Smoke breaks suppression sightlines
- Morale matters, not just health

### 4.3 Line of Sight

You can only shoot what you can see.

**Fog of War:**
- Areas outside unit vision are hidden
- Last known enemy positions shown as ghosts
- Recon units have extended vision
- High ground provides vision bonus

**Stealth:**
- Some units can hide (snipers, recon)
- Moving reveals position
- Detection range varies by unit
- Revealed by getting too close or attacking

### 4.4 Veterancy

Units that survive get better.

**Veterancy Levels:**
- **Rookie:** Default stats
- **Experienced:** +10% damage, +10% health (5 kills)
- **Veteran:** +20% damage, +20% health, ability upgrade (15 kills)
- **Elite:** +30% damage, +30% health, unique ability (30 kills)

**Why It Matters:**
- Incentivizes keeping units alive
- Experienced armies are stronger
- Losing veterans hurts
- Creates attachment to units

### 4.5 Morale System

Units can break and run.

**Morale Factors:**
- Taking casualties: -morale
- Under suppression: -morale
- Losing nearby friendly units: -morale
- Near friendly vehicles/heroes: +morale
- Winning fights: +morale
- In cover: morale stable

**Morale States:**
- **Steady:** Normal behavior
- **Shaken:** -25% effectiveness, won't advance
- **Broken:** Retreats to nearest safe position
- **Rallied:** Recovers after reaching safety

---

## Part 5: Orbital Strike System

The signature feature. When the sky opens up.

### How It Works

```
1. CAPTURE UPLINK
   └── Infantry takes control point (30 sec)
   
2. UPLINK ACTIVATES
   └── Icon appears on your command bar
   └── Cooldown starts (60-180 sec depending on strike type)
   
3. REQUEST STRIKE
   └── Select strike type from orbital menu
   └── Pay ISK cost
   └── Designate target area
   
4. TARGETING PHASE
   └── Red warning zone appears (visible to enemies)
   └── 5-10 second delay (time to evacuate)
   
5. IMPACT
   └── Strike hits designated area
   └── Devastating damage
   └── Terrain may be altered (craters)
   
6. COOLDOWN
   └── Cannot request same strike type for X seconds
   └── More uplinks = shorter cooldowns
```

### Strike Types

**PRECISION STRIKE**
```
Radius: Small (15m)
Damage: Very High
Delay: 5 seconds
Cooldown: 60 seconds
Cost: 200 ISK

Best for: Single vehicles, fortifications, clustered infantry
Counterplay: Short warning, mobile units can escape
```

**BOMBARDMENT**
```
Radius: Large (40m)
Damage: Medium
Delay: 8 seconds
Cooldown: 120 seconds
Cost: 400 ISK

Best for: Area denial, breaking defensive positions
Counterplay: Long warning, spread out
```

**EMP STRIKE**
```
Radius: Medium (25m)
Damage: None (disables)
Delay: 6 seconds
Cooldown: 90 seconds
Cost: 300 ISK

Effect: Disables vehicles, turrets, shields for 15 seconds
Best for: Opening for assault, neutralizing vehicle push
Counterplay: Infantry unaffected, can capture disabled vehicles
```

**ORBITAL LASER**
```
Radius: Line (10m wide, 100m long)
Damage: Extreme
Delay: 10 seconds
Cooldown: 180 seconds
Cost: 600 ISK

Best for: Destroying everything in a line, dramatic effect
Counterplay: Long warning, clear path, don't cluster
```

### Uplink Strategy

Uplinks are key strategic objectives:

- Control 1 uplink: Basic strikes, long cooldowns
- Control 2 uplinks: All strikes, medium cooldowns
- Control 3+ uplinks: Reduced cooldowns, bonus strike power

**Uplink positioning** determines map control. The faction that controls the uplinks controls the tempo.

---

## Part 6: Economy & Production

### Resource Types

**NANITE PASTE (NP)**
```
Generation: 
  - Base income: +50 NP/min
  - Per fuel depot: +30 NP/min
  - Per territory: +10 NP/min

Used for:
  - Infantry units
  - Light vehicles
  - Basic structures
  - Repairs

Cap: 1000 NP (excess lost)
```

**ISK (Interstellar Kredits)**
```
Generation:
  - Base income: +20 ISK/min
  - Per territory: +15 ISK/min
  - Per kill: +5-50 ISK (based on unit value)
  - Bounty for objectives: +100 ISK

Used for:
  - Heavy vehicles
  - Aircraft
  - Orbital strikes
  - Upgrades

Cap: 2000 ISK
```

### Production System

**No Base Building.** Units are produced from off-map and deploy via:

1. **HQ Deployment** — Units spawn at your base, walk to front
2. **APC Spawn** — Infantry can spawn at APCs (forward position)
3. **Dropship Insert** — Pay extra for instant deployment anywhere

**Production Queue:**
- Queue up to 5 units
- Units build simultaneously (not sequentially)
- Build time: 10-60 seconds depending on unit
- Can cancel for partial refund

```
PRODUCTION PANEL

[INFANTRY]  [VEHICLES]  [AIR]  [ORBITAL]

┌─────────────────────────────────────────┐
│ BUILDING:                               │
│ • Infantry Squad    ████████░░ 80%     │
│ • Tank              ███░░░░░░░ 30%     │
│ • Dropship          █░░░░░░░░░ 10%     │
│                                         │
│ RESOURCES: NP 450/1000  ISK 780/2000   │
└─────────────────────────────────────────┘
```

---

## Part 7: Controls & UI

### Control Scheme

**Mouse & Keyboard (Primary):**
```
LEFT CLICK      - Select unit / Confirm action
RIGHT CLICK     - Move / Attack-move
DRAG SELECT     - Box select multiple units
CTRL + CLICK    - Add to selection
SHIFT + CLICK   - Queue commands
ALT + CLICK     - Attack ground

1-9             - Control groups
CTRL + 1-9      - Assign control group
TAB             - Cycle through selected units

Q, W, E, R      - Unit abilities
A               - Attack-move mode
S               - Stop
H               - Hold position
G               - Garrison building
V               - Unload passengers

SPACE           - Center on selected
BACKSPACE       - Center on base
F1-F4           - Jump to saved camera positions

M               - Toggle minimap size
P               - Pause (single player)
ESC             - Deselect / Menu
```

**Controller Support (Optional):**
```
LEFT STICK      - Pan camera
RIGHT STICK     - Cursor movement
A               - Select / Confirm
B               - Cancel / Deselect
X               - Ability 1
Y               - Ability 2
LB              - Previous unit
RB              - Next unit
LT              - Slow cursor (precision)
RT              - Attack command
D-PAD           - Control groups
```

### HUD Layout

```
┌─────────────────────────────────────────────────────────────────────┐
│ [RESOURCES]                              [UPLINK STATUS]            │
│ NP: 450  ISK: 780                        ● ● ○ (2/3 controlled)    │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│                                                                     │
│                         BATTLEFIELD                                 │
│                                                                     │
│                                          ┌────────────┐             │
│                                          │  MINIMAP   │             │
│                                          │            │             │
│                                          │    ◆ ◆    │             │
│                                          │      ●     │             │
│                                          └────────────┘             │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│ [SELECTED UNIT]                          [ABILITIES]                │
│ ┌──────────────────┐                     ┌──┐┌──┐┌──┐┌──┐         │
│ │ Infantry Squad   │                     │Q ││W ││E ││R │         │
│ │ ████████░░ 80%   │                     │🔥││💨││🎯││⚡│         │
│ │ Vet: ★★☆        │                     └──┘└──┘└──┘└──┘         │
│ │ 4/4 soldiers     │                                                │
│ └──────────────────┘                     [PRODUCTION QUEUE]         │
│                                          ░░░░░ ░░░ ░░░░░           │
└─────────────────────────────────────────────────────────────────────┘
```

### Selection Feedback

When units are selected:
- Health bars visible above units
- Colored ring around unit (faction color)
- Unit card in HUD shows details
- Abilities become clickable
- Right-click shows movement preview

---

## Part 8: Map Design Principles

### Map Structure

Every map should have:

**1. Symmetric Layout** (for competitive fairness)
- Mirrored or rotationally symmetric
- Equal access to resources
- No spawn advantage

**2. Defined Lanes**
- 2-3 main approach routes
- Natural chokepoints
- Flanking options that require commitment

**3. Key Terrain**
- High ground (vision bonus, defensive advantage)
- Cover clusters (infantry strongpoints)
- Open areas (vehicle territory)
- Urban/dense areas (infantry territory)

**4. Strategic Points**
- Capture points (sector control)
- Fuel depots (resource boost)
- Uplink stations (orbital access)
- Chokepoints (defensive positions)

### Example Map: "Caldari Refinery"

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   [TEAM A BASE]                                             │
│        │                                                    │
│        ├────► [SECTOR A: Fuel Depot]                       │
│        │           │                                        │
│        │           │    ┌─────────────┐                    │
│        │           └────┤   RIDGE     │                    │
│        │                │  (high      │                    │
│        │                │   ground)   │                    │
│        │                └──────┬──────┘                    │
│        │                       │                            │
│        ├──────────► [SECTOR B: Uplink Station] ◄──────────┤│
│        │                       │                           ││
│        │                ┌──────┴──────┐                    ││
│        │                │   VALLEY    │                    ││
│        │           ┌────┤  (vehicle   │                    ││
│        │           │    │   lane)     │                    ││
│        │           │    └─────────────┘                    ││
│        ├────► [SECTOR C: Fuel Depot]                       ││
│        │                                                    ││
│   [TEAM B BASE] ◄───────────────────────────────────────────┘│
│                                                             │
└─────────────────────────────────────────────────────────────┘

KEY FEATURES:
- Central uplink (high value, contested)
- Two flanking fuel depots (resources, secondary objectives)
- Ridge provides overwatch on center
- Valley is vehicle-friendly but exposed
- Urban areas near bases favor infantry
```

---

## Part 9: Faction Deep Dive

### AMARR LOYALISTS

**Visual Identity:**
- Gold and bronze metals
- Religious iconography (suns, rays)
- Clean, ornate design
- Laser/beam weapons (gold beams)

**Playstyle:** Durable, methodical, powerful in sustained engagements

**Unique Mechanics:**
- **Armor Focus:** Higher HP, slower repair
- **Laser Weapons:** No reload, but overheat
- **Faith:** Morale bonuses near command units

**Unique Units:**

| Unit | Role | Special |
|------|------|---------|
| **Templar Guard** | Elite infantry | +50% health, inspire nearby |
| **Revelation Tank** | Siege tank | Transforms for artillery mode |
| **Inquisitor Gunship** | Heavy air | Sustained beam, burns infantry |

**Faction Strength:** Unbreakable defensive lines, devastating if they reach your position
**Faction Weakness:** Slow, predictable, outmaneuvered by fast factions

---

### CALDARI CORPORATE

**Visual Identity:**
- Blue and grey
- Corporate efficiency, clean lines
- Missile pods, railguns
- Shield effects (blue shimmer)

**Playstyle:** Balanced, flexible, strong at range

**Unique Mechanics:**
- **Shield Focus:** Regenerating shields, lower HP
- **Missile Systems:** Lock-on required, high damage
- **Efficiency:** Reduced production costs

**Unique Units:**

| Unit | Role | Special |
|------|------|---------|
| **Corporate Security** | Standard infantry | Cheaper, faster production |
| **Basilisk Tank** | Shield tank | Projects shield to nearby units |
| **Vulture Interceptor** | Fast air | Anti-air specialist, cheap |

**Faction Strength:** Versatility, economic advantage, ranged combat
**Faction Weakness:** Fragile when shields drop, weak in close combat

---

### MINMATAR REPUBLIC

**Visual Identity:**
- Rust, red, salvaged look
- Tribal markings, asymmetric design
- Projectile weapons (bullets, shells)
- Speed lines, aggressive angles

**Playstyle:** Fast, aggressive, hit-and-run

**Unique Mechanics:**
- **Speed Focus:** All units faster
- **Projectile Weapons:** High burst, must reload
- **Guerrilla:** Bonuses when outnumbered

**Unique Units:**

| Unit | Role | Special |
|------|------|---------|
| **Freedom Fighters** | Skirmish infantry | Can deploy anywhere on map |
| **Tempest Buggy** | Ultra-light vehicle | Fastest unit, can ram |
| **Hound Bomber** | Strike craft | Cloaked until attack |

**Faction Strength:** Map control, flanking, overwhelming aggression
**Faction Weakness:** Fragile, poor at defending, needs constant action

---

## Part 10: Campaign Structure

### Campaign Overview

A single-player campaign that teaches mechanics and tells a story.

**Structure:**
- 3 Acts, 7 missions each (21 missions total)
- Play as one faction per act (experience all three)
- Escalating complexity
- Boss battles (unique scenarios)

### Act 1: Corporate Wars (Caldari)

**Setting:** Industrial planet, corporate conflict

**Missions:**
1. **Tutorial: First Contract** — Basic movement, combat
2. **Fuel Depot Assault** — Capture mechanics
3. **Convoy Escort** — Protecting moving units
4. **Urban Pacification** — Infantry in buildings
5. **Tank Breakthrough** — Vehicle focus
6. **Uplink Capture** — Orbital introduction
7. **Corporate Takeover** — Full combined arms assault

### Act 2: Holy Crusade (Amarr)

**Setting:** Religious conflict, defensive campaign

**Missions:**
1. **Hold the Line** — Defensive mechanics
2. **Pilgrimage** — Escort mission
3. **Heretic Purge** — Urban combat
4. **Temple Defense** — Fortifications
5. **Counter-Attack** — Transitioning from defense to offense
6. **Divine Intervention** — Orbital strike focus
7. **Inquisition** — Final assault on enemy stronghold

### Act 3: Liberation (Minmatar)

**Setting:** Guerrilla warfare, outnumbered

**Missions:**
1. **Raid** — Hit and run tactics
2. **Ambush** — Using terrain, stealth
3. **Sabotage** — Destroy objectives, avoid detection
4. **Rescue** — Extract friendly units
5. **Uprising** — Capturing territory with limited resources
6. **Combined Fleet** — Working with allies
7. **Independence Day** — Final massive battle

---

## Part 11: Technical Architecture

### Engine & Stack

```
Engine: Unity 6
Language: C#
Networking: Unity Netcode for GameObjects (future multiplayer)
Pathfinding: Unity NavMesh + custom flow field for large unit counts
UI: UI Toolkit
Audio: Unity Audio (upgrade to FMOD/Wwise later)
```

### Project Structure

```
Assets/
├── _Project/
│   ├── Scripts/
│   │   ├── Core/
│   │   │   ├── GameManager.cs
│   │   │   ├── MatchManager.cs
│   │   │   ├── FactionManager.cs
│   │   │   └── ResourceManager.cs
│   │   │
│   │   ├── Units/
│   │   │   ├── UnitBase.cs
│   │   │   ├── InfantrySquad.cs
│   │   │   ├── Vehicle.cs
│   │   │   ├── Aircraft.cs
│   │   │   ├── UnitStats.cs
│   │   │   └── UnitAbility.cs
│   │   │
│   │   ├── AI/
│   │   │   ├── UnitAI.cs
│   │   │   ├── SquadBehavior.cs
│   │   │   ├── CommanderAI.cs (for skirmish vs AI)
│   │   │   └── Pathfinding/
│   │   │
│   │   ├── Combat/
│   │   │   ├── WeaponSystem.cs
│   │   │   ├── DamageCalculator.cs
│   │   │   ├── ProjectileManager.cs
│   │   │   ├── CoverSystem.cs
│   │   │   └── SuppressionSystem.cs
│   │   │
│   │   ├── Territory/
│   │   │   ├── SectorManager.cs
│   │   │   ├── CapturePoint.cs
│   │   │   ├── ResourceNode.cs
│   │   │   └── UplinkStation.cs
│   │   │
│   │   ├── Orbital/
│   │   │   ├── OrbitalManager.cs
│   │   │   ├── OrbitalStrike.cs
│   │   │   └── StrikeEffects.cs
│   │   │
│   │   ├── Production/
│   │   │   ├── ProductionQueue.cs
│   │   │   ├── UnitFactory.cs
│   │   │   └── DeploymentManager.cs
│   │   │
│   │   ├── Selection/
│   │   │   ├── SelectionManager.cs
│   │   │   ├── ControlGroup.cs
│   │   │   └── CommandSystem.cs
│   │   │
│   │   ├── Camera/
│   │   │   ├── RTSCamera.cs
│   │   │   ├── CameraControls.cs
│   │   │   └── MinimapCamera.cs
│   │   │
│   │   └── UI/
│   │       ├── HUDManager.cs
│   │       ├── SelectionPanel.cs
│   │       ├── ProductionPanel.cs
│   │       ├── MinimapUI.cs
│   │       └── OrbitalMenu.cs
│   │
│   ├── Data/
│   │   ├── Units/
│   │   ├── Factions/
│   │   ├── Weapons/
│   │   └── Maps/
│   │
│   └── Prefabs/
│       ├── Units/
│       ├── Effects/
│       ├── Buildings/
│       └── UI/
```

### Performance Targets

- **Unit Count:** 200+ units on screen
- **Pathfinding:** Flow field for large groups, A* for small
- **Frame Rate:** 60 FPS minimum
- **Match Size:** Up to 4 players (2v2)

---

## Part 12: Prototype Scope

### Minimum Playable Prototype (4-6 weeks)

**One Faction:**
- Infantry Squad
- Heavy Weapons Squad
- LAV
- Tank
- Basic structures (turret)

**One Map:**
- 3 capture points
- 1 uplink
- Symmetric layout

**Core Systems:**
- Selection and movement
- Basic combat (hitscan)
- Cover system (simple)
- Capture points
- Resource generation
- Production queue
- One orbital strike type

**Win Condition:**
- Capture majority of points
- VP drain
- Or destroy enemy HQ

**AI Opponent:**
- Builds units
- Attacks capture points
- Uses basic tactics

### What This Tests

1. Does selecting and commanding units feel good?
2. Is combat readable and satisfying?
3. Do territories create interesting gameplay?
4. Is the economy balanced?
5. Do orbital strikes feel powerful and fair?

---

## Part 13: Development Timeline

### Phase 1: Foundation (Weeks 1-2)
- Project setup
- Camera system
- Selection system
- Basic movement and pathfinding
- Placeholder units

### Phase 2: Combat (Weeks 3-4)
- Weapon systems
- Damage and health
- Cover system
- Basic infantry combat
- Unit abilities

### Phase 3: Territory (Weeks 5-6)
- Capture point system
- Sector control
- Resource generation
- Basic economy
- Win conditions

### Phase 4: Production (Weeks 7-8)
- Production queue
- Unit spawning
- Reinforcement flow
- Basic UI for production

### Phase 5: Vehicles & Combined Arms (Weeks 9-10)
- Vehicle units
- Vehicle combat
- Infantry-vehicle interaction
- Transport mechanics

### Phase 6: Orbital (Weeks 11-12)
- Uplink stations
- Strike targeting
- Strike effects
- Integration with territory control

### Phase 7: AI & Polish (Weeks 13-14)
- Skirmish AI
- Balance tuning
- UI polish
- Audio implementation

### Phase 8: Content (Weeks 15-16)
- Second faction
- Additional maps
- Campaign missions (3-5)

---

## Summary: Why RTS Works for DUST

1. **Shows the full battlefield** — You see hundreds of units, multiple fronts, the whole war
2. **Combined arms done right** — Infantry, vehicles, air, orbital all visible and commanded
3. **War economy** — Resources matter, losses hurt, decisions have weight
4. **Faction identity** — Clear asymmetric factions with distinct playstyles
5. **Orbital integration** — The signature DUST feature becomes a strategic system
6. **Scalable scope** — Start with skirmish, expand to campaign, potentially multiplayer
7. **Proven genre** — RTS has a dedicated audience hungry for new entries

The fantasy: **You are the commander. You see the whole battlefield. Your decisions move armies. And when you capture that uplink and call down orbital fire on the enemy tank column... you feel like a god of war.**

---

*DUST Orbital Command — RTS Design Document v1.0*
