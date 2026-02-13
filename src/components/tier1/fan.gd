class_name Fan
extends MachineComponent

## Blows objects with wind force via Area2D.
## Self-powered in Phase 1 (works without energy input).
## Input: Energy. Parameters: angle (rotates fan), speed (wind force).
## Rotate via the "angle" parameter (handled by base class Node2D rotation).
## Wind always blows in the fan's facing direction (local X+).

const FAN_SIZE: float = 48.0
const WIND_RANGE: float = 200.0
const WIND_WIDTH: float = 100.0
const BASE_FORCE: float = 300.0
const FAN_COLOR := Color(0.5, 0.5, 0.6)
const FAN_ACCENT := Color(0.9, 0.8, 0.2)

var _body: StaticBody2D
var _wind_area: Area2D
var _wind_collision: CollisionShape2D
var _blade_angle: float = 0.0
var _energy_received: bool = false


func _setup_ports() -> void:
	add_port("energy_in", Port.PortType.ENERGY, Port.Direction.INPUT, Vector2(-FAN_SIZE / 2.0 - 12, 0))


func _setup_parameters() -> void:
	register_parameter("angle", "Angle", 0.0, 0.0, 360.0, 5.0)
	register_parameter("speed", "Speed", 50.0, 0.0, 100.0, 1.0)

	# Static body for the fan housing
	_body = StaticBody2D.new()
	add_child(_body)
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(FAN_SIZE, FAN_SIZE)
	var body_col := CollisionShape2D.new()
	body_col.shape = body_shape
	_body.add_child(body_col)

	# Wind area in local space — always points right (local X+)
	# Node2D rotation handles the actual direction
	_wind_area = Area2D.new()
	_wind_area.collision_layer = 0
	_wind_area.collision_mask = 1
	add_child(_wind_area)

	var wind_shape := RectangleShape2D.new()
	wind_shape.size = Vector2(WIND_RANGE, WIND_WIDTH)
	_wind_collision = CollisionShape2D.new()
	_wind_collision.shape = wind_shape
	_wind_collision.position = Vector2(WIND_RANGE / 2.0 + FAN_SIZE / 2.0, 0)
	_wind_area.add_child(_wind_collision)


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

	# Wind blows in the fan's forward direction (local X+ → global via rotation)
	var force_dir := Vector2.RIGHT.rotated(global_rotation)
	var force_magnitude: float = BASE_FORCE * (speed / 100.0)

	var bodies: Array[Node2D] = _wind_area.get_overlapping_bodies()
	for body in bodies:
		if body is RigidBody2D:
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

	# Housing — draw flat, Node2D rotation handles angle
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
		var speed_norm: float = get_parameter("speed") / 100.0
		var wind_alpha: float = 0.05 + speed_norm * 0.12

		# Wind lines always point right (local space), Node2D rotation handles direction
		for i in range(5):
			var offset_y: float = lerpf(-WIND_WIDTH / 2.0 + 10, WIND_WIDTH / 2.0 - 10, float(i) / 4.0)
			var start := Vector2(half + 8, offset_y)
			var end := Vector2(half + 8 + WIND_RANGE * speed_norm * 0.6, offset_y)
			draw_line(start, end, Color(0.4, 0.7, 1.0, wind_alpha), 1.5)

	# Label
	draw_string(ThemeDB.fallback_font, Vector2(-10, -half - 8),
		"Fan", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	var half := FAN_SIZE / 2.0
	return Rect2(-half - 16, -half - 20, FAN_SIZE + 32, FAN_SIZE + 40)


func _get_component_type() -> String:
	return "fan"
