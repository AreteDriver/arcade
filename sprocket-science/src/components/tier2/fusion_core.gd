class_name FusionCore
extends MachineComponent

## Power source that generates energy.
## Output: Energy. Parameters: output_level, stability.
## When output_level exceeds stability, enters OVERLOADED state.

const CORE_SIZE: float = 56.0
const CORE_COLOR := Color(0.7, 0.4, 0.1)
const CORE_GLOW := Color(1.0, 0.7, 0.2)
const OVERLOAD_COLOR := Color(1.0, 0.2, 0.1)

var _pulse_time: float = 0.0
var _overload_timer: float = 0.0
const OVERLOAD_DELAY: float = 2.0


func _setup_ports() -> void:
	add_port("energy_out", Port.PortType.ENERGY, Port.Direction.OUTPUT, Vector2(CORE_SIZE / 2.0 + 12, 0))


func _setup_parameters() -> void:
	register_parameter("output_level", "Output Level", 50.0, 0.0, 100.0, 1.0)
	register_parameter("stability", "Stability", 70.0, 20.0, 100.0, 1.0)


func _process_component(delta: float) -> void:
	var output_level: float = get_parameter("output_level")
	var stability: float = get_parameter("stability")

	_pulse_time += delta * (1.0 + output_level / 50.0)

	# Check overload condition
	if output_level > stability:
		_overload_timer += delta
		if _overload_timer >= OVERLOAD_DELAY and current_state != State.OVERLOADED:
			set_state(State.OVERLOADED)
	else:
		_overload_timer = 0.0
		if current_state == State.OVERLOADED:
			set_state(State.ACTIVE)

	# Send energy output (reduced when overloaded)
	var output_mult: float = 0.3 if current_state == State.OVERLOADED else 1.0
	send_output("energy_out", {"energy": output_level / 100.0 * output_mult})

	queue_redraw()


func reset_component() -> void:
	super.reset_component()
	_pulse_time = 0.0
	_overload_timer = 0.0
	queue_redraw()


func _draw_component() -> void:
	var half := CORE_SIZE / 2.0

	# Outer casing
	draw_rect(Rect2(-half, -half, CORE_SIZE, CORE_SIZE), CORE_COLOR.darkened(0.4), true)
	draw_rect(Rect2(-half, -half, CORE_SIZE, CORE_SIZE), CORE_COLOR, false, 2.5)

	# Inner core glow
	var pulse: float = (sin(_pulse_time * 3.0) + 1.0) / 2.0
	var inner_radius: float = half * 0.55
	var glow_color: Color
	if current_state == State.OVERLOADED:
		glow_color = OVERLOAD_COLOR.lerp(Color.WHITE, pulse * 0.4)
	else:
		glow_color = CORE_GLOW.lerp(CORE_GLOW.lightened(0.3), pulse)

	# Glow halo
	var halo_alpha: float = 0.15 + pulse * 0.1
	draw_circle(Vector2.ZERO, inner_radius + 8, Color(glow_color.r, glow_color.g, glow_color.b, halo_alpha))

	# Core sphere
	draw_circle(Vector2.ZERO, inner_radius, glow_color.darkened(0.2))
	draw_arc(Vector2.ZERO, inner_radius, 0, TAU, 24, glow_color, 2.0)

	# Highlight
	draw_circle(Vector2(-inner_radius * 0.3, -inner_radius * 0.3), inner_radius * 0.2,
		glow_color.lightened(0.4))

	# Corner brackets (decorative)
	var bracket_len: float = 10.0
	var bracket_color := CORE_COLOR.lightened(0.2)
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var cx: float = corner.x * (half - 2)
		var cy: float = corner.y * (half - 2)
		draw_line(Vector2(cx, cy), Vector2(cx - corner.x * bracket_len, cy), bracket_color, 1.5)
		draw_line(Vector2(cx, cy), Vector2(cx, cy - corner.y * bracket_len), bracket_color, 1.5)

	# Overload warning indicator
	if _overload_timer > 0 and current_state != State.OVERLOADED:
		var warn_alpha: float = clampf(_overload_timer / OVERLOAD_DELAY, 0.0, 1.0)
		draw_rect(Rect2(-half, -half, CORE_SIZE, CORE_SIZE),
			Color(1.0, 0.2, 0.1, warn_alpha * 0.2), true)

	# Output level bar
	var bar_x: float = -half + 4
	var bar_w: float = CORE_SIZE - 8
	var bar_h: float = 4.0
	var bar_y: float = half - 8
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.2, 0.2, 0.25), true)
	var fill_w: float = bar_w * get_parameter("output_level") / 100.0
	var fill_color := OVERLOAD_COLOR if get_parameter("output_level") > get_parameter("stability") else CORE_GLOW
	draw_rect(Rect2(bar_x, bar_y, fill_w, bar_h), fill_color, true)
	# Stability marker
	var stab_x: float = bar_x + bar_w * get_parameter("stability") / 100.0
	draw_line(Vector2(stab_x, bar_y - 2), Vector2(stab_x, bar_y + bar_h + 2), Color.WHITE, 1.0)

	# Label
	draw_string(ThemeDB.fallback_font, Vector2(-24, -half - 8),
		"Fusion Core", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	var half := CORE_SIZE / 2.0
	return Rect2(-half - 12, -half - 20, CORE_SIZE + 24, CORE_SIZE + 40)


func _get_component_type() -> String:
	return "fusion_core"
