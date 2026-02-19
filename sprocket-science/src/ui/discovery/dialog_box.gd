class_name DialogBox
extends CanvasLayer

## Modal text overlay for intro/success dialogs.
## Shows an array of strings, tap to advance, emits dialog_finished.

signal dialog_finished()

var _lines: Array[String] = []
var _current_index: int = 0
var _is_showing: bool = false

var _panel: PanelContainer
var _label: Label
var _continue_label: Label
var _bg: ColorRect


func _ready() -> void:
	layer = 20
	visible = false
	_build_ui()


func _build_ui() -> void:
	# Semi-transparent background
	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.0, 0.6)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	# Dialog panel centered
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -280
	_panel.offset_right = 280
	_panel.offset_top = -80
	_panel.offset_bottom = 80

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.13, 0.18, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.3, 0.6, 0.9, 0.6)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	vbox.add_child(_label)

	_continue_label = Label.new()
	_continue_label.text = "Tap to continue..."
	_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_label.add_theme_font_size_override("font_size", 11)
	_continue_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	vbox.add_child(_continue_label)

	_panel.add_child(vbox)
	add_child(_panel)


## Show a sequence of dialog lines
func show_dialog(lines: Array[String]) -> void:
	if lines.is_empty():
		dialog_finished.emit()
		return
	_lines = lines
	_current_index = 0
	_is_showing = true
	_label.text = _lines[0]
	_update_continue_text()
	visible = true


func _update_continue_text() -> void:
	if _current_index >= _lines.size() - 1:
		_continue_label.text = "Tap to close"
	else:
		_continue_label.text = "Tap to continue..."


func _unhandled_input(event: InputEvent) -> void:
	if not _is_showing:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		_advance()
		get_viewport().set_input_as_handled()


func _advance() -> void:
	_current_index += 1
	if _current_index >= _lines.size():
		_is_showing = false
		visible = false
		dialog_finished.emit()
	else:
		_label.text = _lines[_current_index]
		_update_continue_text()


## Check if dialog is currently showing
func is_showing() -> bool:
	return _is_showing
