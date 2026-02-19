class_name Valve
extends MachineComponent

## Regulates flow passing through.
## Input: Flow + Signal. Output: Flow. Parameters: threshold (0-1).
## Passes flow scaled by threshold. Signal input overrides threshold to 1.0.

const VALVE_SIZE: float = 48.0
const VALVE_COLOR := Color(0.5, 0.3, 0.5)
const VALVE_ACCENT := Color(0.8, 0.5, 0.9)
const PIPE_WIDTH: float = 16.0

var _body: StaticBody2D
var _current_flow: float = 0.0
var _signal_override: bool = false
var _effective_opening: float = 0.5


func _setup_ports() -> void:
	add_port("flow_in", Port.PortType.FLOW, Port.Direction.INPUT, Vector2(-VALVE_SIZE / 2.0 - 12, 0))
	add_port("signal_in", Port.PortType.SIGNAL, Port.Direction.INPUT, Vector2(0, -VALVE_SIZE / 2.0 - 12))
	add_port("flow_out", Port.PortType.FLOW, Port.Direction.OUTPUT, Vector2(VALVE_SIZE / 2.0 + 12, 0))


func _setup_parameters() -> void:
	register_parameter("threshold", "Threshold", 0.5, 0.0, 1.0, 0.05)

	_body = StaticBody2D.new()
	add_child(_body)
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(VALVE_SIZE, VALVE_SIZE)
	var body_col := CollisionShape2D.new()
	body_col.shape = body_shape
	_body.add_child(body_col)


func _on_input_received(port: Port, data: Variant) -> void:
	if port.port_name == "flow_in" and data is Dictionary:
		_current_flow = data.get("flow_rate", 0.0)
	elif port.port_name == "signal_in":
		_signal_override = true


func _process_component(_delta: float) -> void:
	var threshold: float = get_parameter("threshold")

	# Signal override opens valve fully
	if _signal_override:
		_effective_opening = 1.0
	else:
		_effective_opening = threshold

	# Scale output flow by effective opening
	var output_flow: float = _current_flow * _effective_opening
	if output_flow > 0.01:
		send_output("flow_out", {"flow_rate": output_flow})

	# Reset per-frame inputs
	_signal_override = false
	_current_flow = 0.0
	queue_redraw()


func reset_component() -> void:
	super.reset_component()
	_current_flow = 0.0
	_signal_override = false
	_effective_opening = 0.5
	queue_redraw()


func _draw_component() -> void:
	var half := VALVE_SIZE / 2.0

	# Body housing
	draw_rect(Rect2(-half, -half, VALVE_SIZE, VALVE_SIZE), VALVE_COLOR.darkened(0.3), true)
	draw_rect(Rect2(-half, -half, VALVE_SIZE, VALVE_SIZE), VALVE_COLOR, false, 2.0)

	# Pipe stubs left and right
	draw_rect(Rect2(-half - 8, -PIPE_WIDTH / 2.0, 8, PIPE_WIDTH), VALVE_COLOR.darkened(0.1), true)
	draw_rect(Rect2(half, -PIPE_WIDTH / 2.0, 8, PIPE_WIDTH), VALVE_COLOR.darkened(0.1), true)

	# Valve gate (rotates based on opening)
	var gate_angle: float = lerpf(0, PI / 2.0, _effective_opening)
	var gate_len: float = half * 0.7
	var gate_start := Vector2.UP.rotated(gate_angle) * gate_len
	var gate_end := Vector2.DOWN.rotated(gate_angle) * gate_len
	var gate_color := VALVE_ACCENT if _effective_opening > 0.5 else VALVE_COLOR.lightened(0.1)
	draw_line(gate_start, gate_end, gate_color, 3.0)

	# Center knob
	draw_circle(Vector2.ZERO, 6.0, VALVE_COLOR.lightened(0.2))
	draw_arc(Vector2.ZERO, 6.0, 0, TAU, 12, VALVE_ACCENT, 1.5)

	# Opening percentage text
	var pct: int = int(_effective_opening * 100)
	draw_string(ThemeDB.fallback_font, Vector2(-10, half - 4),
		"%d%%" % pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.8, 0.8, 0.9))

	# Label
	draw_string(ThemeDB.fallback_font, Vector2(-14, -half - 8),
		"Valve", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	var half := VALVE_SIZE / 2.0
	return Rect2(-half - 16, -half - 20, VALVE_SIZE + 32, VALVE_SIZE + 40)


func _get_component_type() -> String:
	return "valve"
