class_name Wire
extends Line2D

## Visual connection between two ports.
## Color-coded by port type with animated flow dots and glow layer.

var source_port: Port = null
var target_port: Port = null

## Flow animation
var _flow_offset: float = 0.0
var _flow_speed: float = 80.0
var _active: bool = false

## Glow layer (wider, semi-transparent line behind)
var _glow_line: Line2D = null

## Dot spacing
var _dot_interval: float = 20.0


func _ready() -> void:
	width = 3.0
	default_color = Color.WHITE
	z_index = -1
	antialiased = true

	# Create glow layer behind the wire
	_glow_line = Line2D.new()
	_glow_line.width = 10.0
	_glow_line.default_color = Color(1, 1, 1, 0.0)  # Invisible until active
	_glow_line.z_index = -2
	_glow_line.antialiased = true
	add_child(_glow_line)


func setup(source: Port, target: Port) -> void:
	source_port = source
	target_port = target
	var base_color: Color = source.get_color()
	default_color = base_color
	_glow_line.default_color = Color(base_color.r, base_color.g, base_color.b, 0.0)
	_update_points()


func _process(delta: float) -> void:
	if source_port == null or target_port == null:
		return
	_update_points()

	if _active:
		_flow_offset += _flow_speed * delta
		if _flow_offset > _dot_interval:
			_flow_offset -= _dot_interval
		queue_redraw()


func _update_points() -> void:
	var start: Vector2 = source_port.global_position
	var end: Vector2 = target_port.global_position

	var mid_x: float = (start.x + end.x) / 2.0
	var control1 := Vector2(mid_x, start.y)
	var control2 := Vector2(mid_x, end.y)

	clear_points()
	_glow_line.clear_points()
	var steps: int = 24
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var p: Vector2 = _cubic_bezier(start, control1, control2, end, t)
		add_point(p)
		_glow_line.add_point(p)


func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u: float = 1.0 - t
	return u * u * u * p0 + 3.0 * u * u * t * p1 + 3.0 * u * t * t * p2 + t * t * t * p3


func set_active(active: bool) -> void:
	_active = active
	var base_color: Color = source_port.get_color() if source_port else Color.WHITE
	if active:
		width = 4.0
		default_color = base_color.lightened(0.15)
		_glow_line.width = 14.0
		_glow_line.default_color = Color(base_color.r, base_color.g, base_color.b, 0.15)
	else:
		width = 3.0
		default_color = base_color
		_glow_line.width = 10.0
		_glow_line.default_color = Color(base_color.r, base_color.g, base_color.b, 0.0)


func _draw() -> void:
	if not _active or get_point_count() < 2:
		return

	# Animated flow dots along the wire
	var color: Color = source_port.get_color().lightened(0.5) if source_port else Color.WHITE
	var total_length: float = 0.0
	var segment_lengths: Array[float] = []
	for i in range(get_point_count() - 1):
		var seg_len: float = get_point_position(i).distance_to(get_point_position(i + 1))
		segment_lengths.append(seg_len)
		total_length += seg_len

	if total_length <= 0:
		return

	var pos_along: float = fmod(_flow_offset, _dot_interval)
	while pos_along < total_length:
		var world_pos: Vector2 = _get_point_at_distance(pos_along, segment_lengths)
		var local_pos: Vector2 = world_pos - global_position
		# Dot with small glow
		draw_circle(local_pos, 4.5, Color(color.r, color.g, color.b, 0.25))
		draw_circle(local_pos, 2.5, color)
		pos_along += _dot_interval


func _get_point_at_distance(dist: float, seg_lengths: Array[float]) -> Vector2:
	var accumulated: float = 0.0
	for i in range(seg_lengths.size()):
		if accumulated + seg_lengths[i] >= dist:
			var t: float = (dist - accumulated) / seg_lengths[i] if seg_lengths[i] > 0 else 0.0
			return get_point_position(i).lerp(get_point_position(i + 1), t)
		accumulated += seg_lengths[i]
	return get_point_position(get_point_count() - 1)


func remove_wire() -> void:
	if source_port:
		source_port.disconnect_port()
	source_port = null
	target_port = null
	queue_free()
