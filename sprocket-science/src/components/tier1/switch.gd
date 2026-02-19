class_name Switch
extends MachineComponent

## Trigger that emits a signal when a RigidBody2D enters its area.
## Output: Signal. Parameters: mode (0=toggle, 1=momentary).
## Toggle mode: stays on after first trigger. Momentary: on only while body present.

const SWITCH_SIZE: float = 40.0
const SWITCH_COLOR := Color(0.15, 0.6, 0.3)
const SWITCH_ACCENT := Color(0.2, 1.0, 0.5)
const TRIGGER_RADIUS: float = 36.0

var _trigger_area: Area2D
var _is_triggered: bool = false
var _bodies_in_area: int = 0


func _setup_ports() -> void:
	add_port("signal_out", Port.PortType.SIGNAL, Port.Direction.OUTPUT, Vector2(SWITCH_SIZE / 2.0 + 12, 0))


func _setup_parameters() -> void:
	register_parameter("mode", "Mode (0=Toggle 1=Moment)", 0.0, 0.0, 1.0, 1.0)

	# Trigger area detects RigidBody2D entering
	_trigger_area = Area2D.new()
	_trigger_area.collision_layer = 0
	_trigger_area.collision_mask = 1
	add_child(_trigger_area)

	var shape := CircleShape2D.new()
	shape.radius = TRIGGER_RADIUS
	var col := CollisionShape2D.new()
	col.shape = shape
	_trigger_area.add_child(col)

	_trigger_area.body_entered.connect(_on_body_entered)
	_trigger_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is RigidBody2D and current_state == State.ACTIVE:
		_bodies_in_area += 1
		_is_triggered = true
		queue_redraw()


func _on_body_exited(body: Node2D) -> void:
	if body is RigidBody2D and current_state == State.ACTIVE:
		_bodies_in_area = maxi(_bodies_in_area - 1, 0)
		# Momentary mode: turn off when no bodies present
		if int(get_parameter("mode")) == 1 and _bodies_in_area == 0:
			_is_triggered = false
			queue_redraw()


func _process_component(_delta: float) -> void:
	if _is_triggered:
		send_output("signal_out", {"triggered": true, "strength": 1.0})


func reset_component() -> void:
	super.reset_component()
	_is_triggered = false
	_bodies_in_area = 0
	queue_redraw()


func _draw_component() -> void:
	var half := SWITCH_SIZE / 2.0

	# Base plate
	draw_rect(Rect2(-half, -half, SWITCH_SIZE, SWITCH_SIZE), SWITCH_COLOR.darkened(0.3), true)
	draw_rect(Rect2(-half, -half, SWITCH_SIZE, SWITCH_SIZE), SWITCH_COLOR, false, 2.0)

	# Trigger zone indicator (dashed circle)
	var segments: int = 16
	for i in range(segments):
		if i % 2 == 0:
			var a1: float = TAU * float(i) / float(segments)
			var a2: float = TAU * float(i + 1) / float(segments)
			var p1 := Vector2.RIGHT.rotated(a1) * TRIGGER_RADIUS
			var p2 := Vector2.RIGHT.rotated(a2) * TRIGGER_RADIUS
			draw_line(p1, p2, SWITCH_COLOR.lightened(0.2), 1.0)

	# Button in center
	var button_color: Color = SWITCH_ACCENT if _is_triggered else SWITCH_COLOR.lightened(0.1)
	draw_circle(Vector2.ZERO, 10.0, button_color)
	draw_arc(Vector2.ZERO, 10.0, 0, TAU, 16, button_color.lightened(0.3), 1.5)

	# Mode indicator
	var mode_text: String = "T" if int(get_parameter("mode")) == 0 else "M"
	draw_string(ThemeDB.fallback_font, Vector2(-4, 4),
		mode_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)

	# Label
	draw_string(ThemeDB.fallback_font, Vector2(-16, -half - 8),
		"Switch", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	return Rect2(-TRIGGER_RADIUS - 4, -TRIGGER_RADIUS - 16, TRIGGER_RADIUS * 2 + 8, TRIGGER_RADIUS * 2 + 32)


func _get_component_type() -> String:
	return "switch"
