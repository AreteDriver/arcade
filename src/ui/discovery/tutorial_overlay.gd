class_name TutorialOverlay
extends CanvasLayer

## Step-by-step tutorial overlay for Level 1-1.
## State machine: highlight area, show instruction, block unrelated input.
## Skippable after first completion.

signal tutorial_completed()

enum TutorialStep { HIGHLIGHT_TRAY, PLACE_COMPONENT, CONNECT_WIRE, PRESS_PLAY, DONE }

var _current_step: TutorialStep = TutorialStep.HIGHLIGHT_TRAY
var _is_active: bool = false
var _bg: ColorRect
var _instruction_label: Label
var _arrow_label: Label
var _skip_button: Button
var _highlight_rect: ColorRect


func _ready() -> void:
	layer = 15
	visible = false
	_build_ui()


func _build_ui() -> void:
	# Dim overlay (with transparent hole cut by highlight)
	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.0, 0.4)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	# Highlight area indicator
	_highlight_rect = ColorRect.new()
	_highlight_rect.color = Color(0.2, 0.7, 1.0, 0.15)
	_highlight_rect.size = Vector2(200, 80)
	_highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_highlight_rect)

	# Instruction text
	_instruction_label = Label.new()
	_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instruction_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_instruction_label.offset_top = 80
	_instruction_label.offset_left = -200
	_instruction_label.offset_right = 200
	_instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_instruction_label.add_theme_font_size_override("font_size", 16)
	_instruction_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

	var label_bg := StyleBoxFlat.new()
	label_bg.bg_color = Color(0.1, 0.12, 0.18, 0.9)
	label_bg.corner_radius_top_left = 8
	label_bg.corner_radius_top_right = 8
	label_bg.corner_radius_bottom_left = 8
	label_bg.corner_radius_bottom_right = 8
	label_bg.content_margin_left = 16
	label_bg.content_margin_right = 16
	label_bg.content_margin_top = 12
	label_bg.content_margin_bottom = 12
	_instruction_label.add_theme_stylebox_override("normal", label_bg)
	add_child(_instruction_label)

	# Arrow indicator
	_arrow_label = Label.new()
	_arrow_label.text = "v"
	_arrow_label.add_theme_font_size_override("font_size", 24)
	_arrow_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	_arrow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_arrow_label)

	# Skip button
	_skip_button = Button.new()
	_skip_button.text = "Skip Tutorial"
	_skip_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_button.offset_left = -120
	_skip_button.offset_top = -40
	_skip_button.offset_right = -8
	_skip_button.offset_bottom = -8
	_skip_button.add_theme_font_size_override("font_size", 11)
	_skip_button.pressed.connect(_on_skip_pressed)
	add_child(_skip_button)


## Start the tutorial
func start_tutorial() -> void:
	_is_active = true
	_current_step = TutorialStep.HIGHLIGHT_TRAY
	visible = true
	_update_step()


## Notify the tutorial that an action occurred
func notify_action(action: String) -> void:
	if not _is_active:
		return

	match _current_step:
		TutorialStep.HIGHLIGHT_TRAY:
			# Tray button was clicked
			if action == "tray_clicked":
				_advance_step()
		TutorialStep.PLACE_COMPONENT:
			if action == "component_placed":
				_advance_step()
		TutorialStep.CONNECT_WIRE:
			if action == "wire_created":
				_advance_step()
		TutorialStep.PRESS_PLAY:
			if action == "simulation_started":
				_advance_step()


func _advance_step() -> void:
	var next_step: int = _current_step + 1
	if next_step > TutorialStep.DONE:
		next_step = TutorialStep.DONE
	_current_step = next_step as TutorialStep
	_update_step()


func _update_step() -> void:
	match _current_step:
		TutorialStep.HIGHLIGHT_TRAY:
			_instruction_label.text = "Pick a component from the tray below!"
			_highlight_rect.position = Vector2(440, 632)
			_highlight_rect.size = Vector2(400, 88)
			_arrow_label.position = Vector2(630, 610)
			_arrow_label.text = "v"

		TutorialStep.PLACE_COMPONENT:
			_instruction_label.text = "Click on the canvas to place it!"
			_highlight_rect.position = Vector2(200, 200)
			_highlight_rect.size = Vector2(880, 400)
			_arrow_label.position = Vector2(630, 380)
			_arrow_label.text = "v"

		TutorialStep.CONNECT_WIRE:
			_instruction_label.text = "Drag from an output port to an input port to connect!"
			_highlight_rect.position = Vector2(200, 200)
			_highlight_rect.size = Vector2(880, 400)
			_arrow_label.position = Vector2(630, 190)
			_arrow_label.text = "~"

		TutorialStep.PRESS_PLAY:
			_instruction_label.text = "Press PLAY to start the machine!"
			_highlight_rect.position = Vector2(490, 24)
			_highlight_rect.size = Vector2(300, 40)
			_arrow_label.position = Vector2(630, 66)
			_arrow_label.text = "^"

		TutorialStep.DONE:
			_complete_tutorial()


func _complete_tutorial() -> void:
	_is_active = false
	visible = false
	tutorial_completed.emit()


func _on_skip_pressed() -> void:
	_complete_tutorial()


## Check if tutorial is active
func is_active() -> bool:
	return _is_active
