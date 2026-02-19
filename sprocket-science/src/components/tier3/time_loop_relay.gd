class_name TimeLoopRelay
extends MachineComponent

## Cycles output back to input with configurable delay.
## Input: Energy. Output: Energy. Parameters: loop_delay, decay.

const RELAY_SIZE: float = 52.0
const RELAY_COLOR := Color(0.3, 0.4, 0.5)
const LOOP_COLOR := Color(0.2, 0.9, 0.6)

var _energy_in: float = 0.0
var _buffer: float = 0.0
var _loop_timer: float = 0.0
var _loop_angle: float = 0.0


func _setup_ports() -> void:
	add_port("energy_in", Port.PortType.ENERGY, Port.Direction.INPUT, Vector2(-RELAY_SIZE / 2.0 - 12, 0))
	add_port("energy_out", Port.PortType.ENERGY, Port.Direction.OUTPUT, Vector2(RELAY_SIZE / 2.0 + 12, 0))


func _setup_parameters() -> void:
	register_parameter("loop_delay", "Loop Delay (s)", 1.0, 0.2, 3.0, 0.1)
	register_parameter("decay", "Decay", 30.0, 0.0, 90.0, 1.0)


func _on_input_received(_port: Port, data: Variant) -> void:
	if data is Dictionary:
		_energy_in = data.get("energy", 0.0)


func _process_component(delta: float) -> void:
	var delay: float = get_parameter("loop_delay")
	var decay: float = get_parameter("decay") / 100.0

	_loop_angle += delta * 120.0
	if _loop_angle > 360.0:
		_loop_angle -= 360.0

	# Accumulate input into buffer
	_buffer = clampf(_buffer + _energy_in, 0.0, 1.0)
	_loop_timer += delta

	if _loop_timer >= delay and _buffer > 0.01:
		# Output the buffered energy
		send_output("energy_out", {"energy": _buffer})
		# Loop back with decay
		_buffer *= (1.0 - decay)
		_loop_timer = 0.0

	_energy_in = 0.0
	queue_redraw()


func reset_component() -> void:
	super.reset_component()
	_energy_in = 0.0
	_buffer = 0.0
	_loop_timer = 0.0
	_loop_angle = 0.0
	queue_redraw()


func _draw_component() -> void:
	var half := RELAY_SIZE / 2.0

	# Housing
	draw_rect(Rect2(-half, -half, RELAY_SIZE, RELAY_SIZE), RELAY_COLOR.darkened(0.4), true)
	draw_rect(Rect2(-half, -half, RELAY_SIZE, RELAY_SIZE), RELAY_COLOR, false, 2.0)

	# Loop circle with arrow
	var loop_r: float = half * 0.5
	draw_arc(Vector2.ZERO, loop_r, 0, TAU * 0.75, 20, LOOP_COLOR.darkened(0.2), 2.0)

	# Arrow head at end of arc
	var arrow_angle: float = TAU * 0.75
	var arrow_pos: Vector2 = Vector2.RIGHT.rotated(arrow_angle) * loop_r
	var arrow_dir: Vector2 = Vector2.DOWN.rotated(arrow_angle)
	draw_line(arrow_pos, arrow_pos + arrow_dir.rotated(0.5) * 6, LOOP_COLOR, 2.0)
	draw_line(arrow_pos, arrow_pos + arrow_dir.rotated(-0.5) * 6, LOOP_COLOR, 2.0)

	# Buffer indicator
	if current_state == State.ACTIVE:
		var indicator_r: float = loop_r * _buffer
		if indicator_r > 1.0:
			draw_circle(Vector2.ZERO, indicator_r, Color(LOOP_COLOR.r, LOOP_COLOR.g, LOOP_COLOR.b, 0.3))

		# Rotating dot showing loop progress
		var dot_angle: float = deg_to_rad(_loop_angle)
		var dot_pos: Vector2 = Vector2.RIGHT.rotated(dot_angle) * loop_r
		draw_circle(dot_pos, 3.0, LOOP_COLOR)

	draw_string(ThemeDB.fallback_font, Vector2(-28, -half - 8),
		"Time Loop", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	var half := RELAY_SIZE / 2.0
	return Rect2(-half - 12, -half - 20, RELAY_SIZE + 24, RELAY_SIZE + 40)


func _get_component_type() -> String:
	return "time_loop_relay"
