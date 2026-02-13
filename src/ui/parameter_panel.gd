class_name ParameterPanel
extends PanelContainer

## Side panel showing parameter sliders for the selected component.

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var param_container: VBoxContainer = $MarginContainer/VBoxContainer/ParamContainer
@onready var delete_button: Button = $MarginContainer/VBoxContainer/DeleteButton

signal delete_requested(component: MachineComponent)

var _current_component: MachineComponent = null
var _sliders: Dictionary = {}  # {param_name: HSlider}
var _read_only: bool = false


func _ready() -> void:
	visible = false
	delete_button.pressed.connect(_on_delete_pressed)


## Show parameters for a component
func show_for(component: MachineComponent) -> void:
	_current_component = component
	_clear_params()
	_build_params(component)
	title_label.text = component.component_name
	visible = true


## Hide the panel
func hide_panel() -> void:
	_current_component = null
	_clear_params()
	visible = false


func _clear_params() -> void:
	for child in param_container.get_children():
		child.queue_free()
	_sliders.clear()


func _build_params(component: MachineComponent) -> void:
	for param_name in component.parameters:
		var param: Dictionary = component.parameters[param_name]
		_add_slider(param_name, param)


func _add_slider(param_name: String, param: Dictionary) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)

	# Label row with name and value
	var label_row := HBoxContainer.new()

	var label := Label.new()
	label.text = param["label"]
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_row.add_child(label)

	var value_label := Label.new()
	value_label.text = _format_value(param["value"], param.get("step", 0.1))
	value_label.name = "ValueLabel"
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size.x = 40
	label_row.add_child(value_label)

	row.add_child(label_row)

	# Slider
	var slider := HSlider.new()
	slider.min_value = param["min"]
	slider.max_value = param["max"]
	slider.step = param.get("step", 0.1)
	slider.value = param["value"]
	slider.custom_minimum_size.y = 20

	slider.value_changed.connect(_on_slider_changed.bind(param_name, value_label, param.get("step", 0.1)))
	_sliders[param_name] = slider

	row.add_child(slider)
	param_container.add_child(row)


func _on_slider_changed(value: float, param_name: String, value_label: Label, step: float) -> void:
	if _current_component:
		_current_component.set_parameter(param_name, value)
		value_label.text = _format_value(value, step)


func _format_value(value: float, step: float) -> String:
	if step >= 1.0:
		return str(int(value))
	elif step >= 0.1:
		return "%.1f" % value
	else:
		return "%.2f" % value


## Set read-only mode (disables sliders and delete button)
func set_read_only(value: bool) -> void:
	_read_only = value
	for slider: HSlider in _sliders.values():
		slider.editable = not value
	delete_button.disabled = value


func _on_delete_pressed() -> void:
	if _current_component and not _read_only:
		delete_requested.emit(_current_component)
		hide_panel()
