class_name Ramp
extends MachineComponent

## Angled surface. Objects roll/slide down based on angle and friction.
## No ports — pure physics interaction.

var _body: StaticBody2D
var _collision: CollisionShape2D
var _shape: RectangleShape2D
var _physics_material: PhysicsMaterial

const RAMP_WIDTH: float = 160.0
const RAMP_HEIGHT: float = 16.0
const RAMP_COLOR := Color(0.55, 0.35, 0.15)
const RAMP_OUTLINE := Color(0.75, 0.55, 0.25)


func _setup_ports() -> void:
	# Ramp has no ports — pure physics object
	pass


func _setup_parameters() -> void:
	register_parameter("angle", "Angle", 30.0, 0.0, 80.0, 1.0)
	register_parameter("friction", "Friction", 0.5, 0.0, 1.0, 0.05)

	_physics_material = PhysicsMaterial.new()
	_physics_material.friction = 0.5

	_shape = RectangleShape2D.new()
	_shape.size = Vector2(RAMP_WIDTH, RAMP_HEIGHT)

	_body = StaticBody2D.new()
	_body.physics_material_override = _physics_material
	add_child(_body)

	_collision = CollisionShape2D.new()
	_collision.shape = _shape
	_body.add_child(_collision)

	_apply_angle(30.0)


func _on_parameter_changed(param_name: String, value: float) -> void:
	match param_name:
		"angle":
			_apply_angle(value)
		"friction":
			_physics_material.friction = value


func _apply_angle(degrees: float) -> void:
	_body.rotation = deg_to_rad(degrees)


func _draw_component() -> void:
	var angle_rad: float = deg_to_rad(get_parameter("angle"))

	# Draw the ramp body rotated
	var half_w: float = RAMP_WIDTH / 2.0
	var half_h: float = RAMP_HEIGHT / 2.0

	var corners: PackedVector2Array = [
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h),
	]

	# Rotate corners
	var rotated: PackedVector2Array = []
	for corner in corners:
		rotated.append(corner.rotated(angle_rad))

	draw_colored_polygon(rotated, RAMP_COLOR)

	# Outline
	for i in range(rotated.size()):
		var next: int = (i + 1) % rotated.size()
		draw_line(rotated[i], rotated[next], RAMP_OUTLINE, 2.0)

	# Surface grip lines
	var grip_count: int = 6
	for i in range(grip_count):
		var t: float = float(i + 1) / float(grip_count + 1)
		var x: float = lerpf(-half_w, half_w, t)
		var p1 := Vector2(x, -half_h + 2).rotated(angle_rad)
		var p2 := Vector2(x, half_h - 2).rotated(angle_rad)
		draw_line(p1, p2, RAMP_OUTLINE.darkened(0.2), 1.0)

	# Label
	draw_string(ThemeDB.fallback_font, Vector2(-16, -RAMP_HEIGHT - 8),
		"Ramp", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	return Rect2(-RAMP_WIDTH / 2.0 - 8, -RAMP_WIDTH / 2.0 - 8,
		RAMP_WIDTH + 16, RAMP_WIDTH + 16)


func _get_component_type() -> String:
	return "ramp"
