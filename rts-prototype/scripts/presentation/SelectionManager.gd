extends Node
class_name SelectionManager
## SelectionManager.gd - Handles unit selection via click and box drag
## Manages selected units and interfaces with CommandBus.

signal selection_changed(selected_squads: Array[Node3D])
signal box_selection_started
signal box_selection_ended

@export var camera: Camera3D
@export var selection_box_ui: Control

var selected_squads: Array[Node3D] = []
var control_groups: Dictionary = {}  # int -> Array[Node3D]

var _is_box_selecting: bool = false
var _box_start_screen: Vector2
var _box_current_screen: Vector2

# Selection box visual
var _selection_box_rect: ColorRect


func _ready() -> void:
	_setup_selection_box()

	# Initialize control groups
	for i in range(1, 4):
		control_groups[i] = []


func _setup_selection_box() -> void:
	_selection_box_rect = ColorRect.new()
	_selection_box_rect.color = Color(0.2, 0.8, 0.2, 0.3)
	_selection_box_rect.visible = false

	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	canvas.add_child(_selection_box_rect)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventKey:
		_handle_key_input(event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_selection(event.position)
		else:
			_end_selection(event.position)

	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_issue_context_command(event.position)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _is_box_selecting:
		_box_current_screen = event.position
		_update_selection_box_visual()


func _handle_key_input(event: InputEventKey) -> void:
	if not event.pressed:
		return

	# Control groups
	if event.is_action_pressed("control_group_1"):
		_handle_control_group(1, event.ctrl_pressed)
	elif event.is_action_pressed("control_group_2"):
		_handle_control_group(2, event.ctrl_pressed)
	elif event.is_action_pressed("control_group_3"):
		_handle_control_group(3, event.ctrl_pressed)

	# Jump to selection
	elif event.is_action_pressed("jump_to_selection"):
		_jump_camera_to_selection()


func _start_selection(screen_pos: Vector2) -> void:
	_is_box_selecting = true
	_box_start_screen = screen_pos
	_box_current_screen = screen_pos
	_selection_box_rect.visible = true
	box_selection_started.emit()


func _end_selection(screen_pos: Vector2) -> void:
	_box_current_screen = screen_pos
	_is_box_selecting = false
	_selection_box_rect.visible = false
	box_selection_ended.emit()

	var box_size := (_box_current_screen - _box_start_screen).abs()

	if box_size.length() < 5:
		# Click selection
		_do_click_selection(screen_pos)
	else:
		# Box selection
		_do_box_selection()


func _do_click_selection(screen_pos: Vector2) -> void:
	var clicked_squad := _raycast_for_squad(screen_pos)
	var multi_select := Input.is_action_pressed("multi_select")

	if clicked_squad:
		if clicked_squad.team != GameState.Team.PLAYER:
			# Clicked enemy, don't select
			return

		if multi_select:
			# Toggle selection
			if clicked_squad in selected_squads:
				_deselect_squad(clicked_squad)
			else:
				_select_squad(clicked_squad)
		else:
			# Single select
			_clear_selection()
			_select_squad(clicked_squad)
	else:
		if not multi_select:
			_clear_selection()


func _do_box_selection() -> void:
	var multi_select := Input.is_action_pressed("multi_select")

	if not multi_select:
		_clear_selection()

	# Get all player squads
	var player_squads := GameState.get_squads_for_team(GameState.Team.PLAYER)

	# Check which are in the box
	var box_min := Vector2(
		minf(_box_start_screen.x, _box_current_screen.x),
		minf(_box_start_screen.y, _box_current_screen.y)
	)
	var box_max := Vector2(
		maxf(_box_start_screen.x, _box_current_screen.x),
		maxf(_box_start_screen.y, _box_current_screen.y)
	)

	for squad in player_squads:
		if not is_instance_valid(squad):
			continue

		var screen_pos := camera.unproject_position(squad.global_position)

		if screen_pos.x >= box_min.x and screen_pos.x <= box_max.x and \
		   screen_pos.y >= box_min.y and screen_pos.y <= box_max.y:
			_select_squad(squad)


func _raycast_for_squad(screen_pos: Vector2) -> Node3D:
	if not camera:
		return null

	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 1000.0

	var space_state := camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2  # Units layer

	var result := space_state.intersect_ray(query)

	if result and result.collider:
		var collider := result.collider
		if collider is Squad:
			return collider
		elif collider.get_parent() is Squad:
			return collider.get_parent()

	return null


func _raycast_for_capture_point(screen_pos: Vector2) -> CapturePoint:
	if not camera:
		return null

	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 1000.0

	var space_state := camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 8  # Capture zones layer

	var result := space_state.intersect_ray(query)

	if result and result.collider:
		if result.collider is CapturePoint:
			return result.collider

	return null


func _issue_context_command(screen_pos: Vector2) -> void:
	if selected_squads.is_empty():
		return

	# Check for enemy target
	var target_squad := _raycast_for_squad(screen_pos)
	if target_squad and target_squad.team != GameState.Team.PLAYER:
		CommandBus.issue_attack(selected_squads, target_squad)
		return

	# Check for capture point
	var capture_point := _raycast_for_capture_point(screen_pos)
	if capture_point:
		CommandBus.issue_capture(selected_squads, capture_point)
		return

	# Default: move command
	var ground_pos := camera.get_ground_position(screen_pos) if camera.has_method("get_ground_position") else _get_ground_position_fallback(screen_pos)
	CommandBus.issue_move(selected_squads, ground_pos)


func _get_ground_position_fallback(screen_pos: Vector2) -> Vector3:
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)

	if abs(dir.y) < 0.001:
		return Vector3.ZERO

	var t := -from.y / dir.y
	return from + dir * t


func _select_squad(squad: Node3D) -> void:
	if squad not in selected_squads:
		selected_squads.append(squad)
		squad.set_selected(true)
		selection_changed.emit(selected_squads)


func _deselect_squad(squad: Node3D) -> void:
	var idx := selected_squads.find(squad)
	if idx >= 0:
		selected_squads.remove_at(idx)
		squad.set_selected(false)
		selection_changed.emit(selected_squads)


func _clear_selection() -> void:
	for squad in selected_squads:
		if is_instance_valid(squad):
			squad.set_selected(false)
	selected_squads.clear()
	selection_changed.emit(selected_squads)


func _update_selection_box_visual() -> void:
	var min_pos := Vector2(
		minf(_box_start_screen.x, _box_current_screen.x),
		minf(_box_start_screen.y, _box_current_screen.y)
	)
	var max_pos := Vector2(
		maxf(_box_start_screen.x, _box_current_screen.x),
		maxf(_box_start_screen.y, _box_current_screen.y)
	)

	_selection_box_rect.position = min_pos
	_selection_box_rect.size = max_pos - min_pos


func _handle_control_group(group_num: int, is_assigning: bool) -> void:
	if is_assigning:
		# Assign current selection to control group
		control_groups[group_num] = selected_squads.duplicate()
	else:
		# Recall control group
		var group: Array = control_groups.get(group_num, [])
		_clear_selection()
		for squad in group:
			if is_instance_valid(squad):
				_select_squad(squad)


func _jump_camera_to_selection() -> void:
	if selected_squads.is_empty():
		return

	# Calculate center of selection
	var center := Vector3.ZERO
	var count := 0

	for squad in selected_squads:
		if is_instance_valid(squad):
			center += squad.global_position
			count += 1

	if count > 0:
		center /= count
		if camera.has_method("jump_to_position"):
			camera.jump_to_position(center)


func get_selected_squads() -> Array[Node3D]:
	# Clean invalid references
	selected_squads = selected_squads.filter(func(s): return is_instance_valid(s))
	return selected_squads


func select_all_player_squads() -> void:
	_clear_selection()
	for squad in GameState.get_squads_for_team(GameState.Team.PLAYER):
		if is_instance_valid(squad):
			_select_squad(squad)
