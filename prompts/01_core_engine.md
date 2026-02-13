# Claude Code Prompt: Phase 1 — Core Engine

## Context
Read `docs/CONCEPT.md` for full game design. This is a Godot 4.x (GDScript) physics sandbox game for kids where they build fantastical machines from interconnected components.

## Task
Scaffold the core engine for Machine Shop of Tomorrow. Build the foundational systems that everything else depends on.

## Requirements

### 1. Project Structure
Create a Godot 4 project with this layout:
```
project.godot
src/
  components/
    base/
      machine_component.gd    # Base class all components extend
      port.gd                 # Port class (typed connection point)
      wire.gd                 # Visual wire between ports
    tier1/
      ramp.gd
      ramp.tscn
      pipe.gd  
      pipe.tscn
      fan.gd
      fan.tscn
  systems/
    component_graph.gd        # Directed graph managing connections
    simulation_manager.gd     # Play/pause/reset/step logic
    component_registry.gd     # Registry of available component types
  ui/
    component_tray.gd         # Bottom tray, drag components out
    component_tray.tscn
    parameter_panel.gd        # Side panel with sliders per component
    parameter_panel.tscn
    simulation_controls.gd    # Play/pause/reset buttons
    simulation_controls.tscn
  scenes/
    main.tscn                 # Main game scene
    machine_canvas.tscn       # The workspace where machines are built
```

### 2. Base Component System (`machine_component.gd`)
```
class_name MachineComponent extends Node2D

# Core properties
@export var component_name: String
@export var component_description: String
@export var component_icon: Texture2D

# Port system
var input_ports: Array[Port] = []
var output_ports: Array[Port] = []

# Parameters - Dictionary of {param_name: {value, min, max, step, label}}
var parameters: Dictionary = {}

# State machine
enum State {IDLE, ACTIVE, BROKEN, OVERLOADED}
var current_state: State = State.IDLE

# Methods to implement in subclasses
func _setup_ports() -> void: pass
func _setup_parameters() -> void: pass  
func _process_component(delta: float) -> void: pass
func _on_parameter_changed(param_name: String, value: float) -> void: pass
func _on_input_received(port: Port, data: Variant) -> void: pass

# Built-in
func get_parameter(name: String) -> float
func set_parameter(name: String, value: float) -> void
func send_output(port_name: String, data: Variant) -> void
```

### 3. Port System (`port.gd`)
```
class_name Port extends Marker2D

enum PortType {ENERGY, FLOW, SIGNAL}
enum Direction {INPUT, OUTPUT}

var port_type: PortType
var direction: Direction
var port_name: String
var connected_to: Port = null  # The port this connects to
var owner_component: MachineComponent

# Visual: colored circle matching type
# ENERGY = yellow, FLOW = blue, SIGNAL = green
```

### 4. Component Graph (`component_graph.gd`)
- Maintain adjacency list of component connections
- Topological sort for evaluation order
- Methods: add_component(), remove_component(), connect_ports(), disconnect_ports()
- Validate connections (matching types only)
- Serialize to/from Dictionary (for JSON save/load)

### 5. Three Tier 1 Components

**Ramp:**
- StaticBody2D with CollisionShape2D (angled rectangle)
- Parameters: angle (0-80°), friction (0-1)
- No ports needed — pure physics interaction
- Objects roll/slide down based on angle and friction

**Pipe:**
- StaticBody2D tube shape
- Input port: Flow, Output port: Flow
- Parameters: diameter (affects flow speed)
- Spawns particle-like RigidBody2D balls that travel through

**Fan:**
- StaticBody2D with Area2D for wind zone
- Input port: Energy
- Parameters: speed (0-100), direction (0-360°)
- Applies force to RigidBody2D objects in its Area2D

### 6. Drag-and-Drop from Tray
- ComponentTray at bottom shows available components
- Touch/click and drag to place on canvas
- Snap to grid (optional, configurable)
- Tap placed component to select → shows ParameterPanel

### 7. Wire Connections
- Drag from output port to input port to create wire
- Wire is a Line2D that follows the connection
- Color-coded by port type
- Animated flow direction indicator (dashed line animation or particle travel)

### 8. Simulation Controls
- Play: enable physics processing on all components, evaluate graph
- Pause: freeze physics
- Reset: return all components to initial state
- Components only process in ACTIVE state during Play

### 9. Mobile-First Input
- Touch drag for placement
- Pinch zoom on canvas
- Pan with two-finger drag
- Tap to select component
- Long press for context menu (delete, duplicate)

## Technical Constraints
- Target Godot 4.3+
- GDScript only (no C#/C++)
- All scenes use descriptive node names
- Comment all exported variables and public methods
- Use signals for component communication, not direct references
- Use resource files (.tres) for component definitions where appropriate

## Style Guide
- snake_case for variables/functions
- PascalCase for class names
- Group related @export vars with @export_group
- Use typed arrays and return types everywhere
- Emit signals for state changes: `signal state_changed(new_state: State)`
- Emit signals for parameter changes: `signal parameter_changed(name: String, value: float)`

## Output
Create all files with full implementations. Not stubs — working code that compiles in Godot 4. The result should be a runnable project where you can:
1. See a canvas with a component tray
2. Drag a ramp, pipe, and fan onto the canvas
3. Connect the fan's energy output to... (fan is self-powered for now)
4. Adjust parameters with sliders
5. Hit play and see physics objects interact
