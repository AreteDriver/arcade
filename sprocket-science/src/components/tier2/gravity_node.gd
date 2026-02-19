class_name GravityNode
extends MachineComponent

## Radial force field that attracts or repels RigidBody2D in range.
## Input: Energy. Parameters: field_strength, polarity (0=attract, 1=repel), radius.

const NODE_SIZE: float = 44.0
const NODE_COLOR := Color(0.3, 0.2, 0.6)
const ATTRACT_COLOR := Color(0.4, 0.6, 1.0)
const REPEL_COLOR := Color(1.0, 0.5, 0.3)
const BASE_FORCE: float = 400.0

var _field_area: Area2D
var _field_shape: CircleShape2D
var _energy_received: bool = false
var _ring_time: float = 0.0


func _setup_ports() -> void:
	add_port("energy_in", Port.PortType.ENERGY, Port.Direction.INPUT, Vector2(-NODE_SIZE / 2.0 - 12, 0))


func _setup_parameters() -> void:
	register_parameter("field_strength", "Strength", 50.0, 0.0, 100.0, 1.0)
	register_parameter("polarity", "Polarity (0=Pull 1=Push)", 0.0, 0.0, 1.0, 1.0)
	register_parameter("radius", "Radius", 120.0, 60.0, 240.0, 10.0)

	_field_area = Area2D.new()
	_field_area.collision_layer = 0
	_field_area.collision_mask = 1
	add_child(_field_area)

	_field_shape = CircleShape2D.new()
	_field_shape.radius = 120.0
	var col := CollisionShape2D.new()
	col.shape = _field_shape
	_field_area.add_child(col)


func _on_parameter_changed(param_name: String, value: float) -> void:
	if param_name == "radius":
		_field_shape.radius = value


func _on_input_received(_port: Port, _data: Variant) -> void:
	_energy_received = true


func _process_component(delta: float) -> void:
	var strength: float = get_parameter("field_strength")
	var is_repel: bool = int(get_parameter("polarity")) == 1
	var radius: float = get_parameter("radius")

	if strength <= 0:
		return

	_ring_time += delta

	var force_magnitude: float = BASE_FORCE * (strength / 100.0)
	var bodies: Array[Node2D] = _field_area.get_overlapping_bodies()

	for body in bodies:
		if body is RigidBody2D:
			var to_center: Vector2 = global_position - body.global_position
			var dist: float = to_center.length()
			if dist < 1.0:
				continue
			var falloff: float = 1.0 - clampf(dist / radius, 0.0, 1.0)
			var direction: Vector2 = to_center.normalized()
			if is_repel:
				direction = -direction
			body.apply_central_force(direction * force_magnitude * falloff)

	queue_redraw()


func reset_component() -> void:
	super.reset_component()
	_energy_received = false
	_ring_time = 0.0
	queue_redraw()


func _draw_component() -> void:
	var half := NODE_SIZE / 2.0
	var is_repel: bool = int(get_parameter("polarity")) == 1
	var field_color: Color = REPEL_COLOR if is_repel else ATTRACT_COLOR
	var radius: float = get_parameter("radius")

	# Field radius indicator (animated rings)
	if current_state == State.ACTIVE:
		var ring_count: int = 3
		for i in range(ring_count):
			var t: float = fmod(_ring_time * 0.5 + float(i) / float(ring_count), 1.0)
			var ring_r: float = lerpf(half + 4, radius, t)
			var ring_alpha: float = (1.0 - t) * 0.2
			draw_arc(Vector2.ZERO, ring_r, 0, TAU, 32, Color(field_color.r, field_color.g, field_color.b, ring_alpha), 1.5)

	# Outer casing (hexagonal look)
	draw_rect(Rect2(-half, -half, NODE_SIZE, NODE_SIZE), NODE_COLOR.darkened(0.3), true)
	draw_rect(Rect2(-half, -half, NODE_SIZE, NODE_SIZE), NODE_COLOR, false, 2.0)

	# Inner sphere
	var inner_r: float = half * 0.5
	draw_circle(Vector2.ZERO, inner_r, field_color.darkened(0.3))
	draw_arc(Vector2.ZERO, inner_r, 0, TAU, 16, field_color, 2.0)

	# Polarity symbol
	var sym_color := Color.WHITE
	if is_repel:
		# Outward arrows
		for angle in [0, PI / 2.0, PI, 3 * PI / 2.0]:
			var dir := Vector2.RIGHT.rotated(angle)
			draw_line(dir * 4, dir * 10, sym_color, 1.5)
	else:
		# Inward arrows
		for angle in [0, PI / 2.0, PI, 3 * PI / 2.0]:
			var dir := Vector2.RIGHT.rotated(angle)
			draw_line(dir * 10, dir * 4, sym_color, 1.5)
			draw_line(dir * 4 + dir.rotated(0.4) * 3, dir * 4, sym_color, 1.0)
			draw_line(dir * 4 + dir.rotated(-0.4) * 3, dir * 4, sym_color, 1.0)

	# Label
	var label_text: String = "Gravity (Pull)" if not is_repel else "Gravity (Push)"
	draw_string(ThemeDB.fallback_font, Vector2(-28, -half - 8),
		label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	var half := NODE_SIZE / 2.0
	return Rect2(-half - 12, -half - 20, NODE_SIZE + 24, NODE_SIZE + 40)


func _get_component_type() -> String:
	return "gravity_node"
