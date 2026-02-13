extends Control

## World selection screen with 4 world buttons showing lock/star state.

const WORLD_NAMES: Array[String] = [
	"Home of Tomorrow",
	"Snack Factory",
	"Robo Zoo",
	"Sky City",
]
const WORLD_COLORS: Array[Color] = [
	Color(0.3, 0.6, 0.9),
	Color(0.9, 0.5, 0.2),
	Color(0.2, 0.8, 0.4),
	Color(0.7, 0.3, 0.8),
]

@onready var grid: GridContainer = $VBoxContainer/GridContainer
@onready var back_button: Button = $VBoxContainer/BackButton


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.06, 0.07, 0.1))
	back_button.pressed.connect(_on_back_pressed)
	_build_world_buttons()


func _build_world_buttons() -> void:
	for child in grid.get_children():
		child.queue_free()

	for i in range(4):
		var world_num: int = i + 1
		var unlocked: bool = ProgressManager.is_world_unlocked(world_num)

		var button := Button.new()
		button.custom_minimum_size = Vector2(240, 120)

		var style := StyleBoxFlat.new()
		if unlocked:
			style.bg_color = WORLD_COLORS[i].darkened(0.4)
			style.border_color = WORLD_COLORS[i]
		else:
			style.bg_color = Color(0.15, 0.15, 0.2)
			style.border_color = Color(0.3, 0.3, 0.35)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.border_width_bottom = 3
		style.border_width_top = 3
		style.border_width_left = 3
		style.border_width_right = 3
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		button.add_theme_stylebox_override("normal", style)

		var hover_style := style.duplicate()
		if unlocked:
			hover_style.bg_color = style.bg_color.lightened(0.1)
		button.add_theme_stylebox_override("hover", hover_style)

		# Content
		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var world_label := Label.new()
		world_label.text = "World %d" % world_num
		world_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		world_label.add_theme_font_size_override("font_size", 20)
		world_label.add_theme_color_override("font_color", WORLD_COLORS[i] if unlocked else Color(0.4, 0.4, 0.45))
		world_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(world_label)

		var name_label := Label.new()
		name_label.text = WORLD_NAMES[i] if unlocked else "Locked"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8) if unlocked else Color(0.35, 0.35, 0.4))
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(name_label)

		# Stars for this world
		var stars_text: String = ""
		var total_world_stars: int = 0
		for level in range(1, 5):
			var level_id: String = "%d-%d" % [world_num, level]
			total_world_stars += ProgressManager.get_level_stars(level_id)
		if unlocked and total_world_stars > 0:
			stars_text = "%d / 12 stars" % total_world_stars
		var stars_label := Label.new()
		stars_label.text = stars_text
		stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stars_label.add_theme_font_size_override("font_size", 11)
		stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		stars_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(stars_label)

		button.add_child(vbox)
		button.disabled = not unlocked
		button.pressed.connect(_on_world_pressed.bind(world_num))
		grid.add_child(button)


func _on_world_pressed(world_num: int) -> void:
	# Store selected world for level select to pick up
	LevelSelectData.selected_world = world_num
	get_tree().change_scene_to_file("res://src/scenes/menus/level_select.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/main_menu.tscn")
