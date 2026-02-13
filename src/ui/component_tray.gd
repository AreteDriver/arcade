class_name ComponentTray
extends PanelContainer

## Bottom tray showing available components. Drag to place on canvas.

signal component_drag_started(type_name: String)

@onready var container: HBoxContainer = $MarginContainer/HBoxContainer

var _tooltip: ComponentTooltip = null

const TRAY_BUTTON_SIZE := Vector2(72, 72)
const TRAY_COLORS: Dictionary = {
	"ramp": Color(0.55, 0.35, 0.15),
	"pipe": Color(0.2, 0.5, 0.7),
	"fan": Color(0.5, 0.5, 0.6),
	"switch": Color(0.15, 0.6, 0.3),
	"conveyor": Color(0.35, 0.35, 0.4),
	"valve": Color(0.5, 0.3, 0.5),
	"fusion_core": Color(0.7, 0.4, 0.1),
	"gravity_node": Color(0.3, 0.2, 0.6),
	"gear": Color(0.55, 0.55, 0.6),
	"spring": Color(0.2, 0.6, 0.4),
	"plasma_conduit": Color(0.6, 0.2, 0.7),
	"quantum_coupler": Color(0.2, 0.4, 0.7),
	"chrono_spring": Color(0.3, 0.5, 0.5),
	"phase_gate": Color(0.4, 0.3, 0.6),
	"warp_belt": Color(0.2, 0.5, 0.5),
	"holo_projector": Color(0.25, 0.3, 0.5),
	"dimensional_splitter": Color(0.5, 0.2, 0.6),
	"time_loop_relay": Color(0.3, 0.4, 0.5),
	"emotion_sensor": Color(0.6, 0.3, 0.4),
	"sound_forge": Color(0.5, 0.35, 0.2),
	"cloud_weaver": Color(0.4, 0.45, 0.6),
}
const TRAY_ICONS: Dictionary = {
	"ramp": "/",
	"pipe": "=",
	"fan": "*",
	"switch": "!",
	"conveyor": ">",
	"valve": "V",
	"fusion_core": "@",
	"gravity_node": "G",
	"gear": "O",
	"spring": "~",
	"plasma_conduit": "P",
	"quantum_coupler": "Q",
	"chrono_spring": "T",
	"phase_gate": "#",
	"warp_belt": "W",
	"holo_projector": "H",
	"dimensional_splitter": "D",
	"time_loop_relay": "L",
	"emotion_sensor": "E",
	"sound_forge": "S",
	"cloud_weaver": "C",
}

## Optional filter: when set, only these types are shown
var _available_types: Array[String] = []


func _ready() -> void:
	_tooltip = ComponentTooltip.new()
	# Tooltip lives on a CanvasLayer so it renders above everything
	var tooltip_layer := CanvasLayer.new()
	tooltip_layer.layer = 15
	add_child(tooltip_layer)
	tooltip_layer.add_child(_tooltip)
	_build_tray()


func _build_tray() -> void:
	# Clear existing buttons
	for child in container.get_children():
		child.queue_free()

	var types: Array[String] = ComponentRegistry.get_all_types()
	for type_name in types:
		if _available_types.size() > 0 and type_name not in _available_types:
			continue
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
	button.mouse_entered.connect(_on_button_hover.bind(type_name, button))
	button.mouse_exited.connect(_on_button_unhover)

	container.add_child(button)


func _on_button_pressed(type_name: String) -> void:
	if _tooltip:
		_tooltip.visible = false
	component_drag_started.emit(type_name)


func _on_button_hover(type_name: String, button: Button) -> void:
	if _tooltip:
		_tooltip.cancel_hide()
		var btn_rect: Rect2 = button.get_global_rect()
		var anchor: Vector2 = Vector2(btn_rect.get_center().x, btn_rect.position.y)
		_tooltip.show_for_type(type_name, anchor)


func _on_button_unhover() -> void:
	if _tooltip:
		_tooltip.start_hide(0.2)


## Refresh the tray (e.g., after unlocking new components)
func refresh() -> void:
	_build_tray()


## Filter the tray to only show specific component types.
## Pass an empty array to show all types (default).
func set_available_types(types: Array[String]) -> void:
	_available_types = types
	_build_tray()
