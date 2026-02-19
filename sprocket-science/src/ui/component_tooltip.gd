class_name ComponentTooltip
extends PanelContainer

## Tooltip card showing component info: name, description, ports, parameters.
## Shown when hovering over a tray button.

const PORT_TYPE_NAMES: Dictionary = {
	0: "Energy",   # Port.PortType.ENERGY
	1: "Flow",     # Port.PortType.FLOW
	2: "Signal",   # Port.PortType.SIGNAL
}
const PORT_TYPE_COLORS: Dictionary = {
	0: Color(1.0, 0.85, 0.2),   # Energy = yellow
	1: Color(0.3, 0.7, 1.0),    # Flow = blue
	2: Color(0.3, 1.0, 0.5),    # Signal = green
}

var _vbox: VBoxContainer
var _hide_timer: float = -1.0


func _ready() -> void:
	# Style the panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.3, 0.35, 0.5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", style)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 6)
	add_child(_vbox)

	mouse_filter = Control.MOUSE_FILTER_PASS
	visible = false


func _process(delta: float) -> void:
	if _hide_timer > 0:
		_hide_timer -= delta
		if _hide_timer <= 0:
			visible = false


## Show tooltip for a component type
func show_for_type(type_name: String, anchor_pos: Vector2) -> void:
	_hide_timer = -1.0
	_clear()

	var info: Dictionary = ComponentRegistry.get_component_info(type_name)
	if info.is_empty():
		return

	# Title
	var title := Label.new()
	title.text = info.get("display_name", type_name)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	_vbox.add_child(title)

	# Description
	var desc := Label.new()
	desc.text = info.get("description", "")
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.6, 0.65, 0.8))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 220
	_vbox.add_child(desc)

	# Tier badge
	var tier: int = info.get("tier", 1)
	var tier_label := Label.new()
	tier_label.text = "Tier %d" % tier
	tier_label.add_theme_font_size_override("font_size", 10)
	tier_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	_vbox.add_child(tier_label)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	_vbox.add_child(sep)

	# Ports — create a temporary instance to read port data
	var temp_comp: MachineComponent = ComponentRegistry.create_component(type_name)
	if temp_comp:
		# Ports section
		var ports_title := Label.new()
		ports_title.text = "Ports"
		ports_title.add_theme_font_size_override("font_size", 12)
		ports_title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
		_vbox.add_child(ports_title)

		var ports: Array[Port] = temp_comp.get_all_ports()
		for port in ports:
			var port_hbox := HBoxContainer.new()
			port_hbox.add_theme_constant_override("separation", 6)

			# Direction arrow
			var dir_label := Label.new()
			dir_label.text = ">" if port.direction == Port.Direction.INPUT else "<"
			dir_label.add_theme_font_size_override("font_size", 12)
			dir_label.add_theme_color_override("font_color", PORT_TYPE_COLORS.get(port.port_type, Color.WHITE))
			port_hbox.add_child(dir_label)

			# Port type colored dot + name
			var port_label := Label.new()
			var dir_text: String = "IN" if port.direction == Port.Direction.INPUT else "OUT"
			port_label.text = "%s (%s)" % [PORT_TYPE_NAMES.get(port.port_type, "?"), dir_text]
			port_label.add_theme_font_size_override("font_size", 11)
			port_label.add_theme_color_override("font_color", PORT_TYPE_COLORS.get(port.port_type, Color.WHITE))
			port_hbox.add_child(port_label)

			_vbox.add_child(port_hbox)

		# Parameters section
		var params: Dictionary = temp_comp.serialize()
		if not params.is_empty():
			var sep2 := HSeparator.new()
			sep2.add_theme_constant_override("separation", 4)
			_vbox.add_child(sep2)

			var params_title := Label.new()
			params_title.text = "Parameters"
			params_title.add_theme_font_size_override("font_size", 12)
			params_title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
			_vbox.add_child(params_title)

			var param_defs: Array[Dictionary] = temp_comp.get_parameter_definitions()
			for pdef in param_defs:
				var param_label := Label.new()
				param_label.text = "%s: %.0f (%.0f - %.0f)" % [
					pdef.get("display_name", pdef.get("name", "?")),
					pdef.get("default", 0),
					pdef.get("min", 0),
					pdef.get("max", 100),
				]
				param_label.add_theme_font_size_override("font_size", 10)
				param_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
				_vbox.add_child(param_label)

		# Clean up temp component
		temp_comp.queue_free()

	# Position above the anchor
	position = anchor_pos - Vector2(custom_minimum_size.x / 2.0, 0)
	visible = true

	# Force layout update, then reposition above anchor
	await get_tree().process_frame
	position = anchor_pos - Vector2(size.x / 2.0, size.y + 8)

	# Clamp to viewport
	var vp_size: Vector2 = get_viewport_rect().size
	position.x = clampf(position.x, 8, vp_size.x - size.x - 8)
	position.y = maxf(position.y, 8)


## Start a delayed hide (so tooltip doesn't flicker when moving between buttons)
func start_hide(delay: float = 0.15) -> void:
	_hide_timer = delay


## Cancel hide timer
func cancel_hide() -> void:
	_hide_timer = -1.0


func _clear() -> void:
	for child in _vbox.get_children():
		child.queue_free()
