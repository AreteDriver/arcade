class_name GhostSlot
extends Node2D

## Visual placeholder showing where a missing component should go.
## Displays a dashed pulsing outline with port indicators.
## Used by incomplete challenges.

var slot_type: String = ""
var slot_connections: Array[Dictionary] = []
var _pulse_time: float = 0.0
var _filled: bool = false

const SLOT_SIZE: float = 56.0
const DASH_LENGTH: float = 8.0
const GAP_LENGTH: float = 6.0
const PULSE_SPEED: float = 2.0
const SNAP_DISTANCE: float = 48.0


func _process(delta: float) -> void:
	if not _filled:
		_pulse_time += delta * PULSE_SPEED
		queue_redraw()


func _draw() -> void:
	if _filled:
		return

	var half := SLOT_SIZE / 2.0
	var pulse: float = (sin(_pulse_time) + 1.0) / 2.0
	var alpha: float = 0.3 + pulse * 0.4
	var color := Color(0.3, 0.8, 1.0, alpha)

	# Dashed rectangle outline
	_draw_dashed_rect(Rect2(-half, -half, SLOT_SIZE, SLOT_SIZE), color, 2.0)

	# Component type hint
	if not slot_type.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(-20, 4),
			slot_type, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.8, 1.0, alpha))

	# "?" indicator
	draw_string(ThemeDB.fallback_font, Vector2(-4, -half + 14),
		"?", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 1.0, 1.0, alpha))

	# Port indicators
	for conn in slot_connections:
		var port_pos := Vector2(conn.get("offset_x", 0), conn.get("offset_y", 0))
		draw_circle(port_pos, 6.0, Color(0.5, 0.8, 1.0, alpha * 0.5))
		draw_arc(port_pos, 6.0, 0, TAU, 8, color, 1.0)


func _draw_dashed_rect(rect: Rect2, color: Color, width: float) -> void:
	var corners: Array[Vector2] = [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	]
	for i in range(4):
		_draw_dashed_line(corners[i], corners[(i + 1) % 4], color, width)


func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var direction: Vector2 = (to - from).normalized()
	var total_length: float = from.distance_to(to)
	var drawn: float = 0.0
	var drawing: bool = true

	while drawn < total_length:
		var seg_len: float = DASH_LENGTH if drawing else GAP_LENGTH
		seg_len = minf(seg_len, total_length - drawn)
		if drawing:
			var start: Vector2 = from + direction * drawn
			var end: Vector2 = from + direction * (drawn + seg_len)
			draw_line(start, end, color, width)
		drawn += seg_len
		drawing = not drawing


## Check if a component was placed close enough to fill this slot
func try_snap(component: MachineComponent) -> bool:
	if _filled:
		return false
	if component._get_component_type() != slot_type:
		return false
	var dist: float = global_position.distance_to(component.global_position)
	if dist <= SNAP_DISTANCE:
		component.global_position = global_position
		_filled = true
		queue_redraw()
		return true
	return false


## Mark this slot as filled
func set_filled(value: bool) -> void:
	_filled = value
	queue_redraw()
