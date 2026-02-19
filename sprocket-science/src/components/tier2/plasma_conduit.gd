class_name PlasmaConduit
extends MachineComponent

## Glowing flow tube with temperature and viscosity control.
## Input: Flow. Output: Flow. Parameters: temperature, viscosity.
## Higher temperature = faster flow + glow. Higher viscosity = slower but denser.

const CONDUIT_LENGTH: float = 130.0
const CONDUIT_WIDTH: float = 18.0
const BASE_COLOR := Color(0.6, 0.2, 0.7)
const PLASMA_HOT := Color(1.0, 0.4, 0.2)
const PLASMA_COOL := Color(0.3, 0.2, 0.8)

var _body: StaticBody2D
var _flow_in: float = 0.0
var _glow_time: float = 0.0


func _setup_ports() -> void:
	add_port("flow_in", Port.PortType.FLOW, Port.Direction.INPUT, Vector2(-CONDUIT_LENGTH / 2.0 - 12, 0))
	add_port("flow_out", Port.PortType.FLOW, Port.Direction.OUTPUT, Vector2(CONDUIT_LENGTH / 2.0 + 12, 0))


func _setup_parameters() -> void:
	register_parameter("temperature", "Temperature", 50.0, 0.0, 100.0, 1.0)
	register_parameter("viscosity", "Viscosity", 50.0, 0.0, 100.0, 1.0)

	_body = StaticBody2D.new()
	add_child(_body)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(CONDUIT_LENGTH, CONDUIT_WIDTH)
	var col := CollisionShape2D.new()
	col.shape = shape
	_body.add_child(col)


func _on_input_received(_port: Port, data: Variant) -> void:
	if data is Dictionary:
		_flow_in = data.get("flow_rate", 0.0)


func _process_component(delta: float) -> void:
	var temp: float = get_parameter("temperature") / 100.0
	var visc: float = get_parameter("viscosity") / 100.0

	_glow_time += delta * (1.0 + temp * 3.0)

	var speed_mult: float = (1.0 + temp) * (1.0 - visc * 0.5)
	var density_mult: float = 0.5 + visc * 0.5
	var output_flow: float = (_flow_in + 0.1) * speed_mult * density_mult

	send_output("flow_out", {"flow_rate": clampf(output_flow, 0.0, 2.0)})
	_flow_in = 0.0
	queue_redraw()


func reset_component() -> void:
	super.reset_component()
	_flow_in = 0.0
	_glow_time = 0.0
	queue_redraw()


func _draw_component() -> void:
	var half_l: float = CONDUIT_LENGTH / 2.0
	var half_w: float = CONDUIT_WIDTH / 2.0
	var temp: float = get_parameter("temperature") / 100.0
	var plasma_color: Color = PLASMA_COOL.lerp(PLASMA_HOT, temp)

	# Outer shell
	draw_rect(Rect2(-half_l, -half_w, CONDUIT_LENGTH, CONDUIT_WIDTH), BASE_COLOR.darkened(0.4), true)
	draw_rect(Rect2(-half_l, -half_w, CONDUIT_LENGTH, CONDUIT_WIDTH), BASE_COLOR, false, 2.0)

	# Inner plasma glow
	if current_state == State.ACTIVE:
		var glow_rect := Rect2(-half_l + 3, -half_w + 3, CONDUIT_LENGTH - 6, CONDUIT_WIDTH - 6)
		var pulse: float = (sin(_glow_time * 2.0) + 1.0) / 2.0
		var inner_color: Color = plasma_color
		inner_color.a = 0.4 + pulse * 0.3
		draw_rect(glow_rect, inner_color, true)

		# Flow blobs
		var blob_count: int = 4
		for i in range(blob_count):
			var t: float = fmod(_glow_time * 0.3 + float(i) / float(blob_count), 1.0)
			var bx: float = lerpf(-half_l + 8, half_l - 8, t)
			draw_circle(Vector2(bx, 0), 4.0, plasma_color.lightened(0.2))

	draw_string(ThemeDB.fallback_font, Vector2(-30, -half_w - 8),
		"Plasma Conduit", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	return Rect2(-CONDUIT_LENGTH / 2.0 - 16, -CONDUIT_WIDTH / 2.0 - 20, CONDUIT_LENGTH + 32, CONDUIT_WIDTH + 40)


func _get_component_type() -> String:
	return "plasma_conduit"
