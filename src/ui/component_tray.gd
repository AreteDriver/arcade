class_name ComponentTray
extends PanelContainer

## Bottom tray showing available components. Drag to place on canvas.

signal component_drag_started(type_name: String)

@onready var container: HBoxContainer = $MarginContainer/HBoxContainer

const TRAY_BUTTON_SIZE := Vector2(72, 72)
const TRAY_COLORS: Dictionary = {
	"ramp": Color(0.55, 0.35, 0.15),
	"pipe": Color(0.2, 0.5, 0.7),
	"fan": Color(0.5, 0.5, 0.6),
}
const TRAY_ICONS: Dictionary = {
	"ramp": "/",
	"pipe": "=",
	"fan": "*",
}


func _ready() -> void:
	_build_tray()


func _build_tray() -> void:
	# Clear existing buttons
	for child in container.get_children():
		child.queue_free()

	var types: Array[String] = ComponentRegistry.get_all_types()
	for type_name in types:
		var info: Dictionary = ComponentRegistry.get_component_info(type_name)
		_add_tray_button(type_name, info)


func _add_tray_button(type_name: String, info: Dictionary) -> void:
	var button := Button.new()
	button.custom_minimum_size = TRAY_BUTTON_SIZE
	button.tooltip_text = info.get("description", "")

	# Style the button
	var style := StyleBoxFlat.new()
	style.bg_color = TRAY_COLORS.get(type_name, Color(0.3, 0.3, 0.35))
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = TRAY_COLORS.get(type_name, Color(0.5, 0.5, 0.55)).lightened(0.3)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	button.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate()
	hover_style.bg_color = style.bg_color.lightened(0.15)
	button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate()
	pressed_style.bg_color = style.bg_color.darkened(0.1)
	button.add_theme_stylebox_override("pressed", pressed_style)

	# Label with icon and name
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_label := Label.new()
	icon_label.text = TRAY_ICONS.get(type_name, "?")
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 24)
	icon_label.add_theme_color_override("font_color", Color.WHITE)
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_label)

	var name_label := Label.new()
	name_label.text = info.get("display_name", type_name)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	button.add_child(vbox)
	button.pressed.connect(_on_button_pressed.bind(type_name))

	container.add_child(button)


func _on_button_pressed(type_name: String) -> void:
	component_drag_started.emit(type_name)


## Refresh the tray (e.g., after unlocking new components)
func refresh() -> void:
	_build_tray()
