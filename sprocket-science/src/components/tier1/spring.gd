class_name Spring
extends MachineComponent

## Stores and releases energy on compression. Bounces RigidBody2D.
## Input: Energy. Output: Energy. Parameters: stiffness, compression.

const SPRING_WIDTH: float = 32.0
const SPRING_HEIGHT: float = 60.0
const SPRING_COLOR := Color(0.4, 0.6, 0.3)
const SPRING_ACCENT := Color(0.6, 0.9, 0.4)
const BASE_BOUNCE: float = 500.0

var _body: StaticBody2D
var _bounce_area: Area2D
var _stored_energy: float = 0.0
var _compress_anim: float = 0.0


func _setup_ports() -> void:
	add_port("energy_in", Port.PortType.ENERGY, Port.Direction.INPUT, Vector2(-SPRING_WIDTH / 2.0 - 12, 0))
	add_port("energy_out", Port.PortType.ENERGY, Port.Direction.OUTPUT, Vector2(SPRING_WIDTH / 2.0 + 12, 0))


func _setup_parameters() -> void:
	register_parameter("stiffness", "Stiffness", 50.0, 10.0, 100.0, 1.0)
	register_parameter("compression", "Compression", 0.5, 0.0, 1.0, 0.05)

	_body = StaticBody2D.new()
	add_child(_body)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(SPRING_WIDTH, 8)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, SPRING_HEIGHT / 2.0)
	_body.add_child(col)

	_bounce_area = Area2D.new()
	_bounce_area.collision_layer = 0
	_bounce_area.collision_mask = 1
	add_child(_bounce_area)
	var area_shape := RectangleShape2D.new()
	area_shape.size = Vector2(SPRING_WIDTH + 8, SPRING_HEIGHT)
	var area_col := CollisionShape2D.new()
	area_col.shape = area_shape
	_bounce_area.add_child(area_col)


func _on_input_received(_port: Port, data: Variant) -> void:
	if data is Dictionary:
		_stored_energy = clampf(_stored_energy + data.get("energy", 0.0), 0.0, 1.0)


func _process_component(delta: float) -> void:
	var stiffness: float = get_parameter("stiffness")
	var compression: float = get_parameter("compression")

	# Bounce bodies that enter the spring area
	var bounce_force: float = BASE_BOUNCE * (stiffness / 100.0) * (1.0 + _stored_energy)
	var bodies: Array[Node2D] = _bounce_area.get_overlapping_bodies()
	for body in bodies:
		if body is RigidBody2D:
			var dir := Vector2.UP.rotated(global_rotation)
			body.apply_central_impulse(dir * bounce_force * delta * 10.0)
			_compress_anim = 1.0

	# Animate compression
	_compress_anim = move_toward(_compress_anim, 0.0, delta * 3.0)

	# Release stored energy
	if _stored_energy > 0.01:
		send_output("energy_out", {"energy": _stored_energy * 0.5})
		_stored_energy *= 0.95

	queue_redraw()


func reset_component() -> void:
	super.reset_component()
	_stored_energy = 0.0
	_compress_anim = 0.0
	queue_redraw()


func _draw_component() -> void:
	var half_w: float = SPRING_WIDTH / 2.0
	var compress: float = _compress_anim * 0.3
	var height: float = SPRING_HEIGHT * (1.0 - compress)

	# Base plate
	draw_rect(Rect2(-half_w - 4, height / 2.0 - 4, SPRING_WIDTH + 8, 8), SPRING_COLOR.darkened(0.3), true)

	# Spring coils
	var coil_count: int = 6
	for i in range(coil_count):
		var t: float = float(i) / float(coil_count)
		var next_t: float = float(i + 1) / float(coil_count)
		var y1: float = lerpf(-height / 2.0, height / 2.0 - 4, t)
		var y2: float = lerpf(-height / 2.0, height / 2.0 - 4, next_t)
		var x1: float = half_w * 0.8 * (1.0 if i % 2 == 0 else -1.0)
		var x2: float = half_w * 0.8 * (1.0 if (i + 1) % 2 == 0 else -1.0)
		var coil_color: Color = SPRING_ACCENT if _stored_energy > 0.1 else SPRING_COLOR
		draw_line(Vector2(x1, y1), Vector2(x2, y2), coil_color, 2.5)

	# Top plate
	draw_rect(Rect2(-half_w - 2, -height / 2.0 - 4, SPRING_WIDTH + 4, 6), SPRING_COLOR, true)

	# Energy glow
	if _stored_energy > 0.1:
		var glow_alpha: float = _stored_energy * 0.3
		draw_circle(Vector2.ZERO, 12, Color(0.6, 1.0, 0.4, glow_alpha))

	draw_string(ThemeDB.fallback_font, Vector2(-16, -height / 2.0 - 10),
		"Spring", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	return Rect2(-SPRING_WIDTH / 2.0 - 12, -SPRING_HEIGHT / 2.0 - 16, SPRING_WIDTH + 24, SPRING_HEIGHT + 32)


func _get_component_type() -> String:
	return "spring"
