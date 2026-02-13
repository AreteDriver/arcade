extends Control

## Main menu with Discovery, Inventor, My Machines, and Settings buttons.

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var discovery_button: Button = $VBoxContainer/ButtonContainer/DiscoveryButton
@onready var inventor_button: Button = $VBoxContainer/ButtonContainer/InventorButton
@onready var machines_button: Button = $VBoxContainer/ButtonContainer/MachinesButton
@onready var sandbox_button: Button = $VBoxContainer/ButtonContainer/SandboxButton
@onready var settings_button: Button = $VBoxContainer/ButtonContainer/SettingsButton
@onready var stars_label: Label = $VBoxContainer/StarsLabel


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.06, 0.07, 0.1))
	discovery_button.pressed.connect(_on_discovery_pressed)
	inventor_button.pressed.connect(_on_inventor_pressed)
	machines_button.pressed.connect(_on_machines_pressed)
	sandbox_button.pressed.connect(_on_sandbox_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	_update_stars()


func _update_stars() -> void:
	var total: int = ProgressManager.get_total_stars()
	if total > 0:
		stars_label.text = "Total Stars: %d" % total
	else:
		stars_label.text = ""


func _on_discovery_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/world_select.tscn")


func _on_inventor_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/inventor/purpose_selector.tscn")


func _on_machines_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/inventor/machine_gallery.tscn")


func _on_sandbox_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/main.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/settings.tscn")
