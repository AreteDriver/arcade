class_name MachineComponent
extends Node2D

## Base class for all machine components.
## Subclasses override _setup_ports(), _setup_parameters(), and _process_component().

signal state_changed(new_state: State)
signal parameter_changed(param_name: String, value: float)
signal component_selected(component: MachineComponent)

enum State { IDLE, ACTIVE, BROKEN, OVERLOADED }

@export_group("Component Info")
@export var component_name: String = "Component"
@export var component_description: String = ""
@export var component_icon: Texture2D

## Ports populated by _setup_ports()
var input_ports: Array[Port] = []
var output_ports: Array[Port] = []

## Parameters: {name: {value, min, max, step, label}}
var parameters: Dictionary = {}

## State machine
var current_state: State = State.IDLE

## Selection / drag state
var is_selected: bool = false
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

## Initial position for reset
var _initial_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_setup_ports()
	_setup_parameters()
	_initial_position = position
	queue_redraw()


## Override in subclasses to define input/output ports
func _setup_ports() -> void:
	pass


## Override in subclasses to define adjustable parameters
func _setup_parameters() -> void:
	pass


## Override: called each physics frame during simulation
func _process_component(_delta: float) -> void:
	pass


## Override: called when a parameter slider is adjusted
func _on_parameter_changed(_param_name: String, _value: float) -> void:
	pass


## Override: called when data arrives at an input port
func _on_input_received(_port: Port, _data: Variant) -> void:
	pass


## Override: draw the component's visual representation
func _draw_component() -> void:
	# Default: gray box
	draw_rect(Rect2(-24, -24, 48, 48), Color(0.3, 0.3, 0.35), true)
	draw_rect(Rect2(-24, -24, 48, 48), Color(0.5, 0.5, 0.55), false, 1.5)


## Override: return visual bounds of this component
func _get_bounds() -> Rect2:
	return Rect2(-32, -32, 64, 64)


## Override: return the registry type name
func _get_component_type() -> String:
	return "unknown"


func _draw() -> void:
	_draw_component()

	var rect := _get_bounds()

	# State overlays
	match current_state:
		State.BROKEN:
			_draw_broken_overlay(rect)
		State.OVERLOADED:
			_draw_overload_overlay(rect)

	# Selection highlight
	if is_selected:
		draw_rect(rect.grow(4), Color(0.0, 0.8, 1.0, 0.6), false, 2.0)


func _draw_broken_overlay(rect: Rect2) -> void:
	# Crack lines
	var cx: float = rect.get_center().x
	var cy: float = rect.get_center().y
	var crack_color := Color(0.8, 0.4, 0.1, 0.7)
	draw_line(Vector2(cx - 8, cy - 12), Vector2(cx + 2, cy), crack_color, 2.0)
	draw_line(Vector2(cx + 2, cy), Vector2(cx - 4, cy + 10), crack_color, 2.0)
	draw_line(Vector2(cx + 2, cy), Vector2(cx + 10, cy + 6), crack_color, 1.5)
	# Dim red tint
	draw_rect(rect, Color(0.6, 0.2, 0.1, 0.15), true)


func _draw_overload_overlay(rect: Rect2) -> void:
	# Pulsing red border
	var pulse: float = (sin(Time.get_ticks_msec() / 150.0) + 1.0) / 2.0
	var red := Color(1.0, 0.2, 0.1, 0.2 + pulse * 0.3)
	draw_rect(rect, red, true)
	draw_rect(rect.grow(2), Color(1.0, 0.3, 0.1, 0.4 + pulse * 0.4), false, 2.0)


## Add a port to this component
func add_port(p_name: String, p_type: Port.PortType, p_direction: Port.Direction, p_offset: Vector2) -> Port:
	var port := Port.new()
	port.port_name = p_name
	port.port_type = p_type
	port.direction = p_direction
	port.owner_component = self
	port.position = p_offset
	add_child(port)

	if p_direction == Port.Direction.INPUT:
		input_ports.append(port)
	else:
		output_ports.append(port)

	return port


## Get a parameter's current value
func get_parameter(param_name: String) -> float:
	if param_name in parameters:
		return parameters[param_name]["value"]
	return 0.0


## Set a parameter's value (clamped to min/max)
func set_parameter(param_name: String, value: float) -> void:
	if param_name not in parameters:
		return
	var param: Dictionary = parameters[param_name]
	var clamped: float = clampf(value, param["min"], param["max"])
	if not is_equal_approx(param["value"], clamped):
		param["value"] = clamped
		# Auto-handle rotation for "angle" parameter
		if param_name == "angle":
			rotation = deg_to_rad(clamped)
		parameter_changed.emit(param_name, clamped)
		_on_parameter_changed(param_name, clamped)
		queue_redraw()


## Register a parameter with metadata
func register_parameter(p_name: String, label: String, default_val: float,
		min_val: float, max_val: float, step: float = 0.1) -> void:
	parameters[p_name] = {
		"value": default_val,
		"min": min_val,
		"max": max_val,
		"step": step,
		"label": label,
	}


## Get parameter definitions for tooltip display
func get_parameter_definitions() -> Array[Dictionary]:
	var defs: Array[Dictionary] = []
	for key in parameters:
		var p: Dictionary = parameters[key]
		defs.append({
			"name": key,
			"display_name": p.get("label", key),
			"default": p.get("value", 0.0),
			"min": p.get("min", 0.0),
			"max": p.get("max", 100.0),
			"step": p.get("step", 0.1),
		})
	return defs


## Send data from a named output port to connected inputs
func send_output(port_name: String, data: Variant) -> void:
	for port in output_ports:
		if port.port_name == port_name and port.connected_to != null:
			var target: Port = port.connected_to
			if target.owner_component != null and target.owner_component.has_method("_on_input_received"):
				target.owner_component._on_input_received(target, data)


## Change component state
func set_state(new_state: State) -> void:
	if current_state != new_state:
		var old_state: State = current_state
		current_state = new_state
		state_changed.emit(new_state)

		# Apply state-based modulate tint
		match new_state:
			State.IDLE:
				modulate = Color(0.7, 0.7, 0.75)
			State.ACTIVE:
				modulate = Color.WHITE
			State.BROKEN:
				modulate = Color(0.65, 0.55, 0.55)
				VFX.break_effect(self)
			State.OVERLOADED:
				modulate = Color(1.0, 0.85, 0.85)
				VFX.warning(self)

		queue_redraw()


## Get all ports (input + output)
func get_all_ports() -> Array[Port]:
	var all_ports: Array[Port] = []
	all_ports.append_array(input_ports)
	all_ports.append_array(output_ports)
	return all_ports


## Find a port by name
func get_port(p_name: String) -> Port:
	for port in input_ports:
		if port.port_name == p_name:
			return port
	for port in output_ports:
		if port.port_name == p_name:
			return port
	return null


## Selection
func set_selected(value: bool) -> void:
	if is_selected != value:
		is_selected = value
		if value:
			component_selected.emit(self)
		queue_redraw()


## Reset to initial state for simulation restart
func reset_component() -> void:
	set_state(State.IDLE)


## Serialize for save/load
func serialize() -> Dictionary:
	var port_connections: Array[Dictionary] = []
	for port in output_ports:
		if port.connected_to != null:
			port_connections.append({
				"from_port": port.port_name,
				"to": port.connected_to.owner_component.name if port.connected_to.owner_component else "",
				"to_port": port.connected_to.port_name,
			})

	var param_values: Dictionary = {}
	for key in parameters:
		param_values[key] = parameters[key]["value"]

	return {
		"id": name,
		"type": _get_component_type(),
		"position": [position.x, position.y],
		"parameters": param_values,
		"connections": port_connections,
	}


## Check if a world position is within this component's bounds
func hit_test(world_pos: Vector2) -> bool:
	var local_pos: Vector2 = world_pos - global_position
	return _get_bounds().has_point(local_pos)


## Find the nearest port to a world position within a threshold
func get_port_at(world_pos: Vector2, threshold: float = 24.0) -> Port:
	var best_port: Port = null
	var best_dist: float = threshold
	for port in get_all_ports():
		var dist: float = world_pos.distance_to(port.global_position)
		if dist < best_dist:
			best_dist = dist
			best_port = port
	return best_port
