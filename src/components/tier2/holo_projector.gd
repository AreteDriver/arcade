class_name HoloProjector
extends MachineComponent

## Visual output indicator. Displays patterns based on energy and signal input.
## Input: Energy + Signal. Output: Signal. Parameters: pattern, brightness.

const PROJECTOR_SIZE: float = 52.0
const PROJECTOR_COLOR := Color(0.25, 0.3, 0.5)
const HOLO_COLOR := Color(0.2, 0.8, 1.0)

var _energy_in: float = 0.0
var _signal_in: float = 0.0
var _anim_time: float = 0.0


func _setup_ports() -> void:
	add_port("energy_in", Port.PortType.ENERGY, Port.Direction.INPUT, Vector2(-PROJECTOR_SIZE / 2.0 - 12, -8))
	add_port("signal_in", Port.PortType.SIGNAL, Port.Direction.INPUT, Vector2(-PROJECTOR_SIZE / 2.0 - 12, 8))
	add_port("signal_out", Port.PortType.SIGNAL, Port.Direction.OUTPUT, Vector2(PROJECTOR_SIZE / 2.0 + 12, 0))


func _setup_parameters() -> void:
	register_parameter("pattern", "Pattern", 0.0, 0.0, 3.0, 1.0)
	register_parameter("brightness", "Brightness", 70.0, 10.0, 100.0, 1.0)


func _on_input_received(port: Port, data: Variant) -> void:
	if data is Dictionary:
		if port.port_name == "energy_in":
			_energy_in = data.get("energy", 0.0)
		elif port.port_name == "signal_in":
			_signal_in = data.get("signal", 0.0)


func _process_component(delta: float) -> void:
	var brightness: float = get_parameter("brightness") / 100.0
	_anim_time += delta * (1.0 + _energy_in * 2.0)

	# Pass signal through with energy-modulated strength
	var out_signal: float = _signal_in * brightness * clampf(_energy_in + 0.2, 0.0, 1.0)
	send_output("signal_out", {"signal": clampf(out_signal, 0.0, 1.0)})
	_energy_in = 0.0
	_signal_in = 0.0
	queue_redraw()


func reset_component() -> void:
	super.reset_component()
	_energy_in = 0.0
	_signal_in = 0.0
	_anim_time = 0.0
	queue_redraw()


func _draw_component() -> void:
	var half := PROJECTOR_SIZE / 2.0
	var brightness: float = get_parameter("brightness") / 100.0
	var pattern_idx: int = clampi(int(get_parameter("pattern")), 0, 3)

	# Projector body
	draw_rect(Rect2(-half, -half, PROJECTOR_SIZE, PROJECTOR_SIZE), PROJECTOR_COLOR.darkened(0.4), true)
	draw_rect(Rect2(-half, -half, PROJECTOR_SIZE, PROJECTOR_SIZE), PROJECTOR_COLOR, false, 2.0)

	# Lens circle
	var lens_r: float = half * 0.5
	draw_arc(Vector2.ZERO, lens_r, 0, TAU, 20, HOLO_COLOR.darkened(0.3), 2.0)

	# Holographic projection (above the component)
	if current_state == State.ACTIVE:
		var proj_alpha: float = brightness * 0.5
		var hc: Color = Color(HOLO_COLOR.r, HOLO_COLOR.g, HOLO_COLOR.b, proj_alpha)

		match pattern_idx:
			0:  # Circle pattern
				var r: float = lens_r * 0.7 + sin(_anim_time * 2.0) * 3.0
				draw_arc(Vector2.ZERO, r, 0, TAU, 16, hc, 2.0)
				draw_arc(Vector2.ZERO, r * 0.5, 0, TAU, 12, hc, 1.5)
			1:  # Cross pattern
				var sz: float = lens_r * 0.6
				draw_line(Vector2(-sz, 0), Vector2(sz, 0), hc, 2.0)
				draw_line(Vector2(0, -sz), Vector2(0, sz), hc, 2.0)
			2:  # Diamond pattern
				var sz: float = lens_r * 0.6 + sin(_anim_time * 3.0) * 2.0
				var diamond: PackedVector2Array = [
					Vector2(0, -sz), Vector2(sz, 0),
					Vector2(0, sz), Vector2(-sz, 0),
				]
				draw_polyline(diamond + PackedVector2Array([diamond[0]]), hc, 2.0)
			3:  # Star pattern
				var sz: float = lens_r * 0.5
				for i in range(5):
					var angle: float = _anim_time + TAU * float(i) / 5.0
					var end: Vector2 = Vector2.UP.rotated(angle) * sz
					draw_line(Vector2.ZERO, end, hc, 1.5)

		# Scanlines
		for i in range(3):
			var sy: float = lerpf(-lens_r, lens_r, fmod(_anim_time * 0.5 + float(i) * 0.33, 1.0))
			draw_line(Vector2(-lens_r, sy), Vector2(lens_r, sy),
				Color(HOLO_COLOR.r, HOLO_COLOR.g, HOLO_COLOR.b, 0.1), 1.0)

	draw_string(ThemeDB.fallback_font, Vector2(-28, -half - 8),
		"Holo Proj.", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	var half := PROJECTOR_SIZE / 2.0
	return Rect2(-half - 12, -half - 20, PROJECTOR_SIZE + 24, PROJECTOR_SIZE + 40)


func _get_component_type() -> String:
	return "holo_projector"
