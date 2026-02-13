class_name ChronoSpring
extends MachineComponent

## Stores energy over time, then releases in a burst.
## Input: Energy. Output: Energy. Parameters: delay, charge_rate.

const CHRONO_SIZE: float = 48.0
const CHRONO_COLOR := Color(0.3, 0.5, 0.5)
const TIME_COLOR := Color(0.2, 0.9, 0.8)

var _charge: float = 0.0
var _release_timer: float = 0.0
var _is_releasing: bool = false
var _clock_angle: float = 0.0


func _setup_ports() -> void:
	add_port("energy_in", Port.PortType.ENERGY, Port.Direction.INPUT, Vector2(-CHRONO_SIZE / 2.0 - 12, 0))
	add_port("energy_out", Port.PortType.ENERGY, Port.Direction.OUTPUT, Vector2(CHRONO_SIZE / 2.0 + 12, 0))


func _setup_parameters() -> void:
	register_parameter("delay", "Delay (s)", 2.0, 0.5, 5.0, 0.1)
	register_parameter("charge_rate", "Charge Rate", 50.0, 10.0, 100.0, 1.0)


func _on_input_received(_port: Port, data: Variant) -> void:
	if data is Dictionary:
		var energy: float = data.get("energy", 0.0)
		var rate: float = get_parameter("charge_rate") / 100.0
		_charge = clampf(_charge + energy * rate * 0.1, 0.0, 1.0)


func _process_component(delta: float) -> void:
	var delay: float = get_parameter("delay")

	_clock_angle += delta * 60.0
	if _clock_angle > 360.0:
		_clock_angle -= 360.0

	if _charge >= 0.95 and not _is_releasing:
		_is_releasing = true
		_release_timer = 0.0

	if _is_releasing:
		_release_timer += delta
		if _release_timer >= delay:
			send_output("energy_out", {"energy": _charge})
			_charge = 0.0
			_is_releasing = false
			_release_timer = 0.0
	elif _charge > 0.01:
		# Trickle output while charging
		send_output("energy_out", {"energy": _charge * 0.05})

	queue_redraw()


func reset_component() -> void:
	super.reset_component()
	_charge = 0.0
	_release_timer = 0.0
	_is_releasing = false
	_clock_angle = 0.0
	queue_redraw()


func _draw_component() -> void:
	var half := CHRONO_SIZE / 2.0

	# Housing
	draw_rect(Rect2(-half, -half, CHRONO_SIZE, CHRONO_SIZE), CHRONO_COLOR.darkened(0.4), true)
	draw_rect(Rect2(-half, -half, CHRONO_SIZE, CHRONO_SIZE), CHRONO_COLOR, false, 2.0)

	# Clock face
	var clock_r: float = half * 0.6
	draw_arc(Vector2.ZERO, clock_r, 0, TAU, 24, TIME_COLOR.darkened(0.2), 1.5)

	# Clock hand
	var hand_angle: float = deg_to_rad(_clock_angle)
	var hand_end: Vector2 = Vector2.UP.rotated(hand_angle) * clock_r * 0.8
	draw_line(Vector2.ZERO, hand_end, TIME_COLOR, 2.0)
	draw_circle(Vector2.ZERO, 3.0, TIME_COLOR)

	# Charge bar
	var bar_y: float = half - 6
	draw_rect(Rect2(-half + 4, bar_y, CHRONO_SIZE - 8, 4), Color(0.15, 0.15, 0.2), true)
	var fill_w: float = (CHRONO_SIZE - 8) * _charge
	var bar_color: Color = TIME_COLOR if not _is_releasing else Color(1.0, 0.8, 0.2)
	draw_rect(Rect2(-half + 4, bar_y, fill_w, 4), bar_color, true)

	# Release flash
	if _is_releasing:
		var flash_alpha: float = (sin(_release_timer * 8.0) + 1.0) / 2.0 * 0.3
		draw_circle(Vector2.ZERO, half * 0.8, Color(TIME_COLOR.r, TIME_COLOR.g, TIME_COLOR.b, flash_alpha))

	draw_string(ThemeDB.fallback_font, Vector2(-28, -half - 8),
		"Chrono Spring", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	var half := CHRONO_SIZE / 2.0
	return Rect2(-half - 12, -half - 20, CHRONO_SIZE + 24, CHRONO_SIZE + 40)


func _get_component_type() -> String:
	return "chrono_spring"
