extends Control

## Settings screen with volume, accessibility, and progress management.

@onready var back_button: Button = $VBoxContainer/TitleBar/BackButton
@onready var master_slider: HSlider = $VBoxContainer/SettingsGrid/MasterSlider
@onready var sfx_slider: HSlider = $VBoxContainer/SettingsGrid/SFXSlider
@onready var music_slider: HSlider = $VBoxContainer/SettingsGrid/MusicSlider
@onready var reduce_motion_check: CheckButton = $VBoxContainer/SettingsGrid/ReduceMotionCheck
@onready var grid_snap_check: CheckButton = $VBoxContainer/SettingsGrid/GridSnapCheck
@onready var reset_button: Button = $VBoxContainer/ResetButton
@onready var confirm_dialog: ConfirmationDialog = $ConfirmDialog

const SETTINGS_PATH: String = "user://settings.json"


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.06, 0.07, 0.1))
	back_button.pressed.connect(_on_back)
	reset_button.pressed.connect(_on_reset_pressed)
	confirm_dialog.confirmed.connect(_on_reset_confirmed)

	master_slider.value_changed.connect(_on_master_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	music_slider.value_changed.connect(_on_music_changed)
	reduce_motion_check.toggled.connect(_on_reduce_motion_toggled)
	grid_snap_check.toggled.connect(_on_grid_snap_toggled)

	_load_settings()


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return

	var json := JSON.new()
	var err: Error = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return

	var data: Dictionary = json.data
	master_slider.value = data.get("master_volume", 80.0)
	sfx_slider.value = data.get("sfx_volume", 80.0)
	music_slider.value = data.get("music_volume", 60.0)
	reduce_motion_check.button_pressed = data.get("reduce_motion", false)
	grid_snap_check.button_pressed = data.get("grid_snap", true)

	_apply_volumes()


func _save_settings() -> void:
	var data: Dictionary = {
		"master_volume": master_slider.value,
		"sfx_volume": sfx_slider.value,
		"music_volume": music_slider.value,
		"reduce_motion": reduce_motion_check.button_pressed,
		"grid_snap": grid_snap_check.button_pressed,
	}

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func _apply_volumes() -> void:
	var master_db: float = linear_to_db(master_slider.value / 100.0)
	var sfx_db: float = linear_to_db(sfx_slider.value / 100.0)
	var music_db: float = linear_to_db(music_slider.value / 100.0)

	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, master_db)

	var sfx_idx: int = AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, sfx_db)

	var music_idx: int = AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, music_db)


func _on_master_changed(_value: float) -> void:
	_apply_volumes()
	_save_settings()


func _on_sfx_changed(_value: float) -> void:
	_apply_volumes()
	_save_settings()


func _on_music_changed(_value: float) -> void:
	_apply_volumes()
	_save_settings()


func _on_reduce_motion_toggled(_pressed: bool) -> void:
	_save_settings()


func _on_grid_snap_toggled(_pressed: bool) -> void:
	_save_settings()


func _on_reset_pressed() -> void:
	confirm_dialog.dialog_text = "This will erase ALL progress, stars, and unlocks.\nAre you sure?"
	confirm_dialog.popup_centered()


func _on_reset_confirmed() -> void:
	ProgressManager.reset_progress()
	# Also delete invention saves
	var dir := DirAccess.open("user://inventions/")
	if dir:
		dir.list_dir_begin()
		var f: String = dir.get_next()
		while f != "":
			if not dir.current_is_dir():
				dir.remove(f)
			f = dir.get_next()
		dir.list_dir_end()


func _on_back() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/main_menu.tscn")
