class_name SimulationControls
extends HBoxContainer

## Play / Pause / Reset buttons for simulation control.

signal zoom_to_fit_pressed()
signal trace_toggled(enabled: bool)

var _play_button: Button
var _pause_button: Button
var _reset_button: Button
var _fit_button: Button
var _trace_button: Button
var _status_label: Label
var _trace_active: bool = false


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 8)

	_play_button = _create_button("Play", Color(0.2, 0.7, 0.3))
	_pause_button = _create_button("Pause", Color(0.8, 0.7, 0.2))
	_reset_button = _create_button("Reset", Color(0.7, 0.3, 0.2))
	_fit_button = _create_button("Fit", Color(0.3, 0.5, 0.7))
	_trace_button = _create_button("Trace", Color(0.6, 0.4, 0.8))

	_status_label = Label.new()
	_status_label.text = "STOPPED"
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	add_child(_status_label)

	_play_button.pressed.connect(_on_play)
	_pause_button.pressed.connect(_on_pause)
	_reset_button.pressed.connect(_on_reset)
	_fit_button.pressed.connect(_on_fit)
	_trace_button.pressed.connect(_on_trace)

	_pause_button.disabled = true
	_reset_button.disabled = true

	SimulationManager.simulation_state_changed.connect(_on_state_changed)


func _create_button(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(72, 36)

	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.3)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_bottom = 2
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = color
	button.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate()
	hover_style.bg_color = color.darkened(0.15)
	button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate()
	pressed_style.bg_color = color.darkened(0.4)
	button.add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style := style.duplicate()
	disabled_style.bg_color = Color(0.2, 0.2, 0.25)
	disabled_style.border_color = Color(0.3, 0.3, 0.35)
	button.add_theme_stylebox_override("disabled", disabled_style)

	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 13)

	add_child(button)
	return button


func _on_play() -> void:
	SimulationManager.play()


func _on_pause() -> void:
	SimulationManager.pause()


func _on_reset() -> void:
	SimulationManager.stop()


func _on_fit() -> void:
	zoom_to_fit_pressed.emit()


func _on_trace() -> void:
	_trace_active = not _trace_active
	_update_trace_button()
	trace_toggled.emit(_trace_active)


func _update_trace_button() -> void:
	var color := Color(0.6, 0.4, 0.8)
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_bottom = 2
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	if _trace_active:
		style.bg_color = color
		style.border_color = color.lightened(0.3)
	else:
		style.bg_color = color.darkened(0.3)
		style.border_color = color
	_trace_button.add_theme_stylebox_override("normal", style)


func _on_state_changed(new_state: SimulationManager.SimState) -> void:
	match new_state:
		SimulationManager.SimState.STOPPED:
			_play_button.disabled = false
			_pause_button.disabled = true
			_reset_button.disabled = true
			_status_label.text = "STOPPED"
			_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))

		SimulationManager.SimState.PLAYING:
			_play_button.disabled = true
			_pause_button.disabled = false
			_reset_button.disabled = false
			_status_label.text = "RUNNING"
			_status_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))

		SimulationManager.SimState.PAUSED:
			_play_button.disabled = false
			_pause_button.disabled = true
			_reset_button.disabled = false
			_status_label.text = "PAUSED"
			_status_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
