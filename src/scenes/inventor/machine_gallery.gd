extends Control

## Gallery of saved inventions. Load or delete machines.

@onready var grid: GridContainer = $VBoxContainer/ScrollContainer/GridContainer
@onready var title_label: Label = $VBoxContainer/TitleBar/TitleLabel
@onready var back_button: Button = $VBoxContainer/TitleBar/BackButton
@onready var empty_label: Label = $VBoxContainer/EmptyLabel

const CARD_SIZE := Vector2(200, 120)


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.06, 0.07, 0.1))
	back_button.pressed.connect(_on_back)
	_build_gallery()


func _build_gallery() -> void:
	# Clear existing cards
	for child in grid.get_children():
		child.queue_free()

	var inventions: Array[Dictionary] = InventionManager.list_inventions()

	if inventions.is_empty():
		empty_label.visible = true
		empty_label.text = "No saved machines yet — build one in Inventor Mode!"
		return

	empty_label.visible = false

	for invention in inventions:
		_add_card(invention)


func _add_card(invention: Dictionary) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_bottom = 2
	style.border_color = Color(0.25, 0.3, 0.45)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	var name_label := Label.new()
	name_label.text = invention.get("name", "Unnamed")
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	vbox.add_child(name_label)

	var purpose: String = invention.get("purpose", "")
	if not purpose.is_empty():
		var purpose_label := Label.new()
		purpose_label.text = purpose
		purpose_label.add_theme_font_size_override("font_size", 11)
		purpose_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		vbox.add_child(purpose_label)

	var info_label := Label.new()
	info_label.text = "%d components" % invention.get("component_count", 0)
	info_label.add_theme_font_size_override("font_size", 11)
	info_label.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6))
	vbox.add_child(info_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)

	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.pressed.connect(_on_load.bind(invention.get("filename", "")))
	buttons.add_child(load_btn)

	var delete_btn := Button.new()
	delete_btn.text = "Delete"
	delete_btn.pressed.connect(_on_delete.bind(invention.get("filename", "")))
	buttons.add_child(delete_btn)

	vbox.add_child(buttons)
	card.add_child(vbox)
	grid.add_child(card)


func _on_load(filename: String) -> void:
	InventionManager.set_meta("pending_load", filename)
	get_tree().change_scene_to_file("res://src/scenes/inventor/inventor_mode.tscn")


func _on_delete(filename: String) -> void:
	InventionManager.delete_invention(filename)
	_build_gallery()


func _on_back() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/main_menu.tscn")
