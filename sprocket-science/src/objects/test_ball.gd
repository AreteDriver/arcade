class_name TestBall
extends RigidBody2D

## A small bouncy ball for testing machines.
## Spawned from the test object tray during simulation.

const RADIUS: float = 6.0

## Cycle through a few fun colors
static var _color_index: int = 0
const BALL_COLORS: Array[Color] = [
	Color(1.0, 0.4, 0.3),   # red-orange
	Color(0.3, 0.8, 1.0),   # cyan
	Color(1.0, 0.85, 0.2),  # yellow
	Color(0.5, 1.0, 0.4),   # lime
	Color(1.0, 0.5, 0.9),   # pink
]

var ball_color: Color = Color.WHITE


func _init() -> void:
	ball_color = BALL_COLORS[_color_index % BALL_COLORS.size()]
	_color_index += 1

	mass = 0.5
	gravity_scale = 1.0
	linear_damp = 0.3
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.5
	physics_material_override.friction = 0.4

	# Collision layer 1 — matches all Area2D masks in components
	collision_layer = 1
	collision_mask = 1

	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _draw() -> void:
	# Filled circle
	draw_circle(Vector2.ZERO, RADIUS, ball_color)
	# Highlight arc
	draw_arc(Vector2.ZERO, RADIUS - 1.5, -0.8, 0.8, 8, ball_color.lightened(0.4), 1.5)
	# Outline
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 16, ball_color.darkened(0.3), 1.0)
