extends Control

## Level selection screen showing 4 level cards per world.
## Each card shows challenge type, stars, and lock state.

const CHALLENGE_LABELS: Dictionary = {
	"incomplete": "Build It!",
	"miscalibrated": "Tune It!",
	"broken": "Fix It!",
	"overloaded": "Balance It!",
}
const CHALLENGE_COLORS: Dictionary = {
	"incomplete": Color(0.3, 0.7, 0.9),
	"miscalibrated": Color(0.9, 0.7, 0.2),
	"broken": Color(0.9, 0.3, 0.3),
	"overloaded": Color(0.8, 0.4, 0.9),
}

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var card_container: HBoxContainer = $VBoxContainer/CardContainer
@onready var back_button: Button = $VBoxContainer/BackButton

var _world: int = 1
var _definitions: Array[MachineDefinition] = []


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.06, 0.07, 0.1))
	_world = LevelSelectData.selected_world
	title_label.text = "World %d — Levels" % _world
	back_button.pressed.connect(_on_back_pressed)
	_load_definitions()
	_build_level_cards()


func _load_definitions() -> void:
	_definitions.clear()
	for level in range(1, 5):
		var path: String = "res://content/machines/world%d/level_%d_%d.tres" % [_world, _world, level]
		if ResourceLoader.exists(path):
			var def: MachineDefinition = load(path) as MachineDefinition
			if def:
				_definitions.append(def)
		else:
			_definitions.append(null)


func _build_level_cards() -> void:
	for child in card_container.get_children():
		child.queue_free()

	for i in range(4):
		var level_num: int = i + 1
		var level_id: String = "%d-%d" % [_world, level_num]
		var unlocked: bool = ProgressManager.is_level_unlocked(_world, level_num)
		var stars: int = ProgressManager.get_level_stars(level_id)
		var def: MachineDefinition = _definitions[i] if i < _definitions.size() else null

		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(180, 200)

		var style := StyleBoxFlat.new()
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.border_width_bottom = 2
		style.border_width_top = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 12
		style.content_margin_bottom = 12

		if unlocked and def:
			var challenge_color: Color = CHALLENGE_COLORS.get(def.challenge_type, Color(0.4, 0.4, 0.5))
			style.bg_color = challenge_color.darkened(0.6)
			style.border_color = challenge_color
		else:
			style.bg_color = Color(0.12, 0.12, 0.16)
			style.border_color = Color(0.25, 0.25, 0.3)

		card.add_theme_stylebox_override("panel", style)

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 8)

		# Level number
		var num_label := Label.new()
		num_label.text = "%d-%d" % [_world, level_num]
		num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_label.add_theme_font_size_override("font_size", 22)
		num_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95) if unlocked else Color(0.4, 0.4, 0.45))
		vbox.add_child(num_label)

		# Machine name
		var name_label := Label.new()
		name_label.text = def.machine_name if (def and unlocked) else "???"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85) if unlocked else Color(0.35, 0.35, 0.4))
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(name_label)

		# Challenge type
		var type_label := Label.new()
		if def and unlocked:
			type_label.text = CHALLENGE_LABELS.get(def.challenge_type, "Challenge")
		else:
			type_label.text = "Locked"
		type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		type_label.add_theme_font_size_override("font_size", 11)
		var type_color: Color = Color(0.35, 0.35, 0.4)
		if def and unlocked:
			type_color = CHALLENGE_COLORS.get(def.challenge_type, Color(0.5, 0.5, 0.6))
		type_label.add_theme_color_override("font_color", type_color)
		vbox.add_child(type_label)

		# Stars
		var star_label := Label.new()
		var star_text: String = ""
		for s in range(3):
			star_text += "*" if s < stars else "-"
		star_label.text = star_text
		star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_label.add_theme_font_size_override("font_size", 18)
		star_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if stars > 0 else Color(0.3, 0.3, 0.35))
		vbox.add_child(star_label)

		# Play button
		var play_button := Button.new()
		play_button.text = "Play" if unlocked else "Locked"
		play_button.disabled = not unlocked or def == null
		play_button.custom_minimum_size = Vector2(100, 36)
		play_button.add_theme_font_size_override("font_size", 13)
		if unlocked and def:
			play_button.pressed.connect(_on_level_pressed.bind(def))
		vbox.add_child(play_button)

		card.add_child(vbox)
		card_container.add_child(card)


func _on_level_pressed(definition: MachineDefinition) -> void:
	LevelSelectData.selected_definition = definition
	get_tree().change_scene_to_file("res://src/scenes/discovery/discovery_level.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/world_select.tscn")
