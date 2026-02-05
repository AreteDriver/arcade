extends Camera3D
class_name RTSCamera
## RTSCamera.gd - RTS camera with pan, zoom, and rotate
## Handles all camera controls for top-down RTS view.

signal camera_moved(position: Vector3)

@export var pan_speed: float = 30.0
@export var zoom_speed: float = 5.0
@export var rotate_speed: float = 2.0
@export var edge_pan_margin: int = 20
@export var edge_pan_enabled: bool = true

@export var min_zoom: float = 15.0
@export var max_zoom: float = 60.0
@export var initial_zoom: float = 35.0

@export var min_pitch: float = -80.0
@export var max_pitch: float = -45.0

# Map bounds (set by map scene)
var map_bounds_min: Vector3 = Vector3(-100, 0, -100)
var map_bounds_max: Vector3 = Vector3(100, 0, 100)

var _pivot: Node3D
var _current_zoom: float
var _target_zoom: float


func _ready() -> void:
	# Create pivot point for camera rotation
	_pivot = Node3D.new()
	_pivot.name = "CameraPivot"

	var parent := get_parent()
	var my_transform := global_transform

	parent.remove_child(self)
	parent.add_child(_pivot)
	_pivot.add_child(self)

	_pivot.global_position = Vector3(0, 0, 0)
	_pivot.rotation.x = deg_to_rad(-60)

	_current_zoom = initial_zoom
	_target_zoom = initial_zoom
	position = Vector3(0, 0, _current_zoom)

	# Look at ground
	rotation = Vector3.ZERO


func _process(delta: float) -> void:
	_handle_pan_input(delta)
	_handle_rotation_input(delta)
	_handle_zoom_input(delta)
	_apply_zoom(delta)
	_clamp_to_bounds()


func _handle_pan_input(delta: float) -> void:
	var pan_dir := Vector3.ZERO

	# Keyboard pan
	if Input.is_action_pressed("camera_pan_up"):
		pan_dir.z -= 1
	if Input.is_action_pressed("camera_pan_down"):
		pan_dir.z += 1
	if Input.is_action_pressed("camera_pan_left"):
		pan_dir.x -= 1
	if Input.is_action_pressed("camera_pan_right"):
		pan_dir.x += 1

	# Edge pan
	if edge_pan_enabled:
		var mouse_pos := get_viewport().get_mouse_position()
		var viewport_size := get_viewport().get_visible_rect().size

		if mouse_pos.x < edge_pan_margin:
			pan_dir.x -= 1
		elif mouse_pos.x > viewport_size.x - edge_pan_margin:
			pan_dir.x += 1

		if mouse_pos.y < edge_pan_margin:
			pan_dir.z -= 1
		elif mouse_pos.y > viewport_size.y - edge_pan_margin:
			pan_dir.z += 1

	if pan_dir.length() > 0:
		pan_dir = pan_dir.normalized()

		# Transform pan direction based on camera rotation
		var basis := _pivot.global_transform.basis
		var forward := -basis.z
		forward.y = 0
		forward = forward.normalized()
		var right := basis.x
		right.y = 0
		right = right.normalized()

		var move := (forward * -pan_dir.z + right * pan_dir.x) * pan_speed * delta

		# Adjust speed based on zoom level
		var zoom_factor := _current_zoom / initial_zoom
		move *= zoom_factor

		_pivot.global_position += move
		camera_moved.emit(_pivot.global_position)


func _handle_rotation_input(delta: float) -> void:
	if Input.is_action_pressed("camera_rotate_left"):
		_pivot.rotation.y += rotate_speed * delta
	if Input.is_action_pressed("camera_rotate_right"):
		_pivot.rotation.y -= rotate_speed * delta


func _handle_zoom_input(_delta: float) -> void:
	if Input.is_action_just_pressed("camera_zoom_in"):
		_target_zoom = maxf(min_zoom, _target_zoom - zoom_speed)
	if Input.is_action_just_pressed("camera_zoom_out"):
		_target_zoom = minf(max_zoom, _target_zoom + zoom_speed)


func _apply_zoom(delta: float) -> void:
	_current_zoom = lerpf(_current_zoom, _target_zoom, delta * 10.0)
	position.z = _current_zoom


func _clamp_to_bounds() -> void:
	_pivot.global_position.x = clampf(_pivot.global_position.x, map_bounds_min.x, map_bounds_max.x)
	_pivot.global_position.z = clampf(_pivot.global_position.z, map_bounds_min.z, map_bounds_max.z)
	_pivot.global_position.y = 0


func jump_to_position(target: Vector3) -> void:
	_pivot.global_position = Vector3(target.x, 0, target.z)
	_clamp_to_bounds()
	camera_moved.emit(_pivot.global_position)


func get_ground_position(screen_pos: Vector2) -> Vector3:
	var from := project_ray_origin(screen_pos)
	var dir := project_ray_normal(screen_pos)

	# Intersect with ground plane (y = 0)
	if abs(dir.y) < 0.001:
		return Vector3.ZERO

	var t := -from.y / dir.y
	if t < 0:
		return Vector3.ZERO

	return from + dir * t


func get_camera_position() -> Vector3:
	return _pivot.global_position if _pivot else global_position


func set_map_bounds(min_pos: Vector3, max_pos: Vector3) -> void:
	map_bounds_min = min_pos
	map_bounds_max = max_pos
