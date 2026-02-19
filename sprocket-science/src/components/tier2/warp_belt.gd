class_name WarpBelt
extends MachineComponent

## Teleports objects along a path between endpoints.
## Input: Energy. Output: Flow. Parameters: belt_length, speed.

const BELT_WIDTH: float = 24.0
const BELT_COLOR := Color(0.2, 0.5, 0.5)
const WARP_COLOR := Color(0.0, 0.9, 0.7)

var _energy_in: float = 0.0
var _warp_time: float = 0.0
var _belt_length: float = 120.0


func _setup_ports() -> void:
	add_port("energy_in", Port.PortType.ENERGY, Port.Direction.INPUT, Vector2(-_belt_length / 2.0 - 12, 0))
	add_port("flow_out", Port.PortType.FLOW, Port.Direction.OUTPUT, Vector2(_belt_length / 2.0 + 12, 0))


func _setup_parameters() -> void:
	register_parameter("belt_length", "Length", 120.0, 60.0, 200.0, 10.0)
	register_parameter("speed", "Speed", 50.0, 10.0, 100.0, 1.0)


func _on_input_received(_port: Port, data: Variant) -> void:
	if data is Dictionary:
		_energy_in = data.get("energy", 0.0)


func _process_component(delta: float) -> void:
	var speed: float = get_parameter("speed") / 100.0
	_belt_length = get_parameter("belt_length")
	_warp_time += delta * (1.0 + speed * 3.0)

	var output: float = _energy_in * speed
	send_output("flow_out", {"flow_rate": clampf(output, 0.0, 2.0)})
	_energy_in = 0.0
	queue_redraw()


func reset_component() -> void:
	super.reset_component()
	_energy_in = 0.0
	_warp_time = 0.0
	queue_redraw()


func _draw_component() -> void:
	var half_l: float = _belt_length / 2.0
	var half_w: float = BELT_WIDTH / 2.0

	# Belt track
	draw_rect(Rect2(-half_l, -half_w, _belt_length, BELT_WIDTH), BELT_COLOR.darkened(0.4), true)
	draw_rect(Rect2(-half_l, -half_w, _belt_length, BELT_WIDTH), BELT_COLOR, false, 2.0)

	# Warp chevrons
	if current_state == State.ACTIVE:
		var chevron_count: int = 6
		for i in range(chevron_count):
			var t: float = fmod(_warp_time * 0.4 + float(i) / float(chevron_count), 1.0)
			var cx: float = lerpf(-half_l + 8, half_l - 8, t)
			var alpha: float = 0.6 - abs(t - 0.5) * 0.8
			var c: Color = Color(WARP_COLOR.r, WARP_COLOR.g, WARP_COLOR.b, maxf(alpha, 0.1))
			var h: float = half_w * 0.6
			draw_line(Vector2(cx - 4, -h), Vector2(cx, 0), c, 2.0)
			draw_line(Vector2(cx, 0), Vector2(cx - 4, h), c, 2.0)

	# Entry/exit portals
	for sx in [-1.0, 1.0]:
		var px: float = half_l * sx
		var portal_pulse: float = (sin(_warp_time * 4.0 + sx) + 1.0) / 2.0
		var pc: Color = WARP_COLOR.lightened(portal_pulse * 0.3)
		draw_circle(Vector2(px, 0), 6.0, pc)
		draw_arc(Vector2(px, 0), 8.0, 0, TAU, 12, WARP_COLOR, 1.5)

	draw_string(ThemeDB.fallback_font, Vector2(-24, -half_w - 8),
		"Warp Belt", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	var half_l: float = _belt_length / 2.0
	return Rect2(-half_l - 16, -BELT_WIDTH / 2.0 - 20, _belt_length + 32, BELT_WIDTH + 40)


func _get_component_type() -> String:
	return "warp_belt"
