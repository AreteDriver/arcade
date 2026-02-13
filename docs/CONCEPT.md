# Machine Shop of Tomorrow

## Game Concept Document

**Genre:** Physics Sandbox / Puzzle  
**Engine:** Godot 4.x (GDScript)  
**Platform:** Android (primary), iOS (stretch)  
**Target Audience:** Kids 6-12, family play  
**Dev Status:** Pre-production  

---

## Elevator Pitch

Kids discover, fix, and invent fantastical machines of the future. Every machine is a chain of interconnected components with real physics — tweak speed, direction, and flow, then watch the reactions ripple through the system. Break it, fix it, build something impossible.

---

## Core Pillars

1. **Cause & Effect** — Every action produces visible, satisfying reactions
2. **Experimentation** — No wrong answers, only discoveries
3. **Imagination** — Sci-fi components that follow consistent-but-exaggerated physics
4. **Progression** — Learn by fixing, then create freely

---

## Game Modes

### Discovery Mode (Structured Play)

Pre-built fantastical machines with objectives:

| Challenge Type | Description | Example |
|---|---|---|
| **Broken** | Diagnose & replace a failed component | The candy rain machine's plasma conduit is cracked |
| **Miscalibrated** | Adjust parameters to correct output | Dream recorder is too fast, paintings are blurry |
| **Incomplete** | Fill in missing pieces | Cloud harvester needs 3 more components to work |
| **Overloaded** | Reroute/rebalance to stabilize | Rainbow engine is overheating, redirect flow |

**Progression:** Each completed challenge unlocks components for Inventor Mode.

### Inventor Mode (Sandbox)

Free-form building with all unlocked components:
- Define machine purpose (input → output)
- Place components on canvas
- Wire connections between input/output ports
- Adjust parameters via sliders/dials
- Run simulation and observe
- Save/load creations (JSON serialization)

---

## Component System

### Architecture

Every component is a Godot scene implementing a common interface:

```
MachineComponent (base class)
├── physics_body: RigidBody2D | StaticBody2D
├── input_ports: Array[Port]
├── output_ports: Array[Port]  
├── parameters: Dictionary  (exposed to UI as sliders/dials)
├── state: enum {IDLE, ACTIVE, BROKEN, OVERLOADED}
├── visual_feedback: AnimatedSprite2D + particles
└── audio_feedback: AudioStreamPlayer2D
```

### Port System

Ports are typed connection points:
- **Energy** (yellow) — power transfer
- **Flow** (blue) — material/particle movement  
- **Signal** (green) — triggers and logic

Components only connect matching port types. Visual wires show flow state.

### Component Library

#### Tier 1 — Familiar Physics (Unlocked Early)
| Component | Inputs | Outputs | Parameters |
|---|---|---|---|
| Ramp | — | Flow | Angle, friction |
| Gear | Energy | Energy | Size, teeth count |
| Pipe | Flow | Flow | Diameter |
| Spring | Energy | Energy | Stiffness, compression |
| Fan | Energy | Flow | Speed, direction |
| Valve | Flow + Signal | Flow | Open threshold |
| Conveyor | Energy | Flow | Speed, direction |
| Switch | Signal | Signal | Toggle/momentary |

#### Tier 2 — Sci-Fi Components (Unlocked via Discovery)
| Component | Inputs | Outputs | Parameters | Behavior |
|---|---|---|---|---|
| Plasma Conduit | Flow | Flow | Temperature, viscosity | Glowing flow, splits/merges |
| Quantum Coupler | Energy | Energy | Range, sync rate | Wireless energy transfer |
| Gravity Node | Energy | Flow | Field strength, polarity | Attracts/repels in radius |
| Chrono Spring | Energy | Energy | Delay, charge rate | Stores energy, timed release |
| Phase Gate | Flow + Signal | Flow | Filter type | Filters by color/size/type |
| Warp Belt | Energy | Flow | Length, endpoints | Teleports objects along path |
| Fusion Core | — | Energy | Output level | Power source, can overload |
| Holo Projector | Energy + Signal | Signal | Pattern | Visual output indicator |

#### Tier 3 — Exotic (Late Game Unlocks)
| Component | Description |
|---|---|
| Dimensional Splitter | Duplicates flow into parallel paths |
| Time Loop Relay | Cycles output back to input with delay |
| Emotion Sensor | Reacts to screen tap patterns |
| Sound Forge | Converts energy to musical tones |
| Cloud Weaver | Particle system sculptor |

---

## Fantastical Machines (Discovery Mode Content)

### World 1: Home of Tomorrow
1. **Breakfast Bot** — Makes toast via an absurd chain reaction (tutorial)
2. **Sock Sorter 3000** — Sorts laundry by color using phase gates
3. **Pet Translator** — Converts bark energy into text via quantum couplers
4. **Room Tidier** — Gravity nodes + warp belts to clean a room

### World 2: Sky Factory  
5. **Cloud Harvester** — Collects clouds, compresses into rain
6. **Rainbow Engine** — Splits light through prismatic conduits
7. **Weather Dial** — Control sun/rain/snow via parameter tuning
8. **Star Polisher** — Orbital gravity nodes clean up stars

### World 3: Dream Workshop
9. **Dream Recorder** — Captures thoughts as flowing particles
10. **Imagination Amplifier** — Small ideas become big via energy chains
11. **Nightmare Filter** — Phase gates sort good/bad dream particles
12. **Memory Projector** — Complex multi-system playback machine

### World 4: Impossible Lab
13. **Gravity Reverser** — Full system inversion puzzle
14. **Time Stretcher** — Chrono springs in sequence
15. **Infinity Machine** — Self-sustaining loop challenge
16. **The Everything Engine** — Final boss: combine all component types

---

## UI/UX Design

### Build Interface
- **Component Tray** — Bottom of screen, scrollable, drag to place
- **Parameter Panel** — Tap component → side panel with sliders/dials
- **Wire Tool** — Drag from output port to input port to connect
- **Play/Pause/Reset** — Top bar controls simulation
- **Speed Control** — Slow-mo for observation, fast-forward for impatient kids

### Visual Feedback Philosophy
Every state change must be **immediately visible**:
- Flow through pipes = animated particles
- Energy transfer = pulsing glow along wires
- Overload = red glow + screen shake + warning particles  
- Broken = sparks + smoke + sad component face
- Success = rainbow burst + celebratory particles + sound

### Audio Design
- Each component has a characteristic hum/sound
- Pitch/tempo changes with parameter adjustments
- Chain reactions create emergent "music" from layered component sounds
- Satisfying click/snap sounds for placement and connections

---

## Technical Architecture

### Scene Tree (Simplified)
```
Main
├── GameManager (autoload singleton)
│   ├── ComponentRegistry
│   ├── SaveLoadManager  
│   └── ProgressTracker
├── MachineCanvas
│   ├── Grid (optional snap)
│   ├── ComponentLayer (all placed components)
│   ├── WireLayer (connection visuals)
│   └── ParticleLayer (flow/effects)
├── UI
│   ├── ComponentTray
│   ├── ParameterPanel
│   ├── SimulationControls
│   └── HUD (objectives, hints)
└── Camera2D (pan/zoom)
```

### Component Graph
Under the hood, machines are directed graphs:
- **Nodes** = Components
- **Edges** = Wire connections (typed by port)
- **Evaluation** = Topological sort each physics frame
- **Serialization** = JSON for save/load

```json
{
  "machine_name": "Breakfast Bot",
  "components": [
    {
      "id": "fusion_core_01",
      "type": "fusion_core",
      "position": [200, 300],
      "parameters": {"output_level": 0.7},
      "connections": [
        {"from_port": "energy_out", "to": "conveyor_01", "to_port": "energy_in"}
      ]
    }
  ]
}
```

### Performance Budget (Mobile)
- Max 150 active RigidBody2D per machine
- Max 500 particles visible simultaneously
- Target 60fps on mid-range Android (2020+)
- Use object pooling for flow particles
- Disable off-screen physics processing

---

## Save System

### Per-Machine Save (JSON)
- Component graph (type, position, connections, parameters)
- Machine metadata (name, description, creator)
- Thumbnail (auto-captured screenshot)

### Player Progress (JSON)
- Discovery Mode completion per machine
- Unlocked components
- Inventor Mode saved machines (array of machine saves)
- Settings (audio, controls)

---

## Development Phases

### Phase 1: Core Engine (Weeks 1-3)
- [ ] Base component class with port system
- [ ] Drag-and-drop placement on canvas
- [ ] Wire connection system
- [ ] Parameter sliders affecting physics
- [ ] Play/pause/reset simulation
- [ ] 3 basic components: Ramp, Pipe, Fan

### Phase 2: Juice & Feel (Weeks 4-5)
- [ ] Visual feedback system (glow, particles, animation)
- [ ] Audio system (component sounds, parameter-reactive)
- [ ] Camera pan/zoom for mobile
- [ ] Touch controls optimization

### Phase 3: Discovery Mode (Weeks 6-8)
- [ ] Machine state system (working/broken/overloaded)
- [ ] Objective system (detect completion conditions)
- [ ] First 4 machines (World 1: Home of Tomorrow)
- [ ] Component unlock progression

### Phase 4: Content & Polish (Weeks 9-12)
- [ ] Remaining sci-fi components
- [ ] Worlds 2-4 machines
- [ ] Inventor Mode save/load
- [ ] Tutorial flow
- [ ] Android export & device testing

### Phase 5: Stretch Goals
- [ ] iOS export
- [ ] Sound Forge component (musical machines)
- [ ] Screenshot/recording sharing
- [ ] Community machine sharing (export/import JSON)

---

## Inspirations
- The Incredible Machine (1992)
- Bad Piggies (Rovio)
- Crazy Machines series
- Human Resource Machine (visual logic)
- Factorio (component chaining, scaled down)
- Kids' Rube Goldberg kits
