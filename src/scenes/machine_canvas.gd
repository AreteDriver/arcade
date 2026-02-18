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

## Trace mode — highlights flow paths from selected component
var trace_enabled: bool = false

## Restriction flags for Discovery Mode (default permissive = sandbox)
var allow_placement: bool = true
var allow_wiring: bool = true
var allow_parameter_edit: bool = true
var allow_removal: bool = true
var allowed_component_types: Array[String] = []
var locked_component_ids: Array[String] = []


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

	# Juice: pop scale animation + placement sound
	VFX.pop_scale(component)
	Audio.play_place()

	return component


## Start placing a component from tray click.
## Places at canvas center, enters click-to-place mode (follows cursor until clicked).
func start_placing(type_name: String) -> void:
	if SimulationManager.is_playing():
		return
	if not allow_placement:
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

	# Juice: shrink + smoke puff + delete sound instead of instant free
	VFX.spawn_smoke(component.global_position, component_layer)
	VFX.shrink_and_free(component)
	Audio.play_delete()


## Select a component and show its parameters
func select_component(component: MachineComponent) -> void:
	if _selected_component and _selected_component != component:
		_selected_component.set_selected(false)

	_selected_component = component
	component.set_selected(true)
	component_selected.emit(component)
	if trace_enabled:
		_update_trace_highlight()


## Deselect current component
func deselect() -> void:
	if _selected_component:
		_selected_component.set_selected(false)
		_selected_component = null
		component_deselected.emit()
	_clear_trace_highlight()


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
	if port and port.direction == Port.Direction.OUTPUT and allow_wiring:
		_start_wire(port, world_pos)
		return

	# Check if clicking on a port to disconnect
	if port and port.direction == Port.Direction.INPUT and port.connected_to != null and allow_wiring:
		_disconnect_wire_at(port)
		return

	# Check if clicking on a component
	var component := _find_component_at(world_pos)
	if component:
		select_component(component)
		if not _is_component_locked(component):
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
	if not allow_removal:
		return

	var component := _find_component_at(world_pos)
	if component and not _is_component_locked(component):
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

	# Juice: flash at both ports + connection sound
	VFX.connection_flash(source)
	VFX.connection_flash(target)
	Audio.play_connect()


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


## Zoom camera to fit all placed components
func zoom_to_fit() -> void:
	if graph.is_empty():
		camera.position = Vector2(640, 360)
		_zoom_level = 1.0
		camera.zoom = Vector2.ONE
		return

	var components: Array[MachineComponent] = graph.get_components()
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)

	for comp in components:
		var bounds: Rect2 = comp._get_bounds()
		var world_min: Vector2 = comp.global_position + bounds.position
		var world_max: Vector2 = comp.global_position + bounds.end
		min_pos = Vector2(minf(min_pos.x, world_min.x), minf(min_pos.y, world_min.y))
		max_pos = Vector2(maxf(max_pos.x, world_max.x), maxf(max_pos.y, world_max.y))

	var center := (min_pos + max_pos) / 2.0
	var extent := max_pos - min_pos + Vector2(100, 100)  # Padding
	var viewport_size := get_viewport_rect().size

	var zoom_x: float = viewport_size.x / extent.x if extent.x > 0 else 1.0
	var zoom_y: float = viewport_size.y / extent.y if extent.y > 0 else 1.0
	_zoom_level = clampf(minf(zoom_x, zoom_y), MIN_ZOOM, MAX_ZOOM)

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_parallel(true)
	tween.tween_property(camera, "position", center, 0.4)
	tween.tween_property(camera, "zoom", Vector2(_zoom_level, _zoom_level), 0.4)


## Trigger screen shake (called by VFX or game events)
func do_screen_shake(intensity: float = 5.0, duration: float = 0.3) -> void:
	VFX.screen_shake(camera, intensity, duration)


## Load a machine from a MachineDefinition resource.
## Creates components, sets positions/params, creates wires.
func load_machine(definition: MachineDefinition) -> void:
	clear_machine()

	var data: Dictionary = definition.machine_data
	if not data.has("components"):
		return

	# Phase 1: Create all components
	var comp_map: Dictionary = {}  # {id: MachineComponent}
	for comp_data: Dictionary in data["components"]:
		var type_name: String = comp_data.get("type", "")
		var comp_id: String = comp_data.get("id", "")
		if type_name.is_empty() or comp_id.is_empty():
			continue

		var component: MachineComponent = ComponentRegistry.create_component(type_name)
		if component == null:
			continue

		_component_counter += 1
		component.name = comp_id

		var pos_arr: Array = comp_data.get("position", [0, 0])
		component.position = Vector2(pos_arr[0], pos_arr[1])

		component_layer.add_child(component)
		graph.add_component(component)
		component.component_selected.connect(_on_component_clicked)

		# Set parameters
		var params: Dictionary = comp_data.get("parameters", {})
		for param_name in params:
			component.set_parameter(param_name, params[param_name])

		comp_map[comp_id] = component

	# Phase 2: Create wires from connection data
	for comp_data: Dictionary in data["components"]:
		var comp_id: String = comp_data.get("id", "")
		var source_comp: MachineComponent = comp_map.get(comp_id)
		if source_comp == null:
			continue

		for conn: Dictionary in comp_data.get("connections", []):
			var from_port_name: String = conn.get("from_port", "")
			var target_id: String = conn.get("to", "")
			var to_port_name: String = conn.get("to_port", "")

			var target_comp: MachineComponent = comp_map.get(target_id)
			if target_comp == null:
				continue

			var source_port: Port = source_comp.get_port(from_port_name)
			var target_port: Port = target_comp.get_port(to_port_name)
			if source_port and target_port and source_port.can_connect_to(target_port):
				_create_wire(source_port, target_port)

	# Apply restriction flags from definition
	locked_component_ids = definition.locked_component_ids.duplicate()


## Remove all components and wires from the canvas
func clear_machine() -> void:
	deselect()

	# Remove all wires
	for child in wire_layer.get_children():
		child.queue_free()

	# Remove all components
	for child in component_layer.get_children():
		if child is MachineComponent:
			graph.remove_component(child)
			child.queue_free()
		elif child is RigidBody2D:
			child.queue_free()

	graph.clear()
	_component_counter = 0


## Reset all restriction flags to permissive (sandbox mode)
func reset_restrictions() -> void:
	allow_placement = true
	allow_wiring = true
	allow_parameter_edit = true
	allow_removal = true
	allowed_component_types.clear()
	locked_component_ids.clear()


## Check if a component is locked (cannot be moved/deleted)
func _is_component_locked(component: MachineComponent) -> bool:
	return component.name in locked_component_ids


## Spawn a test object (ball or block) at a world position
func spawn_test_object(object_type: String, world_pos: Vector2) -> void:
	var body: RigidBody2D
	match object_type:
		"ball":
			body = TestBall.new()
		"block":
			body = TestBlock.new()
		_:
			return

	body.position = world_pos
	component_layer.add_child(body)

	# Juice: pop + sound
	VFX.pop_scale(body)
	Audio.play_place()


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

	# Juice: activation wave — flash each component in topological order
	Audio.play_start()
	var order: Array[MachineComponent] = graph.get_evaluation_order()
	for i in range(order.size()):
		var comp: MachineComponent = order[i]
		# Staggered glow
		get_tree().create_timer(i * 0.08).timeout.connect(
			func() -> void:
				if is_instance_valid(comp):
					VFX.glow(comp, Color(1.4, 1.4, 1.6), 0.3)
		)


## Set trace mode on/off
func set_trace_enabled(enabled: bool) -> void:
	trace_enabled = enabled
	if trace_enabled and _selected_component:
		_update_trace_highlight()
	else:
		_clear_trace_highlight()


## Highlight all wires and components downstream from the selected component
func _update_trace_highlight() -> void:
	_clear_trace_highlight()
	if _selected_component == null:
		return

	# Collect all downstream component names via BFS
	var visited: Dictionary = {}
	var queue: Array[String] = [_selected_component.name]
	visited[_selected_component.name] = true

	while queue.size() > 0:
		var current: String = queue.pop_front()
		if current in graph._connections:
			for conn: Dictionary in graph._connections[current]:
				var target: String = conn["target_name"]
				if target not in visited:
					visited[target] = true
					queue.append(target)

	# Highlight downstream wires
	for child in wire_layer.get_children():
		if child is Wire and child.source_port:
			var source_name: String = child.source_port.owner_component.name
			if source_name in visited:
				child.set_meta("trace_highlighted", true)
				child.width = 5.0
				child.default_color = child.source_port.get_color().lightened(0.3)

	# Dim non-traced components, brighten traced ones
	for comp: MachineComponent in graph.get_components():
		if comp.name in visited:
			comp.modulate = Color(1.2, 1.2, 1.3)
		else:
			comp.modulate = Color(0.4, 0.4, 0.45)


## Remove all trace highlighting
func _clear_trace_highlight() -> void:
	for child in wire_layer.get_children():
		if child is Wire and child.has_meta("trace_highlighted"):
			child.remove_meta("trace_highlighted")
			child.set_active(child._active)

	for comp: MachineComponent in graph.get_components():
		comp.modulate = Color.WHITE
		if comp.current_state != MachineComponent.State.IDLE:
			# Re-apply state modulation
			comp.set_state(comp.current_state)
