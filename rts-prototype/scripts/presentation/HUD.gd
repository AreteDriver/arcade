extends CanvasLayer
class_name HUD
## HUD.gd - Main game UI
## Displays selection info, resources, capture points, and reinforcement buttons.

@export var selection_manager: SelectionManager

# UI References (created in _ready)
var _supply_label: Label
var _score_player_label: Label
var _score_enemy_label: Label
var _tickets_player_label: Label
var _tickets_enemy_label: Label

var _capture_point_container: HBoxContainer
var _capture_point_displays: Dictionary = {}  # point_id -> Control

var _selection_panel: PanelContainer
var _selection_type_label: Label
var _selection_hp_bar: ProgressBar
var _selection_state_label: Label

var _reinforce_panel: VBoxContainer
var _infantry_button: Button
var _support_button: Button
var _vehicle_button: Button
var _cooldown_label: Label

var _victory_overlay: Control
var _victory_label: Label


func _ready() -> void:
	layer = 5
	_build_ui()
	_connect_signals()


func _process(_delta: float) -> void:
	_update_supply_display()
	_update_scores_display()
	_update_capture_points_display()
	_update_selection_panel()
	_update_reinforce_panel()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_build_top_bar(root)
	_build_capture_point_bar(root)
	_build_selection_panel(root)
	_build_reinforce_panel(root)
	_build_victory_overlay(root)


func _build_top_bar(root: Control) -> void:
	var top_bar := HBoxContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size.y = 50
	top_bar.add_theme_constant_override("separation", 30)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	panel.add_theme_stylebox_override("panel", style)
	top_bar.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 50)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	# Supply
	var supply_box := HBoxContainer.new()
	var supply_icon := Label.new()
	supply_icon.text = "SUPPLY: "
	supply_icon.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	supply_box.add_child(supply_icon)

	_supply_label = Label.new()
	_supply_label.text = "100"
	_supply_label.add_theme_font_size_override("font_size", 20)
	supply_box.add_child(_supply_label)
	hbox.add_child(supply_box)

	# Player Score
	var player_score_box := VBoxContainer.new()
	player_score_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var player_label := Label.new()
	player_label.text = "PLAYER"
	player_label.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
	player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_score_box.add_child(player_label)

	var player_stats := HBoxContainer.new()
	_score_player_label = Label.new()
	_score_player_label.text = "0"
	_score_player_label.add_theme_font_size_override("font_size", 24)
	player_stats.add_child(_score_player_label)

	var sep1 := Label.new()
	sep1.text = " | "
	player_stats.add_child(sep1)

	_tickets_player_label = Label.new()
	_tickets_player_label.text = "200"
	_tickets_player_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	player_stats.add_child(_tickets_player_label)

	player_score_box.add_child(player_stats)
	hbox.add_child(player_score_box)

	# Enemy Score
	var enemy_score_box := VBoxContainer.new()
	enemy_score_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var enemy_label := Label.new()
	enemy_label.text = "ENEMY"
	enemy_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_score_box.add_child(enemy_label)

	var enemy_stats := HBoxContainer.new()
	_score_enemy_label = Label.new()
	_score_enemy_label.text = "0"
	_score_enemy_label.add_theme_font_size_override("font_size", 24)
	enemy_stats.add_child(_score_enemy_label)

	var sep2 := Label.new()
	sep2.text = " | "
	enemy_stats.add_child(sep2)

	_tickets_enemy_label = Label.new()
	_tickets_enemy_label.text = "200"
	_tickets_enemy_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	enemy_stats.add_child(_tickets_enemy_label)

	enemy_score_box.add_child(enemy_stats)
	hbox.add_child(enemy_score_box)

	root.add_child(top_bar)


func _build_capture_point_bar(root: Control) -> void:
	var bar := HBoxContainer.new()
	bar.position = Vector2(0, 60)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size.y = 40
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 20)

	_capture_point_container = bar
	root.add_child(bar)


func _build_selection_panel(root: Control) -> void:
	_selection_panel = PanelContainer.new()
	_selection_panel.position = Vector2(10, 0)
	_selection_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_selection_panel.custom_minimum_size = Vector2(250, 100)
	_selection_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.9)
	style.set_corner_radius_all(5)
	_selection_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)

	_selection_type_label = Label.new()
	_selection_type_label.text = "Infantry Squad"
	_selection_type_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_selection_type_label)

	var hp_label := Label.new()
	hp_label.text = "HP"
	hp_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(hp_label)

	_selection_hp_bar = ProgressBar.new()
	_selection_hp_bar.custom_minimum_size.x = 200
	_selection_hp_bar.max_value = 100
	_selection_hp_bar.value = 100
	_selection_hp_bar.show_percentage = true
	vbox.add_child(_selection_hp_bar)

	_selection_state_label = Label.new()
	_selection_state_label.text = "Idle"
	_selection_state_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(_selection_state_label)

	_selection_panel.add_child(vbox)
	root.add_child(_selection_panel)


func _build_reinforce_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(-10, 0)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.custom_minimum_size = Vector2(180, 150)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.9)
	style.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", style)

	_reinforce_panel = VBoxContainer.new()
	_reinforce_panel.add_theme_constant_override("separation", 5)

	var title := Label.new()
	title.text = "REINFORCEMENTS"
	title.add_theme_font_size_override("font_size", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reinforce_panel.add_child(title)

	_infantry_button = Button.new()
	_infantry_button.text = "Infantry (50)"
	_infantry_button.pressed.connect(_on_infantry_pressed)
	_reinforce_panel.add_child(_infantry_button)

	_support_button = Button.new()
	_support_button.text = "Support (60)"
	_support_button.pressed.connect(_on_support_pressed)
	_reinforce_panel.add_child(_support_button)

	_vehicle_button = Button.new()
	_vehicle_button.text = "Vehicle (100)"
	_vehicle_button.pressed.connect(_on_vehicle_pressed)
	_reinforce_panel.add_child(_vehicle_button)

	_cooldown_label = Label.new()
	_cooldown_label.text = "Ready"
	_cooldown_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	_cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reinforce_panel.add_child(_cooldown_label)

	panel.add_child(_reinforce_panel)
	root.add_child(panel)


func _build_victory_overlay(root: Control) -> void:
	_victory_overlay = Control.new()
	_victory_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_victory_overlay.visible = false

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	_victory_overlay.add_child(bg)

	_victory_label = Label.new()
	_victory_label.set_anchors_preset(Control.PRESET_CENTER)
	_victory_label.text = "VICTORY"
	_victory_label.add_theme_font_size_override("font_size", 72)
	_victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_victory_overlay.add_child(_victory_label)

	root.add_child(_victory_overlay)


func _connect_signals() -> void:
	GameState.match_ended.connect(_on_match_ended)

	if selection_manager:
		selection_manager.selection_changed.connect(_on_selection_changed)


func _update_supply_display() -> void:
	var supply := Economy.get_supply(GameState.Team.PLAYER)
	_supply_label.text = str(supply)


func _update_scores_display() -> void:
	_score_player_label.text = str(GameState.team_scores[GameState.Team.PLAYER])
	_score_enemy_label.text = str(GameState.team_scores[GameState.Team.ENEMY])
	_tickets_player_label.text = str(GameState.team_tickets[GameState.Team.PLAYER])
	_tickets_enemy_label.text = str(GameState.team_tickets[GameState.Team.ENEMY])


func _update_capture_points_display() -> void:
	for point in GameState.capture_points:
		if not is_instance_valid(point):
			continue

		var point_id: String = point.point_id if point.has_method("get_team") else "?"

		if point_id not in _capture_point_displays:
			_create_capture_point_display(point)

		var display: Control = _capture_point_displays[point_id]
		_update_single_capture_display(display, point)


func _create_capture_point_display(point: Node3D) -> void:
	var point_id: String = point.point_id

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(60, 30)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.3, 0.3, 0.8)
	style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = point_id
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.name = "Label"
	panel.add_child(label)

	_capture_point_container.add_child(panel)
	_capture_point_displays[point_id] = panel


func _update_single_capture_display(display: Control, point: Node3D) -> void:
	var style := display.get_theme_stylebox("panel") as StyleBoxFlat
	var label := display.get_node("Label") as Label

	if point.is_contested:
		style.bg_color = Color(0.8, 0.6, 0.1, 0.9)
		label.add_theme_color_override("font_color", Color.BLACK)
	elif point.owning_team == GameState.Team.PLAYER:
		style.bg_color = Color(0.2, 0.5, 1.0, 0.9)
		label.add_theme_color_override("font_color", Color.WHITE)
	elif point.owning_team == GameState.Team.ENEMY:
		style.bg_color = Color(1.0, 0.2, 0.2, 0.9)
		label.add_theme_color_override("font_color", Color.WHITE)
	else:
		style.bg_color = Color(0.4, 0.4, 0.4, 0.9)
		label.add_theme_color_override("font_color", Color.WHITE)


func _update_selection_panel() -> void:
	if not selection_manager:
		return

	var selected := selection_manager.get_selected_squads()

	if selected.is_empty():
		_selection_panel.visible = false
		return

	_selection_panel.visible = true
	var squad: Squad = selected[0]

	if selected.size() == 1:
		_selection_type_label.text = squad.get_type_name() + " Squad"
	else:
		_selection_type_label.text = "%d Squads Selected" % selected.size()

	_selection_hp_bar.max_value = squad.max_health
	_selection_hp_bar.value = squad.current_health
	_selection_state_label.text = "Status: " + squad.get_state_name()


func _update_reinforce_panel() -> void:
	var player_team := GameState.Team.PLAYER
	var supply := Economy.get_supply(player_team)
	var cooldown := Economy.get_cooldown(player_team)

	_infantry_button.disabled = not Economy.can_reinforce(player_team, GameState.SquadType.INFANTRY)
	_support_button.disabled = not Economy.can_reinforce(player_team, GameState.SquadType.SUPPORT)
	_vehicle_button.disabled = not Economy.can_reinforce(player_team, GameState.SquadType.VEHICLE)

	if cooldown > 0:
		_cooldown_label.text = "Cooldown: %.1fs" % cooldown
		_cooldown_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	else:
		_cooldown_label.text = "Ready"
		_cooldown_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))


func _on_selection_changed(selected: Array[Node3D]) -> void:
	# Panel visibility handled in _update_selection_panel
	pass


func _on_match_ended(winning_team: int) -> void:
	_victory_overlay.visible = true
	if winning_team == GameState.Team.PLAYER:
		_victory_label.text = "VICTORY"
		_victory_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		_victory_label.text = "DEFEAT"
		_victory_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))


func _on_infantry_pressed() -> void:
	_spawn_reinforcement(GameState.SquadType.INFANTRY)


func _on_support_pressed() -> void:
	_spawn_reinforcement(GameState.SquadType.SUPPORT)


func _on_vehicle_pressed() -> void:
	_spawn_reinforcement(GameState.SquadType.VEHICLE)


func _spawn_reinforcement(squad_type: int) -> void:
	var spawn_pos := GameState.get_spawn_position_for_team(GameState.Team.PLAYER)
	Economy.request_reinforcement(GameState.Team.PLAYER, squad_type, spawn_pos)
