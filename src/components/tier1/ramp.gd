class_name Ramp
extends MachineComponent

## Angled surface. Objects roll/slide down based on angle and friction.
## No ports — pure physics interaction.
## Rotate via the "angle" parameter (handled by base class Node2D rotation).

var _body: StaticBody2D
var _collision: CollisionShape2D
var _shape: RectangleShape2D
var _physics_material: PhysicsMaterial

const RAMP_WIDTH: float = 160.0
const RAMP_HEIGHT: float = 16.0
const RAMP_COLOR := Color(0.55, 0.35, 0.15)
const RAMP_OUTLINE := Color(0.75, 0.55, 0.25)


func _setup_ports() -> void:
	pass


func _setup_parameters() -> void:
	register_parameter("angle", "Angle", 30.0, 0.0, 360.0, 5.0)
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

	# Apply initial angle via base class (sets Node2D rotation)
	rotation = deg_to_rad(30.0)


func _on_parameter_changed(param_name: String, value: float) -> void:
	if param_name == "friction":
		_physics_material.friction = value


func _draw_component() -> void:
	var half_w: float = RAMP_WIDTH / 2.0
	var half_h: float = RAMP_HEIGHT / 2.0

	# Draw flat — Node2D rotation handles the angle
	var rect := Rect2(-half_w, -half_h, RAMP_WIDTH, RAMP_HEIGHT)
	draw_rect(rect, RAMP_COLOR, true)
	draw_rect(rect, RAMP_OUTLINE, false, 2.0)

	# Surface grip lines
	var grip_count: int = 6
	for i in range(grip_count):
		var t: float = float(i + 1) / float(grip_count + 1)
		var x: float = lerpf(-half_w, half_w, t)
		draw_line(Vector2(x, -half_h + 2), Vector2(x, half_h - 2), RAMP_OUTLINE.darkened(0.2), 1.0)

	# Label
	draw_string(ThemeDB.fallback_font, Vector2(-16, -half_h - 8),
		"Ramp", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	return Rect2(-RAMP_WIDTH / 2.0 - 8, -RAMP_HEIGHT / 2.0 - 20,
		RAMP_WIDTH + 16, RAMP_HEIGHT + 40)


func _get_component_type() -> String:
	return "ramp"
