class_name SoundForge
extends MachineComponent

## Converts energy into musical tones. Visual note display.
## Input: Energy. Output: Signal. Parameters: pitch, volume.

const FORGE_SIZE: float = 50.0
const FORGE_COLOR := Color(0.5, 0.35, 0.2)
const NOTE_COLOR := Color(1.0, 0.7, 0.2)

var _energy_in: float = 0.0
var _note_time: float = 0.0
var _notes: Array[Dictionary] = []


func _setup_ports() -> void:
	add_port("energy_in", Port.PortType.ENERGY, Port.Direction.INPUT, Vector2(-FORGE_SIZE / 2.0 - 12, 0))
	add_port("signal_out", Port.PortType.SIGNAL, Port.Direction.OUTPUT, Vector2(FORGE_SIZE / 2.0 + 12, 0))


func _setup_parameters() -> void:
	register_parameter("pitch", "Pitch", 50.0, 0.0, 100.0, 1.0)
	register_parameter("volume", "Volume", 70.0, 10.0, 100.0, 1.0)


func _on_input_received(_port: Port, data: Variant) -> void:
	if data is Dictionary:
		_energy_in = data.get("energy", 0.0)


func _process_component(delta: float) -> void:
	var pitch: float = get_parameter("pitch") / 100.0
	var volume: float = get_parameter("volume") / 100.0
	_note_time += delta

	# Spawn visual notes based on energy
	if current_state == State.ACTIVE and _energy_in > 0.1:
		if fmod(_note_time, 0.3 + (1.0 - pitch) * 0.5) < delta:
			_notes.append({
				"x": randf_range(-10.0, 10.0),
				"y": 0.0,
				"life": 0.0,
				"type": randi_range(0, 2),
			})

	# Update notes
	var alive_notes: Array[Dictionary] = []
	for note in _notes:
		note["life"] += delta
		note["y"] -= delta * 30.0 * (0.5 + pitch)
		if note["life"] < 1.5:
			alive_notes.append(note)
	_notes = alive_notes

	# Output signal proportional to energy and volume
	var out_signal: float = _energy_in * volume
	send_output("signal_out", {"signal": clampf(out_signal, 0.0, 1.0)})
	_energy_in = 0.0
	queue_redraw()


func reset_component() -> void:
	super.reset_component()
	_energy_in = 0.0
	_note_time = 0.0
	_notes.clear()
	queue_redraw()


func _draw_component() -> void:
	var half := FORGE_SIZE / 2.0

	# Anvil body
	draw_rect(Rect2(-half, -half * 0.6, FORGE_SIZE, FORGE_SIZE * 0.6), FORGE_COLOR.darkened(0.4), true)
	draw_rect(Rect2(-half, -half * 0.6, FORGE_SIZE, FORGE_SIZE * 0.6), FORGE_COLOR, false, 2.0)

	# Base
	draw_rect(Rect2(-half * 0.7, half * 0.0, FORGE_SIZE * 0.7, half * 0.5), FORGE_COLOR.darkened(0.5), true)

	# Hammer
	var hammer_y: float = -half * 0.6 - 6.0 + sin(_note_time * 8.0) * 4.0
	draw_rect(Rect2(-6, hammer_y - 4, 12, 8), Color(0.6, 0.6, 0.65), true)
	draw_line(Vector2(0, hammer_y + 4), Vector2(0, -half * 0.6), Color(0.5, 0.5, 0.5), 2.0)

	# Musical notes floating up
	for note in _notes:
		var alpha: float = 1.0 - note["life"] / 1.5
		var nc: Color = Color(NOTE_COLOR.r, NOTE_COLOR.g, NOTE_COLOR.b, alpha)
		var nx: float = note["x"]
		var ny: float = note["y"] - half
		match note["type"]:
			0:  # Quarter note
				draw_circle(Vector2(nx, ny), 3.0, nc)
				draw_line(Vector2(nx + 3, ny), Vector2(nx + 3, ny - 10), nc, 1.5)
			1:  # Eighth note
				draw_circle(Vector2(nx, ny), 3.0, nc)
				draw_line(Vector2(nx + 3, ny), Vector2(nx + 3, ny - 10), nc, 1.5)
				draw_line(Vector2(nx + 3, ny - 10), Vector2(nx + 7, ny - 7), nc, 1.5)
			2:  # Double note
				draw_circle(Vector2(nx - 3, ny), 2.5, nc)
				draw_circle(Vector2(nx + 3, ny), 2.5, nc)
				draw_line(Vector2(nx - 0.5, ny), Vector2(nx - 0.5, ny - 8), nc, 1.5)
				draw_line(Vector2(nx + 5.5, ny), Vector2(nx + 5.5, ny - 8), nc, 1.5)

	draw_string(ThemeDB.fallback_font, Vector2(-28, -half - 14),
		"Sound Forge", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))


func _get_bounds() -> Rect2:
	var half := FORGE_SIZE / 2.0
	return Rect2(-half - 12, -half - 26, FORGE_SIZE + 24, FORGE_SIZE + 50)


func _get_component_type() -> String:
	return "sound_forge"
