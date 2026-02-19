class_name EmotionSensor
extends MachineComponent

## Reacts to screen tap patterns. Rapid taps = excited, slow = calm.
## Input: Signal. Output: Signal. Parameters: sensitivity, response_time.

const SENSOR_SIZE: float = 48.0
const SENSOR_COLOR := Color(0.6, 0.3, 0.4)
const HAPPY_COLOR := Color(1.0, 0.8, 0.2)
const CALM_COLOR := Color(0.3, 0.6, 0.9)
const EXCITED_COLOR := Color(1.0, 0.3, 0.5)

var _tap_count: int = 0
var _tap_timer: float = 0.0
var _emotion_level: float = 0.0  # 0 = calm, 1 = excited
var _signal_in: float = 0.0
var _face_blink: float = 0.0
var _output_value: float = 0.0


func _setup_ports() -> void:
	add_port("signal_in", Port.PortType.SIGNAL, Port.Direction.INPUT, Vector2(-SENSOR_SIZE / 2.0 - 12, 0))
	add_port("signal_out", Port.PortType.SIGNAL, Port.Direction.OUTPUT, Vector2(SENSOR_SIZE / 2.0 + 12, 0))


func _setup_parameters() -> void:
	register_parameter("sensitivity", "Sensitivity", 50.0, 10.0, 100.0, 1.0)
	register_parameter("response_time", "Response", 50.0, 10.0, 100.0, 1.0)


func _on_input_received(_port: Port, data: Variant) -> void:
	if data is Dictionary:
		_signal_in = data.get("signal", 0.0)


func _process_component(delta: float) -> void:
	var sensitivity: float = get_parameter("sensitivity") / 100.0
	var response: float = get_parameter("response_time") / 100.0

	# Signal input acts like taps
	if _signal_in > 0.5:
		_tap_count += 1
		_tap_timer = 0.0

	_tap_timer += delta
	if _tap_timer > 1.0:
		_tap_count = maxi(_tap_count - 1, 0)
		_tap_timer = 0.0

	# Emotion level based on tap frequency
	var target_emotion: float = clampf(float(_tap_count) * sensitivity * 0.2, 0.0, 1.0)
	_emotion_level = lerpf(_emotion_level, target_emotion, delta * response * 5.0)

	_output_value = _emotion_level
	send_output("signal_out", {"signal": _output_value})

	_face_blink += delta
	_signal_in = 0.0
	queue_redraw()


func reset_component() -> void:
	super.reset_component()
	_tap_count = 0
	_tap_timer = 0.0
	_emotion_level = 0.0
	_signal_in = 0.0
	_face_blink = 0.0
	_output_value = 0.0
	queue_redraw()


func _draw_component() -> void:
	var half := SENSOR_SIZE / 2.0
	var emotion_color: Color = CALM_COLOR.lerp(EXCITED_COLOR, _emotion_level)

	# Body
	draw_circle(Vector2.ZERO, half, SENSOR_COLOR.darkened(0.3))
	draw_arc(Vector2.ZERO, half, 0, TAU, 24, SENSOR_COLOR, 2.0)

	# Face
	var eye_y: float = -6.0
	var eye_spread: float = 10.0
	var blink: bool = fmod(_face_blink, 3.0) < 0.15

	# Eyes
	if not blink:
		var eye_h: float = lerpf(3.0, 5.0, _emotion_level)
		draw_circle(Vector2(-eye_spread, eye_y), eye_h, emotion_color)
		draw_circle(Vector2(eye_spread, eye_y), eye_h, emotion_color)
	else:
		draw_line(Vector2(-eye_spread - 3, eye_y), Vector2(-eye_spread + 3, eye_y), emotion_color, 2.0)
		draw_line(Vector2(eye_spread - 3, eye_y), Vector2(eye_spread + 3, eye_y), emotion_color, 2.0)

	# Mouth — changes with emotion
	var mouth_y: float = 8.0
	if _emotion_level < 0.3:
		# Calm — small line
		draw_line(Vector2(-5, mouth_y), Vector2(5, mouth_y), emotion_color, 2.0)
	elif _emotion_level < 0.7:
		# Happy — small smile
		draw_arc(Vector2(0, mouth_y - 2), 6.0, 0.2, PI - 0.2, 8, emotion_color, 2.0)
	else:
		# Excited — big open mouth
		draw_arc(Vector2(0, mouth_y - 4), 8.0, 0.1, PI - 0.1, 10, emotion_color, 2.0)
		draw_line(Vector2(-7, mouth_y - 2), Vector2(7, mouth_y - 2), emotion_color, 1.5)

	# Emotion aura
	if current_state == State.ACTIVE and _emotion_level > 0.1:
		var aura_r: float = half + 4.0 + _emotion_level * 6.0
		var aura_alpha: float = _emotion_level * 0.2
		draw_arc(Vector2.ZERO, aura_r, 0, TAU, 20,
			Color(emotion_color.r, emotion_color.g, emotion_color.b, aura_alpha), 1.5)

	draw_string(ThemeDB.fallback_font, Vector2(-28, -half - 8),
		"Emotion", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	var half := SENSOR_SIZE / 2.0
	return Rect2(-half - 12, -half - 20, SENSOR_SIZE + 24, SENSOR_SIZE + 40)


func _get_component_type() -> String:
	return "emotion_sensor"
