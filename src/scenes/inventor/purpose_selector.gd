extends Control

## Fun multiple-choice purpose selector for inventor mode.
## "My machine will: [make music / sort things / launch stuff / do magic / surprise me]"

signal purpose_selected(purpose: String)

const PURPOSES: Array[String] = [
	"Make Music",
	"Sort Things",
	"Launch Stuff",
	"Do Magic",
	"Cook Breakfast",
	"Paint the Sky",
	"Tell Stories",
	"Surprise Me!",
]

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $VBoxContainer/SubtitleLabel
@onready var grid: GridContainer = $VBoxContainer/GridContainer
@onready var skip_button: Button = $VBoxContainer/SkipButton


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.06, 0.07, 0.1))
	skip_button.pressed.connect(_on_skip)
	_build_choices()


func _build_choices() -> void:
	for purpose in PURPOSES:
		var button := Button.new()
		button.text = purpose
		button.custom_minimum_size = Vector2(160, 60)
		button.pressed.connect(_on_purpose_chosen.bind(purpose))

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.18, 0.3)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.border_width_bottom = 2
		style.border_color = Color(0.3, 0.35, 0.55)
		button.add_theme_stylebox_override("normal", style)

		var hover := style.duplicate()
		hover.bg_color = style.bg_color.lightened(0.15)
		button.add_theme_stylebox_override("hover", hover)

		grid.add_child(button)


func _on_purpose_chosen(purpose: String) -> void:
	InventionManager.set_meta("selected_purpose", purpose)
	SceneTransition.change_scene("res://src/scenes/inventor/inventor_mode.tscn")


func _on_skip() -> void:
	SceneTransition.change_scene("res://src/scenes/inventor/inventor_mode.tscn")
