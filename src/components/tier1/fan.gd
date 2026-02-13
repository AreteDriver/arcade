class_name Fan
extends MachineComponent

## Blows objects with wind force via Area2D.
## Self-powered in Phase 1 (works without energy input).
## Input: Energy. Parameters: speed (0-100), direction (0-360).

const FAN_SIZE: float = 48.0
const WIND_RANGE: float = 200.0
const WIND_WIDTH: float = 100.0
const BASE_FORCE: float = 300.0
const FAN_COLOR := Color(0.5, 0.5, 0.6)
const FAN_ACCENT := Color(0.9, 0.8, 0.2)
const WIND_COLOR := Color(0.4, 0.7, 1.0, 0.15)

var _body: StaticBody2D
var _wind_area: Area2D
var _wind_collision: CollisionShape2D
var _blade_angle: float = 0.0
var _energy_received: bool = false


func _setup_ports() -> void:
	add_port("energy_in", Port.PortType.ENERGY, Port.Direction.INPUT, Vector2(-FAN_SIZE / 2.0 - 12, 0))


func _setup_parameters() -> void:
	register_parameter("speed", "Speed", 50.0, 0.0, 100.0, 1.0)
	register_parameter("direction", "Direction", 0.0, 0.0, 360.0, 5.0)

	# Static body for the fan housing
	_body = StaticBody2D.new()
	add_child(_body)
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(FAN_SIZE, FAN_SIZE)
	var body_col := CollisionShape2D.new()
	body_col.shape = body_shape
	_body.add_child(body_col)

	# Wind area
	_wind_area = Area2D.new()
	_wind_area.collision_layer = 0
	_wind_area.collision_mask = 1  # Detect physics objects on layer 1
	add_child(_wind_area)

	_rebuild_wind_area()


func _rebuild_wind_area() -> void:
	if _wind_collision:
		_wind_collision.queue_free()

	var wind_shape := RectangleShape2D.new()
	wind_shape.size = Vector2(WIND_RANGE, WIND_WIDTH)
	_wind_collision = CollisionShape2D.new()
	_wind_collision.shape = wind_shape
	_wind_collision.position = Vector2(WIND_RANGE / 2.0 + FAN_SIZE / 2.0, 0)
	_wind_area.add_child(_wind_collision)

	_apply_direction(get_parameter("direction"))


func _on_parameter_changed(param_name: String, value: float) -> void:
	match param_name:
		"direction":
			_apply_direction(value)
		"speed":
			pass  # Force magnitude computed dynamically


func _apply_direction(degrees: float) -> void:
	var rad: float = deg_to_rad(degrees)
	_wind_area.rotation = rad


func _on_input_received(_port: Port, _data: Variant) -> void:
	_energy_received = true


func _process_component(delta: float) -> void:
	var speed: float = get_parameter("speed")
	if speed <= 0:
		return

	# Spin blades
	_blade_angle += speed * 8.0 * delta
	if _blade_angle > 360.0:
		_blade_angle -= 360.0
	queue_redraw()

	# Apply wind force to bodies in the area
	var dir_rad: float = deg_to_rad(get_parameter("direction"))
	var force_dir := Vector2.RIGHT.rotated(dir_rad)
	var force_magnitude: float = BASE_FORCE * (speed / 100.0)

	var bodies: Array[Node2D] = _wind_area.get_overlapping_bodies()
	for body in bodies:
		if body is RigidBody2D:
			# Force falls off with distance
			var dist: float = body.global_position.distance_to(global_position)
			var falloff: float = 1.0 - clampf(dist / (WIND_RANGE + FAN_SIZE), 0.0, 1.0)
			body.apply_central_force(force_dir * force_magnitude * falloff)


func reset_component() -> void:
	super.reset_component()
	_blade_angle = 0.0
	_energy_received = false
	queue_redraw()


func _draw_component() -> void:
	var half := FAN_SIZE / 2.0

	# Housing
	draw_rect(Rect2(-half, -half, FAN_SIZE, FAN_SIZE), FAN_COLOR.darkened(0.3), true)
	draw_rect(Rect2(-half, -half, FAN_SIZE, FAN_SIZE), FAN_COLOR, false, 2.0)

	# Circular fan center
	draw_circle(Vector2.ZERO, half * 0.65, FAN_COLOR.darkened(0.2))
	draw_arc(Vector2.ZERO, half * 0.65, 0, TAU, 32, FAN_ACCENT, 1.5)

	# Fan blades (4 blades, rotating)
	var blade_len: float = half * 0.55
	var blade_rad: float = deg_to_rad(_blade_angle)
	for i in range(4):
		var angle: float = blade_rad + TAU * float(i) / 4.0
		var tip: Vector2 = Vector2.RIGHT.rotated(angle) * blade_len
		var perp: Vector2 = Vector2.RIGHT.rotated(angle + PI / 2.0) * 6.0
		var blade_points: PackedVector2Array = [
			Vector2.ZERO + perp * 0.3,
			tip + perp,
			tip - perp,
			Vector2.ZERO - perp * 0.3,
		]
		draw_colored_polygon(blade_points, FAN_ACCENT.darkened(0.1))

	# Center hub
	draw_circle(Vector2.ZERO, 5.0, FAN_COLOR)

	# Wind zone indicator (when active)
	if current_state == State.ACTIVE:
		var dir_rad: float = deg_to_rad(get_parameter("direction"))
		var speed_norm: float = get_parameter("speed") / 100.0
		var wind_alpha: float = 0.05 + speed_norm * 0.12

		# Draw wind lines
		for i in range(5):
			var offset_y: float = lerpf(-WIND_WIDTH / 2.0 + 10, WIND_WIDTH / 2.0 - 10, float(i) / 4.0)
			var start := Vector2(half + 8, offset_y).rotated(dir_rad)
			var end := Vector2(half + 8 + WIND_RANGE * speed_norm * 0.6, offset_y).rotated(dir_rad)
			draw_line(start, end, Color(WIND_COLOR.r, WIND_COLOR.g, WIND_COLOR.b, wind_alpha), 1.5)

	# Label
	draw_string(ThemeDB.fallback_font, Vector2(-10, -half - 8),
		"Fan", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	var half := FAN_SIZE / 2.0
	return Rect2(-half - 16, -half - 16, FAN_SIZE + 32, FAN_SIZE + 32)


func _get_component_type() -> String:
	return "fan"
