class_name ObjectiveTracker
extends PanelContainer

## HUD showing current objective, hint button, timer, and star display.

signal hint_requested()

var _objective_label: Label
var _timer_label: Label
var _hint_button: Button
var _star_container: HBoxContainer
var _stars: Array[Label] = []

var _elapsed_time: float = 0.0
var _tracking: bool = false
var _hint_cooldown: float = 0.0
const HINT_COOLDOWN_TIME: float = 5.0


func _ready() -> void:
	_build_ui()
	visible = false


func _build_ui() -> void:
	# Panel style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	# Top row: timer + stars
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)

	_timer_label = Label.new()
	_timer_label.text = "0:00"
	_timer_label.add_theme_font_size_override("font_size", 12)
	_timer_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	_timer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(_timer_label)

	_star_container = HBoxContainer.new()
	_star_container.add_theme_constant_override("separation", 2)
	for i in range(3):
		var star := Label.new()
		star.text = "-"
		star.add_theme_font_size_override("font_size", 14)
		star.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		_star_container.add_child(star)
		_stars.append(star)
	top_row.add_child(_star_container)

	vbox.add_child(top_row)

	# Objective text
	_objective_label = Label.new()
	_objective_label.text = ""
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_objective_label.add_theme_font_size_override("font_size", 13)
	_objective_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	vbox.add_child(_objective_label)

	# Hint button
	_hint_button = Button.new()
	_hint_button.text = "Hint"
	_hint_button.custom_minimum_size = Vector2(60, 28)
	_hint_button.pressed.connect(_on_hint_pressed)

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.25, 0.3, 0.4)
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4
	_hint_button.add_theme_stylebox_override("normal", btn_style)
	_hint_button.add_theme_font_size_override("font_size", 11)

	vbox.add_child(_hint_button)
	add_child(vbox)


## Start tracking objective and timer
func start_tracking(objective_text: String) -> void:
	_objective_label.text = objective_text
	_elapsed_time = 0.0
	_tracking = true
	_hint_cooldown = 0.0
	_set_stars(0)
	visible = true


## Update the objective text
func set_objective(text: String) -> void:
	_objective_label.text = text


## Show earned stars
func show_stars(count: int) -> void:
	_set_stars(count)


## Stop tracking
func stop_tracking() -> void:
	_tracking = false


func _process(delta: float) -> void:
	if _tracking:
		_elapsed_time += delta
		_timer_label.text = _format_time(_elapsed_time)

	if _hint_cooldown > 0:
		_hint_cooldown -= delta
		_hint_button.disabled = _hint_cooldown > 0
		if _hint_cooldown > 0:
			_hint_button.text = "Hint (%ds)" % ceili(_hint_cooldown)
		else:
			_hint_button.text = "Hint"


func _set_stars(count: int) -> void:
	for i in range(3):
		if i < count:
			_stars[i].text = "*"
			_stars[i].add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		else:
			_stars[i].text = "-"
			_stars[i].add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))


func _format_time(seconds: float) -> String:
	var mins: int = int(seconds) / 60
	var secs: int = int(seconds) % 60
	return "%d:%02d" % [mins, secs]


func _on_hint_pressed() -> void:
	_hint_cooldown = HINT_COOLDOWN_TIME
	_hint_button.disabled = true
	hint_requested.emit()


## Get elapsed time
func get_elapsed_time() -> float:
	return _elapsed_time
