class_name PhaseGate
extends MachineComponent

## Filters flow by type. Signal input toggles gate open/closed.
## Input: Flow + Signal. Output: Flow. Parameters: filter_type, selectivity.

const GATE_SIZE: float = 50.0
const GATE_COLOR := Color(0.4, 0.3, 0.6)
const FILTER_COLORS: Array[Color] = [
	Color(1.0, 0.3, 0.3),   # Red
	Color(0.3, 1.0, 0.3),   # Green
	Color(0.3, 0.3, 1.0),   # Blue
	Color(1.0, 1.0, 0.3),   # Yellow
]

var _flow_in: float = 0.0
var _signal_in: float = 0.0
var _gate_open: float = 0.0
var _scan_offset: float = 0.0


func _setup_ports() -> void:
	add_port("flow_in", Port.PortType.FLOW, Port.Direction.INPUT, Vector2(-GATE_SIZE / 2.0 - 12, -8))
	add_port("signal_in", Port.PortType.SIGNAL, Port.Direction.INPUT, Vector2(-GATE_SIZE / 2.0 - 12, 8))
	add_port("flow_out", Port.PortType.FLOW, Port.Direction.OUTPUT, Vector2(GATE_SIZE / 2.0 + 12, 0))


func _setup_parameters() -> void:
	register_parameter("filter_type", "Filter Type", 0.0, 0.0, 3.0, 1.0)
	register_parameter("selectivity", "Selectivity", 50.0, 0.0, 100.0, 1.0)


func _on_input_received(port: Port, data: Variant) -> void:
	if data is Dictionary:
		if port.port_name == "flow_in":
			_flow_in = data.get("flow_rate", 0.0)
		elif port.port_name == "signal_in":
			_signal_in = data.get("signal", 0.0)


func _process_component(delta: float) -> void:
	var selectivity: float = get_parameter("selectivity") / 100.0
	_scan_offset += delta * 2.0

	# Signal controls gate — high signal opens, low closes
	var target: float = 1.0 if _signal_in > 0.5 else selectivity
	_gate_open = lerpf(_gate_open, target, delta * 5.0)

	var output: float = _flow_in * _gate_open
	send_output("flow_out", {"flow_rate": clampf(output, 0.0, 2.0)})
	_flow_in = 0.0
	_signal_in = 0.0
	queue_redraw()


func reset_component() -> void:
	super.reset_component()
	_flow_in = 0.0
	_signal_in = 0.0
	_gate_open = 0.0
	_scan_offset = 0.0
	queue_redraw()


func _draw_component() -> void:
	var half := GATE_SIZE / 2.0
	var filter_idx: int = clampi(int(get_parameter("filter_type")), 0, 3)
	var filter_color: Color = FILTER_COLORS[filter_idx]

	# Housing
	draw_rect(Rect2(-half, -half, GATE_SIZE, GATE_SIZE), GATE_COLOR.darkened(0.4), true)
	draw_rect(Rect2(-half, -half, GATE_SIZE, GATE_SIZE), GATE_COLOR, false, 2.0)

	# Filter window
	var win_margin: float = 8.0
	var win_rect := Rect2(-half + win_margin, -half + win_margin,
		GATE_SIZE - win_margin * 2, GATE_SIZE - win_margin * 2)
	draw_rect(win_rect, Color(0.1, 0.1, 0.15), true)

	# Scan line
	if current_state == State.ACTIVE:
		var scan_y: float = lerpf(win_rect.position.y, win_rect.end.y,
			fmod(_scan_offset, 1.0))
		draw_line(Vector2(win_rect.position.x, scan_y),
			Vector2(win_rect.end.x, scan_y), filter_color, 1.5)

	# Filter color indicator
	var indicator_r: float = 6.0
	draw_circle(Vector2(0, -half + win_margin + 6), indicator_r, filter_color)

	# Gate bars (close based on _gate_open)
	var bar_gap: float = (GATE_SIZE - win_margin * 2) * _gate_open
	var bar_y: float = 0.0
	draw_rect(Rect2(win_rect.position.x, bar_y - 2, bar_gap, 4),
		filter_color.darkened(0.2), true)

	draw_string(ThemeDB.fallback_font, Vector2(-24, -half - 8),
		"Phase Gate", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	var half := GATE_SIZE / 2.0
	return Rect2(-half - 12, -half - 20, GATE_SIZE + 24, GATE_SIZE + 40)


func _get_component_type() -> String:
	return "phase_gate"
