class_name TestBlock
extends RigidBody2D

## A heavier block for testing machines.
## Spawned from the test object tray during simulation.

const BLOCK_SIZE: Vector2 = Vector2(14, 14)

static var _color_index: int = 0
const BLOCK_COLORS: Array[Color] = [
	Color(0.6, 0.4, 0.2),   # brown
	Color(0.4, 0.4, 0.5),   # slate
	Color(0.3, 0.5, 0.3),   # dark green
	Color(0.5, 0.3, 0.4),   # mauve
	Color(0.35, 0.35, 0.55), # indigo
]

var block_color: Color = Color.WHITE


func _init() -> void:
	block_color = BLOCK_COLORS[_color_index % BLOCK_COLORS.size()]
	_color_index += 1

	mass = 1.5
	gravity_scale = 1.0
	linear_damp = 0.2
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.15
	physics_material_override.friction = 0.7

	# Collision layer 1
	collision_layer = 1
	collision_mask = 1

	var shape := RectangleShape2D.new()
	shape.size = BLOCK_SIZE
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _draw() -> void:
	var half := BLOCK_SIZE / 2.0
	var rect := Rect2(-half, BLOCK_SIZE)

	# Filled box
	draw_rect(rect, block_color, true)
	# Top highlight edge
	draw_line(Vector2(-half.x + 1, -half.y + 1), Vector2(half.x - 1, -half.y + 1),
		block_color.lightened(0.3), 1.5)
	# Outline
	draw_rect(rect, block_color.darkened(0.3), false, 1.0)
