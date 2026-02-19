extends Control

## Main menu with Discovery, Inventor, My Machines, Settings, and stats dashboard.

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var discovery_button: Button = $VBoxContainer/ButtonContainer/DiscoveryButton
@onready var inventor_button: Button = $VBoxContainer/ButtonContainer/InventorButton
@onready var machines_button: Button = $VBoxContainer/ButtonContainer/MachinesButton
@onready var sandbox_button: Button = $VBoxContainer/ButtonContainer/SandboxButton
@onready var settings_button: Button = $VBoxContainer/ButtonContainer/SettingsButton
@onready var stars_label: Label = $VBoxContainer/StarsLabel

var _stats_panel: PanelContainer = null
var _achievement_toast: PanelContainer = null


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.06, 0.07, 0.1))
	discovery_button.pressed.connect(_on_discovery_pressed)
	inventor_button.pressed.connect(_on_inventor_pressed)
	machines_button.pressed.connect(_on_machines_pressed)
	sandbox_button.pressed.connect(_on_sandbox_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	_update_stars()
	_build_stats_panel()
	_build_achievement_toast()
	ProgressManager.achievement_unlocked.connect(_on_achievement_unlocked)


func _update_stars() -> void:
	var total: int = ProgressManager.get_total_stars()
	if total > 0:
		stars_label.text = "Total Stars: %d" % total
	else:
		stars_label.text = ""


func _build_stats_panel() -> void:
	_stats_panel = PanelContainer.new()
	_stats_panel.anchors_preset = Control.PRESET_BOTTOM_LEFT
	_stats_panel.anchor_left = 0.0
	_stats_panel.anchor_bottom = 1.0
	_stats_panel.offset_left = 16
	_stats_panel.offset_bottom = -16
	_stats_panel.offset_top = -140
	_stats_panel.offset_right = 220

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.11, 0.15, 0.85)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	_stats_panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	var header := Label.new()
	header.text = "Progress"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	vbox.add_child(header)

	var levels_done: int = ProgressManager.get_completed_level_count()
	var worlds_done: int = ProgressManager.get_completed_world_count()
	var components: int = ProgressManager.get_unlocked_components().size()
	var total_comps: int = ComponentRegistry.get_all_types().size()
	var achievements: int = ProgressManager.get_unlocked_achievements().size()
	var total_achievements: int = ProgressManager.get_achievement_definitions().size()
	var inventions: int = InventionManager.list_inventions().size()

	var stats: Array[String] = [
		"Levels: %d / 16" % levels_done,
		"Worlds: %d / 4" % worlds_done,
		"Components: %d / %d" % [components, total_comps],
		"Achievements: %d / %d" % [achievements, total_achievements],
		"Inventions: %d" % inventions,
	]

	for stat in stats:
		var label := Label.new()
		label.text = stat
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
		vbox.add_child(label)

	_stats_panel.add_child(vbox)
	add_child(_stats_panel)


func _build_achievement_toast() -> void:
	_achievement_toast = PanelContainer.new()
	_achievement_toast.anchors_preset = Control.PRESET_TOP_RIGHT
	_achievement_toast.anchor_right = 1.0
	_achievement_toast.offset_right = -16
	_achievement_toast.offset_left = -280
	_achievement_toast.offset_top = 16
	_achievement_toast.offset_bottom = 72
	_achievement_toast.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.25, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 3
	style.border_color = Color(0.8, 0.6, 1.0)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_achievement_toast.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var toast_header := Label.new()
	toast_header.name = "ToastHeader"
	toast_header.text = "Achievement Unlocked!"
	toast_header.add_theme_font_size_override("font_size", 11)
	toast_header.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	vbox.add_child(toast_header)

	var toast_name := Label.new()
	toast_name.name = "ToastName"
	toast_name.text = ""
	toast_name.add_theme_font_size_override("font_size", 14)
	toast_name.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(toast_name)

	_achievement_toast.add_child(vbox)
	add_child(_achievement_toast)


func _on_achievement_unlocked(achievement_id: String) -> void:
	var defs: Array[Dictionary] = ProgressManager.get_achievement_definitions()
	for adef in defs:
		if adef["id"] == achievement_id:
			_show_achievement_toast(adef["name"], adef["desc"])
			break


func _show_achievement_toast(aname: String, desc: String) -> void:
	var name_label: Label = _achievement_toast.get_node("VBoxContainer/ToastName")
	name_label.text = "%s — %s" % [aname, desc]
	_achievement_toast.visible = true
	_achievement_toast.modulate = Color.WHITE

	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(_achievement_toast, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void: _achievement_toast.visible = false)


func _on_discovery_pressed() -> void:
	SceneTransition.change_scene("res://src/scenes/menus/world_select.tscn")


func _on_inventor_pressed() -> void:
	SceneTransition.change_scene("res://src/scenes/inventor/purpose_selector.tscn")


func _on_machines_pressed() -> void:
	SceneTransition.change_scene("res://src/scenes/inventor/machine_gallery.tscn")


func _on_sandbox_pressed() -> void:
	# Free Build = Inventor Mode with all components, no purpose selector
	InventionManager.set_meta("free_build", true)
	SceneTransition.change_scene("res://src/scenes/inventor/inventor_mode.tscn")


func _on_settings_pressed() -> void:
	SceneTransition.change_scene("res://src/scenes/menus/settings.tscn")
