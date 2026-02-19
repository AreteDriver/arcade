class_name QuantumCoupler
extends MachineComponent

## Wireless energy transfer. Sends energy to paired coupler in range.
## Input: Energy. Output: Energy. Parameters: range, sync_rate.

const COUPLER_SIZE: float = 44.0
const COUPLER_COLOR := Color(0.2, 0.4, 0.7)
const QUANTUM_COLOR := Color(0.4, 0.8, 1.0)

var _energy_in: float = 0.0
var _pulse_time: float = 0.0


func _setup_ports() -> void:
	add_port("energy_in", Port.PortType.ENERGY, Port.Direction.INPUT, Vector2(-COUPLER_SIZE / 2.0 - 12, 0))
	add_port("energy_out", Port.PortType.ENERGY, Port.Direction.OUTPUT, Vector2(COUPLER_SIZE / 2.0 + 12, 0))


func _setup_parameters() -> void:
	register_parameter("sync_range", "Range", 200.0, 50.0, 400.0, 10.0)
	register_parameter("sync_rate", "Sync Rate", 50.0, 10.0, 100.0, 1.0)


func _on_input_received(_port: Port, data: Variant) -> void:
	if data is Dictionary:
		_energy_in = data.get("energy", 0.0)


func _process_component(delta: float) -> void:
	var rate: float = get_parameter("sync_rate") / 100.0
	_pulse_time += delta * (1.0 + rate * 2.0)

	var output: float = _energy_in * rate
	send_output("energy_out", {"energy": clampf(output, 0.0, 1.0)})
	_energy_in = 0.0
	queue_redraw()


func reset_component() -> void:
	super.reset_component()
	_energy_in = 0.0
	_pulse_time = 0.0
	queue_redraw()


func _draw_component() -> void:
	var half := COUPLER_SIZE / 2.0
	var sync_range: float = get_parameter("sync_range")

	# Body
	draw_rect(Rect2(-half, -half, COUPLER_SIZE, COUPLER_SIZE), COUPLER_COLOR.darkened(0.4), true)
	draw_rect(Rect2(-half, -half, COUPLER_SIZE, COUPLER_SIZE), COUPLER_COLOR, false, 2.0)

	# Quantum rings
	if current_state == State.ACTIVE:
		var ring_count: int = 2
		for i in range(ring_count):
			var t: float = fmod(_pulse_time * 0.4 + float(i) * 0.5, 1.0)
			var ring_r: float = lerpf(half * 0.3, sync_range * 0.3, t)
			var alpha: float = (1.0 - t) * 0.25
			draw_arc(Vector2.ZERO, ring_r, 0, TAU, 24, Color(QUANTUM_COLOR.r, QUANTUM_COLOR.g, QUANTUM_COLOR.b, alpha), 1.5)

	# Core crystal
	var crystal_size: float = half * 0.4
	var crystal_points: PackedVector2Array = [
		Vector2(0, -crystal_size), Vector2(crystal_size, 0),
		Vector2(0, crystal_size), Vector2(-crystal_size, 0),
	]
	var pulse: float = (sin(_pulse_time * 3.0) + 1.0) / 2.0
	var crystal_color: Color = QUANTUM_COLOR.lerp(Color.WHITE, pulse * 0.3)
	draw_colored_polygon(crystal_points, crystal_color)
	draw_polyline(crystal_points + PackedVector2Array([crystal_points[0]]), QUANTUM_COLOR.lightened(0.3), 1.5)

	draw_string(ThemeDB.fallback_font, Vector2(-28, -half - 8),
		"Q. Coupler", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	var half := COUPLER_SIZE / 2.0
	return Rect2(-half - 12, -half - 20, COUPLER_SIZE + 24, COUPLER_SIZE + 40)


func _get_component_type() -> String:
	return "quantum_coupler"
