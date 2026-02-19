class_name Gear
extends MachineComponent

## Transfers and scales energy. Size affects torque/speed ratio.
## Input: Energy. Output: Energy. Parameters: size, teeth_count.

const GEAR_COLOR := Color(0.55, 0.55, 0.6)
const GEAR_ACCENT := Color(0.7, 0.65, 0.3)
const BASE_RADIUS: float = 28.0

var _rotation_angle: float = 0.0
var _energy_in: float = 0.0


func _setup_ports() -> void:
	add_port("energy_in", Port.PortType.ENERGY, Port.Direction.INPUT, Vector2(-BASE_RADIUS - 12, 0))
	add_port("energy_out", Port.PortType.ENERGY, Port.Direction.OUTPUT, Vector2(BASE_RADIUS + 12, 0))


func _setup_parameters() -> void:
	register_parameter("size", "Size", 1.0, 0.5, 2.0, 0.1)
	register_parameter("teeth_count", "Teeth", 8.0, 4.0, 16.0, 1.0)


func _on_input_received(_port: Port, data: Variant) -> void:
	if data is Dictionary:
		_energy_in = data.get("energy", 0.0)


func _process_component(delta: float) -> void:
	var gear_size: float = get_parameter("size")
	var teeth: float = get_parameter("teeth_count")
	var speed_mult: float = 1.0 / gear_size
	var torque_mult: float = gear_size

	_rotation_angle += (100.0 * speed_mult + _energy_in * 200.0) * delta
	if _rotation_angle > 360.0:
		_rotation_angle -= 360.0

	var output_energy: float = (_energy_in + 0.1) * torque_mult
	send_output("energy_out", {"energy": clampf(output_energy, 0.0, 1.0)})
	_energy_in = 0.0
	queue_redraw()


func reset_component() -> void:
	super.reset_component()
	_rotation_angle = 0.0
	_energy_in = 0.0
	queue_redraw()


func _draw_component() -> void:
	var gear_size: float = get_parameter("size")
	var teeth: int = int(get_parameter("teeth_count"))
	var radius: float = BASE_RADIUS * gear_size
	var tooth_height: float = 8.0 * gear_size

	# Gear body
	draw_circle(Vector2.ZERO, radius, GEAR_COLOR.darkened(0.3))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, GEAR_COLOR, 2.0)

	# Teeth
	var rot_rad: float = deg_to_rad(_rotation_angle)
	for i in range(teeth):
		var angle: float = rot_rad + TAU * float(i) / float(teeth)
		var inner: Vector2 = Vector2.RIGHT.rotated(angle) * (radius - 2)
		var outer: Vector2 = Vector2.RIGHT.rotated(angle) * (radius + tooth_height)
		var perp: Vector2 = Vector2.RIGHT.rotated(angle + PI / 2.0) * 3.0 * gear_size
		var tooth_points: PackedVector2Array = [
			inner + perp, outer + perp * 0.6, outer - perp * 0.6, inner - perp,
		]
		draw_colored_polygon(tooth_points, GEAR_ACCENT.darkened(0.1))

	# Center hub
	draw_circle(Vector2.ZERO, radius * 0.3, GEAR_COLOR.lightened(0.1))
	draw_arc(Vector2.ZERO, radius * 0.3, 0, TAU, 12, GEAR_ACCENT, 1.5)

	# Axle cross
	var axle_size: float = radius * 0.15
	draw_line(Vector2(-axle_size, 0), Vector2(axle_size, 0), GEAR_COLOR.darkened(0.2), 2.0)
	draw_line(Vector2(0, -axle_size), Vector2(0, axle_size), GEAR_COLOR.darkened(0.2), 2.0)

	draw_string(ThemeDB.fallback_font, Vector2(-12, -radius - tooth_height - 4),
		"Gear", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	var r: float = BASE_RADIUS * get_parameter("size") + 12
	return Rect2(-r - 8, -r - 16, r * 2 + 16, r * 2 + 32)


func _get_component_type() -> String:
	return "gear"
