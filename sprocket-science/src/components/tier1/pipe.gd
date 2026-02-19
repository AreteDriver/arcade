class_name Pipe
extends MachineComponent

## Tube that carries flow. Spawns RigidBody2D balls during simulation.
## Input: Flow, Output: Flow. Parameters: angle, diameter.
## Rotate via the "angle" parameter (handled by base class Node2D rotation).

const PIPE_LENGTH: float = 120.0
const PIPE_COLOR := Color(0.2, 0.5, 0.7)
const PIPE_OUTLINE := Color(0.3, 0.7, 0.9)
const BALL_RADIUS: float = 6.0
const MAX_BALLS: int = 20

var _body: StaticBody2D
var _spawn_timer: float = 0.0
var _balls: Array[RigidBody2D] = []
var _receiving_flow: bool = false


func _setup_ports() -> void:
	add_port("flow_in", Port.PortType.FLOW, Port.Direction.INPUT, Vector2(-PIPE_LENGTH / 2.0 - 12, 0))
	add_port("flow_out", Port.PortType.FLOW, Port.Direction.OUTPUT, Vector2(PIPE_LENGTH / 2.0 + 12, 0))


func _setup_parameters() -> void:
	register_parameter("angle", "Angle", 0.0, 0.0, 360.0, 5.0)
	register_parameter("diameter", "Diameter", 24.0, 12.0, 48.0, 2.0)

	_body = StaticBody2D.new()
	add_child(_body)
	_rebuild_collision()


func _rebuild_collision() -> void:
	# Remove existing collision shapes
	for child in _body.get_children():
		child.queue_free()

	var diameter: float = get_parameter("diameter")
	var half_d: float = diameter / 2.0
	var wall_thickness: float = 4.0

	# Top wall
	var top_shape := RectangleShape2D.new()
	top_shape.size = Vector2(PIPE_LENGTH, wall_thickness)
	var top_col := CollisionShape2D.new()
	top_col.shape = top_shape
	top_col.position = Vector2(0, -half_d - wall_thickness / 2.0)
	_body.add_child(top_col)

	# Bottom wall
	var bot_shape := RectangleShape2D.new()
	bot_shape.size = Vector2(PIPE_LENGTH, wall_thickness)
	var bot_col := CollisionShape2D.new()
	bot_col.shape = bot_shape
	bot_col.position = Vector2(0, half_d + wall_thickness / 2.0)
	_body.add_child(bot_col)


func _on_parameter_changed(param_name: String, value: float) -> void:
	if param_name == "diameter":
		_rebuild_collision()


func _on_input_received(_port: Port, _data: Variant) -> void:
	_receiving_flow = true


func _process_component(delta: float) -> void:
	_spawn_timer += delta
	var spawn_interval: float = 1.5 - (get_parameter("diameter") - 12.0) / 48.0
	spawn_interval = maxf(spawn_interval, 0.4)

	if _spawn_timer >= spawn_interval:
		_spawn_timer = 0.0
		_spawn_ball()

	send_output("flow_out", {"flow_rate": get_parameter("diameter") / 24.0})
	_cleanup_balls()


func _spawn_ball() -> void:
	if _balls.size() >= MAX_BALLS:
		return

	var ball := RigidBody2D.new()
	ball.mass = 0.5
	ball.gravity_scale = 1.0
	ball.linear_damp = 0.3

	var shape := CircleShape2D.new()
	shape.radius = BALL_RADIUS
	var col := CollisionShape2D.new()
	col.shape = shape
	ball.add_child(col)

	var visual := BallVisual.new()
	visual.radius = BALL_RADIUS
	ball.add_child(visual)

	# Spawn at input end, respecting component rotation
	ball.global_position = to_global(Vector2(-PIPE_LENGTH / 2.0, 0))

	# Initial velocity through the pipe, respecting rotation
	var speed: float = 60.0 + get_parameter("diameter") * 2.0
	ball.linear_velocity = Vector2(speed, 0).rotated(global_rotation)

	var canvas: Node = get_parent()
	if canvas:
		canvas.add_child(ball)
		_balls.append(ball)


func _cleanup_balls() -> void:
	for i in range(_balls.size() - 1, -1, -1):
		var ball: RigidBody2D = _balls[i]
		if not is_instance_valid(ball):
			_balls.remove_at(i)
			continue
		if ball.global_position.distance_to(global_position) > 800.0:
			ball.queue_free()
			_balls.remove_at(i)


func reset_component() -> void:
	super.reset_component()
	_spawn_timer = 0.0
	_receiving_flow = false
	for ball in _balls:
		if is_instance_valid(ball):
			ball.queue_free()
	_balls.clear()


func _draw_component() -> void:
	var diameter: float = get_parameter("diameter")
	var half_d: float = diameter / 2.0
	var half_l: float = PIPE_LENGTH / 2.0

	# Draw flat — Node2D rotation handles the angle
	var pipe_rect := Rect2(-half_l, -half_d, PIPE_LENGTH, diameter)
	draw_rect(pipe_rect, PIPE_COLOR.darkened(0.3), true)

	# Walls
	draw_line(Vector2(-half_l, -half_d), Vector2(half_l, -half_d), PIPE_OUTLINE, 3.0)
	draw_line(Vector2(-half_l, half_d), Vector2(half_l, half_d), PIPE_OUTLINE, 3.0)

	# End caps
	draw_line(Vector2(-half_l, -half_d), Vector2(-half_l, half_d), PIPE_OUTLINE, 2.0)
	draw_line(Vector2(half_l, -half_d), Vector2(half_l, half_d), PIPE_OUTLINE, 2.0)

	# Flow indicator lines when active
	if current_state == State.ACTIVE:
		var flow_color := PIPE_OUTLINE.lightened(0.2)
		flow_color.a = 0.4
		for i in range(4):
			var x: float = lerpf(-half_l + 10, half_l - 10, float(i) / 3.0)
			draw_line(Vector2(x, -half_d + 3), Vector2(x + 8, 0), flow_color, 1.5)
			draw_line(Vector2(x + 8, 0), Vector2(x, half_d - 3), flow_color, 1.5)

	# Label
	draw_string(ThemeDB.fallback_font, Vector2(-14, -half_d - 8),
		"Pipe", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	var half_d: float = get_parameter("diameter") / 2.0
	return Rect2(-PIPE_LENGTH / 2.0 - 16, -half_d - 20, PIPE_LENGTH + 32, half_d * 2 + 40)


func _get_component_type() -> String:
	return "pipe"


class BallVisual extends Node2D:
	var radius: float = 6.0

	func _draw() -> void:
		draw_circle(Vector2.ZERO, radius, Color(0.3, 0.75, 1.0, 0.9))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 16, Color(0.5, 0.85, 1.0), 1.5)
		draw_circle(Vector2(-radius * 0.3, -radius * 0.3), radius * 0.25, Color(0.7, 0.9, 1.0, 0.6))
