class_name TestObjectTray
extends PanelContainer

## Small toolbar for spawning test objects during simulation.
## Appears when simulation starts, hides when stopped.

signal spawn_requested(object_type: String)

const OBJECT_TYPES: Array[Dictionary] = [
	{"type": "ball", "label": "Ball", "icon": "o", "color": Color(1.0, 0.4, 0.3)},
	{"type": "block", "label": "Block", "icon": "#", "color": Color(0.5, 0.4, 0.3)},
]

var _container: HBoxContainer


func _ready() -> void:
	# Panel style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.3, 0.5, 0.4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	add_theme_stylebox_override("panel", style)

	_container = HBoxContainer.new()
	_container.add_theme_constant_override("separation", 6)
	add_child(_container)

	# Title
	var title := Label.new()
	title.text = "Test:"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.5, 0.7, 0.55))
	_container.add_child(title)

	# Spawn buttons
	for obj_info: Dictionary in OBJECT_TYPES:
		_add_spawn_button(obj_info)

	visible = false


func _add_spawn_button(obj_info: Dictionary) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(56, 40)
	button.tooltip_text = "Spawn a %s" % obj_info["label"].to_lower()

	# Style
	var style := StyleBoxFlat.new()
	style.bg_color = obj_info.get("color", Color(0.3, 0.3, 0.35)).darkened(0.4)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = obj_info.get("color", Color(0.5, 0.5, 0.55)).lightened(0.1)
	button.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate()
	hover.bg_color = style.bg_color.lightened(0.15)
	button.add_theme_stylebox_override("hover", hover)

	var pressed := style.duplicate()
	pressed.bg_color = style.bg_color.darkened(0.1)
	button.add_theme_stylebox_override("pressed", pressed)

	# Label layout
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_label := Label.new()
	icon_label.text = obj_info.get("icon", "?")
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 16)
	icon_label.add_theme_color_override("font_color", obj_info.get("color", Color.WHITE))
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_label)

	var name_label := Label.new()
	name_label.text = obj_info["label"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	button.add_child(vbox)
	button.pressed.connect(_on_spawn_pressed.bind(obj_info["type"]))
	_container.add_child(button)


func _on_spawn_pressed(object_type: String) -> void:
	spawn_requested.emit(object_type)
