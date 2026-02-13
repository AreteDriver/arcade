class_name MachineCanvas
extends Node2D

## The workspace where machines are built.
## Handles component placement, wire creation, selection, and camera control.

signal component_selected(component: MachineComponent)
signal component_deselected()
signal wire_created(wire: Wire)

@onready var component_layer: Node2D = $ComponentLayer
@onready var wire_layer: Node2D = $WireLayer
@onready var particle_layer: Node2D = $ParticleLayer
@onready var camera: Camera2D = $Camera2D
@onready var grid: Node2D = $Grid

var graph: ComponentGraph = ComponentGraph.new()

## Interaction state
enum InteractionMode { NONE, DRAGGING_COMPONENT, CREATING_WIRE, PANNING }
var _mode: InteractionMode = InteractionMode.NONE
var _selected_component: MachineComponent = null
var _dragging_component: MachineComponent = null
var _drag_offset: Vector2 = Vector2.ZERO

## Wire creation state
var _wire_source_port: Port = null
var _wire_preview: Line2D = null

## Camera state
var _pan_start: Vector2 = Vector2.ZERO
var _camera_start: Vector2 = Vector2.ZERO
var _zoom_level: float = 1.0
const MIN_ZOOM: float = 0.3
const MAX_ZOOM: float = 2.0
const ZOOM_STEP: float = 0.1

## Grid
var snap_enabled: bool = true
var grid_size: int = 32

## Component naming counter
var _component_counter: int = 0


## Whether we're in click-to-place mode (component follows cursor, click to drop)
var _placing_from_tray: bool = false


func _ready() -> void:
	SimulationManager.set_graph(graph)
	SimulationManager.simulation_started.connect(_on_simulation_started)
	SimulationManager.simulation_stopped.connect(_on_simulation_stopped)


## Place a new component by type name at a position
func place_component(type_name: String, world_pos: Vector2) -> MachineComponent:
	var component: MachineComponent = ComponentRegistry.create_component(type_name)
	if component == null:
		return null

	_component_counter += 1
	component.name = "%s_%03d" % [type_name, _component_counter]

	if snap_enabled:
		world_pos = _snap_to_grid(world_pos)
	component.position = world_pos

	component_layer.add_child(component)
	graph.add_component(component)

	component.component_selected.connect(_on_component_clicked)

	return component


## Start placing a component from tray click.
## Places at canvas center, enters click-to-place mode (follows cursor until clicked).
func start_placing(type_name: String) -> void:
	if SimulationManager.is_playing():
		return

	# Place at the center of the visible canvas area (camera position)
	var center_pos: Vector2 = camera.get_screen_center_position()
	var component := place_component(type_name, center_pos)
	if component:
		_mode = InteractionMode.DRAGGING_COMPONENT
		_dragging_component = component
		_drag_offset = Vector2.ZERO
		_placing_from_tray = true
		select_component(component)


## Remove a component
func remove_component(component: MachineComponent) -> void:
	if component == _selected_component:
		deselect()

	# Remove associated wires
	_remove_wires_for(component)

	graph.remove_component(component)
	component.queue_free()


## Select a component and show its parameters
func select_component(component: MachineComponent) -> void:
	if _selected_component and _selected_component != component:
		_selected_component.set_selected(false)

	_selected_component = component
	component.set_selected(true)
	component_selected.emit(component)


## Deselect current component
func deselect() -> void:
	if _selected_component:
		_selected_component.set_selected(false)
		_selected_component = null
		component_deselected.emit()


func _process(_delta: float) -> void:
	# During tray placement, track mouse every frame so UI overlay doesn't block it
	if _placing_from_tray and _dragging_component:
		_dragging_component.position = _get_world_mouse()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	var world_pos: Vector2 = _get_world_mouse()

	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_left_press(world_pos)
		else:
			_on_left_release(world_pos)

	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_on_right_press(world_pos)

	elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom(ZOOM_STEP)

	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom(-ZOOM_STEP)

	elif event.button_index == MOUSE_BUTTON_MIDDLE:
		if event.pressed:
			_mode = InteractionMode.PANNING
			_pan_start = event.global_position
			_camera_start = camera.position
		else:
			if _mode == InteractionMode.PANNING:
				_mode = InteractionMode.NONE


func _on_left_press(world_pos: Vector2) -> void:
	if SimulationManager.is_playing():
		return

	# If placing from tray, finalize placement on click
	if _placing_from_tray and _dragging_component:
		if snap_enabled:
			_dragging_component.position = _snap_to_grid(world_pos)
		else:
			_dragging_component.position = world_pos
		_dragging_component = null
		_placing_from_tray = false
		_mode = InteractionMode.NONE
		return

	# Check if clicking on a port first
	var port := _find_port_at(world_pos)
	if port and port.direction == Port.Direction.OUTPUT:
		_start_wire(port, world_pos)
		return

	# Check if clicking on a port to disconnect
	if port and port.direction == Port.Direction.INPUT and port.connected_to != null:
		_disconnect_wire_at(port)
		return

	# Check if clicking on a component
	var component := _find_component_at(world_pos)
	if component:
		select_component(component)
		_mode = InteractionMode.DRAGGING_COMPONENT
		_dragging_component = component
		_drag_offset = component.position - world_pos
		return

	# Clicked empty space — deselect and start panning
	deselect()
	_mode = InteractionMode.PANNING
	_pan_start = get_viewport().get_mouse_position()
	_camera_start = camera.position


func _on_left_release(world_pos: Vector2) -> void:
	match _mode:
		InteractionMode.DRAGGING_COMPONENT:
			if _dragging_component and snap_enabled:
				_dragging_component.position = _snap_to_grid(_dragging_component.position)
			_dragging_component = null
			_mode = InteractionMode.NONE

		InteractionMode.CREATING_WIRE:
			_finish_wire(world_pos)

		InteractionMode.PANNING:
			_mode = InteractionMode.NONE

		_:
			_mode = InteractionMode.NONE


func _on_right_press(world_pos: Vector2) -> void:
	if SimulationManager.is_playing():
		return

	var component := _find_component_at(world_pos)
	if component:
		remove_component(component)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	var world_pos: Vector2 = _get_world_mouse()

	match _mode:
		InteractionMode.DRAGGING_COMPONENT:
			if _dragging_component:
				_dragging_component.position = world_pos + _drag_offset

		InteractionMode.CREATING_WIRE:
			_update_wire_preview(world_pos)
			# Hover feedback on nearby compatible ports
			_update_port_hover(world_pos)

		InteractionMode.PANNING:
			var delta: Vector2 = event.global_position - _pan_start
			camera.position = _camera_start - delta / _zoom_level


## Wire creation
func _start_wire(port: Port, _world_pos: Vector2) -> void:
	_mode = InteractionMode.CREATING_WIRE
	_wire_source_port = port

	_wire_preview = Line2D.new()
	_wire_preview.width = 2.5
	_wire_preview.default_color = port.get_color().lightened(0.2)
	_wire_preview.add_point(port.global_position)
	_wire_preview.add_point(port.global_position)
	wire_layer.add_child(_wire_preview)


func _update_wire_preview(world_pos: Vector2) -> void:
	if _wire_preview and _wire_preview.get_point_count() >= 2:
		_wire_preview.set_point_position(0, _wire_source_port.global_position)
		_wire_preview.set_point_position(1, world_pos)


func _finish_wire(world_pos: Vector2) -> void:
	# Clean up preview
	if _wire_preview:
		_wire_preview.queue_free()
		_wire_preview = null

	# Check if released on a compatible port
	var target_port := _find_port_at(world_pos)
	if target_port and _wire_source_port.can_connect_to(target_port):
		_create_wire(_wire_source_port, target_port)

	_clear_port_hover()
	_wire_source_port = null
	_mode = InteractionMode.NONE


func _create_wire(source: Port, target: Port) -> void:
	if not graph.connect_ports(source, target):
		return

	var wire := Wire.new()
	wire.setup(source, target)
	wire_layer.add_child(wire)
	wire_created.emit(wire)


func _disconnect_wire_at(port: Port) -> void:
	# Find and remove the wire visual
	for child in wire_layer.get_children():
		if child is Wire:
			if child.target_port == port or child.source_port == port:
				var source: Port = child.source_port
				graph.disconnect_ports(source)
				child.queue_free()
				break


func _remove_wires_for(component: MachineComponent) -> void:
	var to_remove: Array[Wire] = []
	for child in wire_layer.get_children():
		if child is Wire:
			if (child.source_port and child.source_port.owner_component == component) or \
			   (child.target_port and child.target_port.owner_component == component):
				to_remove.append(child)
	for wire in to_remove:
		wire.queue_free()


## Port hover feedback during wire creation
func _update_port_hover(world_pos: Vector2) -> void:
	_clear_port_hover()
	if _wire_source_port == null:
		return

	for comp: MachineComponent in graph.get_components():
		for port in comp.get_all_ports():
			if _wire_source_port.can_connect_to(port):
				var dist: float = world_pos.distance_to(port.global_position)
				if dist < 24.0:
					port.set_hover(true)


func _clear_port_hover() -> void:
	for comp: MachineComponent in graph.get_components():
		for port in comp.get_all_ports():
			port.set_hover(false)


## Find component at world position
func _find_component_at(world_pos: Vector2) -> MachineComponent:
	# Check in reverse order (topmost first)
	var children: Array[Node] = component_layer.get_children()
	for i in range(children.size() - 1, -1, -1):
		var child: Node = children[i]
		if child is MachineComponent and child.hit_test(world_pos):
			return child
	return null


## Find port at world position
func _find_port_at(world_pos: Vector2, threshold: float = 24.0) -> Port:
	var best_port: Port = null
	var best_dist: float = threshold

	for comp: MachineComponent in graph.get_components():
		var port: Port = comp.get_port_at(world_pos, threshold)
		if port:
			var dist: float = world_pos.distance_to(port.global_position)
			if dist < best_dist:
				best_dist = dist
				best_port = port
	return best_port


## Camera zoom
func _zoom(delta: float) -> void:
	_zoom_level = clampf(_zoom_level + delta, MIN_ZOOM, MAX_ZOOM)
	camera.zoom = Vector2(_zoom_level, _zoom_level)


## Get mouse position in world coordinates
func _get_world_mouse() -> Vector2:
	return get_global_mouse_position()


## Snap position to grid
func _snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		roundf(pos.x / grid_size) * grid_size,
		roundf(pos.y / grid_size) * grid_size,
	)


func _on_component_clicked(component: MachineComponent) -> void:
	select_component(component)


func _on_simulation_stopped() -> void:
	# Clean up any spawned physics objects
	for child in component_layer.get_children():
		if child is RigidBody2D:
			child.queue_free()
	# Also clean up balls spawned by pipes (they're added to component_layer)
	for comp: MachineComponent in graph.get_components():
		comp.reset_component()

	# Deactivate wire animations
	for child in wire_layer.get_children():
		if child is Wire:
			child.set_active(false)


## Activate wire animations when simulation starts
func _on_simulation_started() -> void:
	for child in wire_layer.get_children():
		if child is Wire:
			child.set_active(true)
