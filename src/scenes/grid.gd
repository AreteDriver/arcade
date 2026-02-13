class_name WorkshopGrid
extends Node2D

## Draws a subtle background grid for the machine canvas.

var grid_size: int = 32
var grid_color := Color(0.15, 0.18, 0.25)
var grid_accent_color := Color(0.18, 0.22, 0.3)
var grid_extent: int = 4000  # How far the grid extends


func _draw() -> void:
	var half := grid_extent

	# Minor grid lines
	var x: int = -half
	while x <= half:
		var alpha: float = grid_color.a
		if x % (grid_size * 4) == 0:
			draw_line(Vector2(x, -half), Vector2(x, half), grid_accent_color, 1.0)
		else:
			draw_line(Vector2(x, -half), Vector2(x, half), grid_color, 0.5)
		x += grid_size

	var y: int = -half
	while y <= half:
		if y % (grid_size * 4) == 0:
			draw_line(Vector2(-half, y), Vector2(half, y), grid_accent_color, 1.0)
		else:
			draw_line(Vector2(-half, y), Vector2(half, y), grid_color, 0.5)
		y += grid_size

	# Origin crosshair
	draw_line(Vector2(-16, 0), Vector2(16, 0), Color(0.4, 0.4, 0.5), 1.5)
	draw_line(Vector2(0, -16), Vector2(0, 16), Color(0.4, 0.4, 0.5), 1.5)
