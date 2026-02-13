# Claude Code Prompt: Phase 3 — Discovery Mode

## Context
Read `docs/CONCEPT.md` for full design. Phases 1-2 are complete: core engine with components, connections, simulation, and visual/audio feedback.

## Task
Build Discovery Mode — the structured gameplay where kids encounter pre-built fantastical machines and solve challenges by fixing, calibrating, completing, or stabilizing them.

## Requirements

### 1. Machine Definition Format (`machine_definition.gd`)
Resource class for defining pre-built machines:

```gdscript
class_name MachineDefinition extends Resource

@export var machine_name: String
@export var machine_description: String
@export var world: int  # 1-4
@export var level: int  # Order within world
@export var challenge_type: String  # "broken", "miscalibrated", "incomplete", "overloaded"

# The full machine layout (components + connections + parameters)
@export var machine_data: Dictionary  # Same format as save JSON

# Challenge-specific data
@export var broken_component_ids: Array[String]       # Which components are broken
@export var target_parameters: Dictionary              # {component_id: {param: target_value}}
@export var missing_component_slots: Array[Dictionary] # {position, required_type, port_connections}
@export var overload_threshold: float                  # When does the machine overload

# Objectives
@export var objective_text: String
@export var hint_texts: Array[String]  # Progressive hints
@export var completion_condition: String  # Script expression or signal to listen for
@export var unlocked_components: Array[String]  # Component types unlocked on completion

# Presentation
@export var intro_dialog: Array[String]  # Story text shown before challenge
@export var success_dialog: Array[String]
@export var machine_icon: Texture2D
```

### 2. Challenge System (`challenge_manager.gd`)

Manages the active challenge state:

**Broken challenges:**
- Specific components start in BROKEN state
- Player must identify broken component (visual clues: sparks, smoke)
- Provide a repair tray with correct + decoy replacement components
- Player drags correct replacement onto broken component
- Validate: correct type placed → machine works

**Miscalibrated challenges:**
- Machine runs but produces wrong output
- Target output shown as reference (e.g., "the painting should be clear, not blurry")
- Player adjusts parameter sliders on specific components
- Real-time feedback: output changes as parameters change
- Completion: all parameters within tolerance of target values

**Incomplete challenges:**
- Machine has empty slots (ghost outlines showing where components go)
- Component tray offers limited selection
- Player fills slots and connects wires
- Some slots have port hints showing required connections
- Completion: all slots filled with compatible components, machine runs

**Overloaded challenges:**
- Machine is running too hot/fast
- Visual: red glow, shaking, warning gauges
- Player must reroute flow (disconnect/reconnect wires) or add dampening components
- Add pressure release valves, flow splitters, etc.
- Completion: all components below overload threshold

### 3. Objective System (`objective_tracker.gd`)
- Display current objective text at top of screen
- Track completion conditions per challenge type
- Progressive hint system (hint button, shows next hint after delay)
- Completion detection triggers success sequence
- Star rating: 1 star = completed, 2 = no hints used, 3 = under par time

### 4. World Map / Level Select (`world_select.tscn`, `level_select.tscn`)
- World select: 4 worlds as large illustrated buttons
- Level select per world: 4 machines shown as cards
- Lock/unlock state based on progression
- Star display per completed level
- Simple left/right swipe navigation

### 5. Build World 1: Home of Tomorrow (4 Machines)

**Level 1-1: Breakfast Bot (Tutorial)**
- Challenge type: Incomplete
- Concept: A chain reaction to make toast — ball rolls down ramp → hits switch → activates conveyor → bread slides into toaster zone
- Missing: The ramp and the switch
- Teaches: Component placement, basic connections
- Components used: Ramp, Conveyor, Switch, Pipe
- Detailed tutorial overlays guide every step

**Level 1-2: Sock Sorter 3000**
- Challenge type: Miscalibrated
- Concept: Phase gates filter colored "socks" (particles) into correct bins
- Problem: Phase gates have wrong filter settings, socks going to wrong bins
- Fix: Adjust phase gate filter parameters to match sock colors to bins
- Components used: Pipe, Phase Gate, Fan, Conveyor
- Teaches: Parameter adjustment, observation

**Level 1-3: Pet Translator**
- Challenge type: Broken
- Concept: Bark energy → quantum coupler → text display
- Problem: Quantum coupler is broken, no translation happening
- Fix: Identify the sparking component, replace with working quantum coupler from repair tray
- Decoys in tray: Gravity node, Chrono spring (wrong types)
- Components used: Quantum Coupler, Pipe, Holo Projector
- Teaches: Diagnosis, component identification

**Level 1-4: Room Tidier**
- Challenge type: Overloaded
- Concept: Gravity nodes + warp belts vacuum up mess
- Problem: Too much power from fusion core, everything shaking
- Fix: Add a valve to regulate flow, reroute excess energy through a chrono spring (buffer)
- Components used: Fusion Core, Gravity Node, Warp Belt, Valve, Chrono Spring
- Teaches: Flow management, overload handling

### 6. Tutorial System (`tutorial_overlay.gd`)
For Level 1-1 specifically:
- Step-by-step overlay with highlighted zones
- "Drag the ramp here" with glowing target area
- "Now connect this port to that port" with animated arrow
- "Tap the play button" with pulsing highlight
- Blocks unrelated actions during tutorial steps
- Skippable after first completion

### 7. Transition & Story
- Each machine has a brief intro: 2-3 text boxes with the machine's story
- "The Breakfast Bot hasn't made toast in weeks! Can you fix it?"
- Success: celebratory animation + "You did it!" + show unlocked components
- Use a simple dialog box system (portrait + text + tap to advance)

### 8. Progress Persistence
- Save completion state, stars, and unlocks to user://progress.json
- Auto-save after each level completion
- Load on game start to restore progression state

## Technical Notes
- MachineDefinitions stored as .tres resource files in res://content/machines/
- Each world is a subfolder: res://content/machines/world1/
- Challenge validation runs every physics frame during simulation
- Tolerance for miscalibration: ±5% of target value by default
- Tutorial system uses a state machine, not coroutines
- Level select should work with touch/swipe on mobile

## Output
Implement all systems. After this phase, a player can:
1. See a world/level select screen
2. Choose World 1, Level 1 (Breakfast Bot)
3. Read the intro story
4. Follow the tutorial to complete the machine
5. See success celebration and unlock notification
6. Return to level select with 1-3 stars
7. Play levels 1-2 through 1-4 with increasing complexity
8. Unlock new components through progression
