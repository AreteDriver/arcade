class_name Conveyor
extends MachineComponent

## Moving belt that pushes objects horizontally.
## Input: Energy. Output: Flow. Parameters: speed, angle.
## Area2D applies force to RigidBody2D on the belt surface.

const BELT_LENGTH: float = 140.0
const BELT_HEIGHT: float = 20.0
const BASE_SPEED: float = 200.0
const BELT_COLOR := Color(0.35, 0.35, 0.4)
const BELT_ACCENT := Color(0.6, 0.55, 0.2)
const ROLLER_COLOR := Color(0.5, 0.5, 0.55)

var _body: StaticBody2D
var _belt_area: Area2D
var _belt_offset: float = 0.0
var _energy_received: bool = false


func _setup_ports() -> void:
	add_port("energy_in", Port.PortType.ENERGY, Port.Direction.INPUT, Vector2(-BELT_LENGTH / 2.0 - 12, 0))
	add_port("flow_out", Port.PortType.FLOW, Port.Direction.OUTPUT, Vector2(BELT_LENGTH / 2.0 + 12, 0))


func _setup_parameters() -> void:
	register_parameter("angle", "Angle", 0.0, 0.0, 360.0, 5.0)
	register_parameter("speed", "Speed", 50.0, 0.0, 100.0, 1.0)

	# Static body for belt structure
	_body = StaticBody2D.new()
	add_child(_body)
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(BELT_LENGTH, BELT_HEIGHT)
	var body_col := CollisionShape2D.new()
	body_col.shape = body_shape
	_body.add_child(body_col)

	# Area2D on top surface to detect and push bodies
	_belt_area = Area2D.new()
	_belt_area.collision_layer = 0
	_belt_area.collision_mask = 1
	add_child(_belt_area)

	var area_shape := RectangleShape2D.new()
	area_shape.size = Vector2(BELT_LENGTH - 8, BELT_HEIGHT + 16)
	var area_col := CollisionShape2D.new()
	area_col.shape = area_shape
	area_col.position = Vector2(0, -BELT_HEIGHT / 2.0)
	_belt_area.add_child(area_col)


func _on_input_received(_port: Port, _data: Variant) -> void:
	_energy_received = true


func _process_component(delta: float) -> void:
	var speed: float = get_parameter("speed")
	if speed <= 0:
		return

	# Animate belt treads
	_belt_offset += speed * 1.5 * delta
	if _belt_offset > 20.0:
		_belt_offset -= 20.0
	queue_redraw()

	# Push bodies along belt direction (local X+)
	var push_dir := Vector2.RIGHT.rotated(global_rotation)
	var force_magnitude: float = BASE_SPEED * (speed / 100.0)

	var bodies: Array[Node2D] = _belt_area.get_overlapping_bodies()
	for body in bodies:
		if body is RigidBody2D:
			body.apply_central_force(push_dir * force_magnitude)

	send_output("flow_out", {"flow_rate": speed / 100.0})


func reset_component() -> void:
	super.reset_component()
	_belt_offset = 0.0
	_energy_received = false
	queue_redraw()


func _draw_component() -> void:
	var half_l: float = BELT_LENGTH / 2.0
	var half_h: float = BELT_HEIGHT / 2.0

	# Belt body
	draw_rect(Rect2(-half_l, -half_h, BELT_LENGTH, BELT_HEIGHT), BELT_COLOR.darkened(0.2), true)
	draw_rect(Rect2(-half_l, -half_h, BELT_LENGTH, BELT_HEIGHT), BELT_COLOR, false, 2.0)

	# Rollers at each end
	draw_circle(Vector2(-half_l + 8, 0), 8.0, ROLLER_COLOR)
	draw_circle(Vector2(half_l - 8, 0), 8.0, ROLLER_COLOR)
	draw_arc(Vector2(-half_l + 8, 0), 8.0, 0, TAU, 12, ROLLER_COLOR.lightened(0.3), 1.0)
	draw_arc(Vector2(half_l - 8, 0), 8.0, 0, TAU, 12, ROLLER_COLOR.lightened(0.3), 1.0)

	# Belt tread marks (animated)
	if current_state == State.ACTIVE:
		var tread_color := BELT_ACCENT
		tread_color.a = 0.5
		var tread_spacing: float = 20.0
		var start_x: float = -half_l + 16.0 + fmod(_belt_offset, tread_spacing)
		var x: float = start_x
		while x < half_l - 16.0:
			draw_line(Vector2(x, -half_h + 2), Vector2(x, half_h - 2), tread_color, 1.5)
			x += tread_spacing

	# Direction arrow
	var arrow_color := BELT_ACCENT if current_state == State.ACTIVE else BELT_COLOR.lightened(0.2)
	draw_line(Vector2(-10, 0), Vector2(10, 0), arrow_color, 2.0)
	draw_line(Vector2(6, -4), Vector2(10, 0), arrow_color, 2.0)
	draw_line(Vector2(6, 4), Vector2(10, 0), arrow_color, 2.0)

	# Label
	draw_string(ThemeDB.fallback_font, Vector2(-22, -half_h - 8),
		"Conveyor", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	return Rect2(-BELT_LENGTH / 2.0 - 16, -BELT_HEIGHT / 2.0 - 20, BELT_LENGTH + 32, BELT_HEIGHT + 40)


func _get_component_type() -> String:
	return "conveyor"
