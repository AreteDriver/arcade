class_name DimensionalSplitter
extends MachineComponent

## Duplicates flow into parallel output paths.
## Input: Flow. Output: Flow x2. Parameters: split_ratio, stability.

const SPLIT_SIZE: float = 56.0
const SPLIT_COLOR := Color(0.5, 0.2, 0.6)
const RIFT_COLOR := Color(0.8, 0.3, 1.0)

var _flow_in: float = 0.0
var _rift_time: float = 0.0


func _setup_ports() -> void:
	add_port("flow_in", Port.PortType.FLOW, Port.Direction.INPUT, Vector2(-SPLIT_SIZE / 2.0 - 12, 0))
	add_port("flow_out_a", Port.PortType.FLOW, Port.Direction.OUTPUT, Vector2(SPLIT_SIZE / 2.0 + 12, -12))
	add_port("flow_out_b", Port.PortType.FLOW, Port.Direction.OUTPUT, Vector2(SPLIT_SIZE / 2.0 + 12, 12))


func _setup_parameters() -> void:
	register_parameter("split_ratio", "Split Ratio", 50.0, 0.0, 100.0, 1.0)
	register_parameter("stability", "Stability", 70.0, 10.0, 100.0, 1.0)


func _on_input_received(_port: Port, data: Variant) -> void:
	if data is Dictionary:
		_flow_in = data.get("flow_rate", 0.0)


func _process_component(delta: float) -> void:
	var ratio: float = get_parameter("split_ratio") / 100.0
	var stability: float = get_parameter("stability") / 100.0
	_rift_time += delta * (1.0 + (1.0 - stability) * 3.0)

	# Split flow based on ratio — some energy lost to instability
	var efficiency: float = 0.7 + stability * 0.3
	var total: float = _flow_in * efficiency
	send_output("flow_out_a", {"flow_rate": clampf(total * ratio, 0.0, 2.0)})
	send_output("flow_out_b", {"flow_rate": clampf(total * (1.0 - ratio), 0.0, 2.0)})
	_flow_in = 0.0
	queue_redraw()


func reset_component() -> void:
	super.reset_component()
	_flow_in = 0.0
	_rift_time = 0.0
	queue_redraw()


func _draw_component() -> void:
	var half := SPLIT_SIZE / 2.0
	var stability: float = get_parameter("stability") / 100.0

	# Housing
	var points: PackedVector2Array = [
		Vector2(-half, -half), Vector2(half * 0.3, -half),
		Vector2(half, -half * 0.6), Vector2(half, -4),
		Vector2(half, 4),
		Vector2(half, half * 0.6), Vector2(half * 0.3, half),
		Vector2(-half, half),
	]
	draw_colored_polygon(points, SPLIT_COLOR.darkened(0.4))
	draw_polyline(points + PackedVector2Array([points[0]]), SPLIT_COLOR, 2.0)

	# Dimensional rift center
	if current_state == State.ACTIVE:
		var rift_size: float = 8.0 + sin(_rift_time * 3.0) * 2.0
		var rift_alpha: float = 0.4 + (1.0 - stability) * 0.3
		draw_circle(Vector2.ZERO, rift_size, Color(RIFT_COLOR.r, RIFT_COLOR.g, RIFT_COLOR.b, rift_alpha))

		# Split lines from center to outputs
		var flicker: float = sin(_rift_time * 7.0) * (1.0 - stability) * 3.0
		draw_line(Vector2.ZERO, Vector2(half * 0.6, -10 + flicker), RIFT_COLOR, 1.5)
		draw_line(Vector2.ZERO, Vector2(half * 0.6, 10 - flicker), RIFT_COLOR, 1.5)

	# Input arrow
	draw_line(Vector2(-half * 0.6, 0), Vector2(-4, 0), RIFT_COLOR.darkened(0.3), 2.0)

	draw_string(ThemeDB.fallback_font, Vector2(-28, -half - 8),
		"Dim. Splitter", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	var half := SPLIT_SIZE / 2.0
	return Rect2(-half - 12, -half - 20, SPLIT_SIZE + 24, SPLIT_SIZE + 40)


func _get_component_type() -> String:
	return "dimensional_splitter"
