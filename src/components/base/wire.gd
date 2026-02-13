class_name Wire
extends Line2D

## Visual connection between two ports.
## Color-coded by port type with animated flow indicator.

var source_port: Port = null
var target_port: Port = null

## Flow animation
var _flow_offset: float = 0.0
var _flow_speed: float = 80.0
var _active: bool = false

## Dash pattern for flow animation
var _dash_length: float = 12.0
var _gap_length: float = 8.0


func _ready() -> void:
	width = 3.0
	default_color = Color.WHITE
	z_index = -1  # Draw behind components
	antialiased = true


func setup(source: Port, target: Port) -> void:
	source_port = source
	target_port = target
	default_color = source.get_color()
	_update_points()


## Update wire endpoints to follow ports
func _process(delta: float) -> void:
	if source_port == null or target_port == null:
		return
	_update_points()

	if _active:
		_flow_offset += _flow_speed * delta
		if _flow_offset > _dash_length + _gap_length:
			_flow_offset -= _dash_length + _gap_length
		queue_redraw()


func _update_points() -> void:
	var start: Vector2 = source_port.global_position
	var end: Vector2 = target_port.global_position

	# Create a smooth curve between ports
	var mid_x: float = (start.x + end.x) / 2.0
	var control1 := Vector2(mid_x, start.y)
	var control2 := Vector2(mid_x, end.y)

	clear_points()
	var steps: int = 20
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var p: Vector2 = _cubic_bezier(start, control1, control2, end, t)
		add_point(p)


func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u: float = 1.0 - t
	return u * u * u * p0 + 3.0 * u * u * t * p1 + 3.0 * u * t * t * p2 + t * t * t * p3


func set_active(active: bool) -> void:
	_active = active
	if active:
		width = 4.0
		default_color = source_port.get_color().lightened(0.15) if source_port else Color.WHITE
	else:
		width = 3.0
		default_color = source_port.get_color() if source_port else Color.WHITE


func _draw() -> void:
	if not _active or get_point_count() < 2:
		return

	# Draw animated flow dots along the wire
	var color: Color = source_port.get_color().lightened(0.4) if source_port else Color.WHITE
	var total_length: float = 0.0
	var segment_lengths: Array[float] = []
	for i in range(get_point_count() - 1):
		var seg_len: float = get_point_position(i).distance_to(get_point_position(i + 1))
		segment_lengths.append(seg_len)
		total_length += seg_len

	# Place dots at intervals along the path
	var interval: float = _dash_length + _gap_length
	var pos_along: float = fmod(_flow_offset, interval)
	while pos_along < total_length:
		var world_pos: Vector2 = _get_point_at_distance(pos_along, segment_lengths)
		draw_circle(world_pos - global_position, 3.0, color)
		pos_along += interval


func _get_point_at_distance(dist: float, seg_lengths: Array[float]) -> Vector2:
	var accumulated: float = 0.0
	for i in range(seg_lengths.size()):
		if accumulated + seg_lengths[i] >= dist:
			var t: float = (dist - accumulated) / seg_lengths[i] if seg_lengths[i] > 0 else 0.0
			return get_point_position(i).lerp(get_point_position(i + 1), t)
		accumulated += seg_lengths[i]
	return get_point_position(get_point_count() - 1)


## Disconnect and clean up
func remove_wire() -> void:
	if source_port:
		source_port.disconnect_port()
	source_port = null
	target_port = null
	queue_free()
