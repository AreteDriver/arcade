extends Node2D

## Inventor Mode — full sandbox with undo/redo and save/load.

@onready var canvas: MachineCanvas = $MachineCanvas
@onready var tray: ComponentTray = $UILayer/ComponentTray
@onready var param_panel: ParameterPanel = $UILayer/ParameterPanel
@onready var sim_controls: SimulationControls = $UILayer/SimulationControls
@onready var toolbar: HBoxContainer = $UILayer/Toolbar
@onready var purpose_label: Label = $UILayer/PurposeLabel

var _history: ActionHistory = ActionHistory.new()
var _machine_name: String = "My Machine"
var _machine_purpose: String = ""
var _is_loaded_invention: bool = false
var _loaded_filename: String = ""

## Undo button
var _undo_button: Button
var _redo_button: Button
var _save_button: Button
var _back_button: Button
var _name_edit: LineEdit


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.08, 0.09, 0.12))

	# Build toolbar buttons
	_build_toolbar()

	# Connect UI signals
	tray.component_drag_started.connect(_on_tray_component_selected)
	canvas.component_selected.connect(_on_canvas_component_selected)
	canvas.component_deselected.connect(_on_canvas_component_deselected)
	param_panel.delete_requested.connect(_on_delete_requested)
	sim_controls.zoom_to_fit_pressed.connect(canvas.zoom_to_fit)

	# Filter tray to only show unlocked components
	var unlocked: Array[String] = ProgressManager.get_unlocked_components()
	if unlocked.size() > 0:
		tray.set_available_types(unlocked)

	# Check if loading a saved invention
	if InventionManager.has_meta("pending_load"):
		var filename: String = InventionManager.get_meta("pending_load")
		InventionManager.remove_meta("pending_load")
		_load_invention(filename)

	# Check if purpose was selected
	if InventionManager.has_meta("selected_purpose"):
		_machine_purpose = InventionManager.get_meta("selected_purpose")
		InventionManager.remove_meta("selected_purpose")
		purpose_label.text = _machine_purpose


func _build_toolbar() -> void:
	_back_button = Button.new()
	_back_button.text = "< Back"
	_back_button.pressed.connect(_on_back_pressed)
	toolbar.add_child(_back_button)

	var spacer1 := Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(spacer1)

	_name_edit = LineEdit.new()
	_name_edit.text = _machine_name
	_name_edit.custom_minimum_size = Vector2(200, 0)
	_name_edit.placeholder_text = "Machine name..."
	_name_edit.text_submitted.connect(func(text: String) -> void: _machine_name = text)
	toolbar.add_child(_name_edit)

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(spacer2)

	_undo_button = Button.new()
	_undo_button.text = "Undo"
	_undo_button.pressed.connect(_on_undo)
	toolbar.add_child(_undo_button)

	_redo_button = Button.new()
	_redo_button.text = "Redo"
	_redo_button.pressed.connect(_on_redo)
	toolbar.add_child(_redo_button)

	_save_button = Button.new()
	_save_button.text = "Save"
	_save_button.pressed.connect(_on_save)
	toolbar.add_child(_save_button)


func _process(_delta: float) -> void:
	# Update undo/redo button state
	_undo_button.disabled = not _history.can_undo()
	_redo_button.disabled = not _history.can_redo()


func _unhandled_input(event: InputEvent) -> void:
	# Keyboard shortcuts for undo/redo
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Z and event.ctrl_pressed:
			if event.shift_pressed:
				_on_redo()
			else:
				_on_undo()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_Y and event.ctrl_pressed:
			_on_redo()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_S and event.ctrl_pressed:
			_on_save()
			get_viewport().set_input_as_handled()


func _on_tray_component_selected(type_name: String) -> void:
	canvas.start_placing(type_name)
	# Record placement action
	_history.record({
		"type": "place",
		"component_type": type_name,
	})


func _on_canvas_component_selected(component: MachineComponent) -> void:
	param_panel.show_for(component)


func _on_canvas_component_deselected() -> void:
	param_panel.hide_panel()


func _on_delete_requested(component: MachineComponent) -> void:
	# Record deletion before removing
	_history.record({
		"type": "delete",
		"component_type": component._get_component_type(),
		"position": [component.position.x, component.position.y],
	})
	canvas.remove_component(component)


func _on_undo() -> void:
	if SimulationManager.is_playing():
		return
	var action: Dictionary = _history.pop_undo()
	if action.is_empty():
		return

	match action.get("type", ""):
		"place":
			# Undo placement: remove the last placed component
			var components: Array[MachineComponent] = canvas.graph.get_components()
			if not components.is_empty():
				canvas.remove_component(components[-1])
		"delete":
			# Undo deletion: re-place the component
			var pos: Array = action.get("position", [400, 300])
			canvas.place_component(action.get("component_type", ""), Vector2(pos[0], pos[1]))


func _on_redo() -> void:
	if SimulationManager.is_playing():
		return
	var action: Dictionary = _history.pop_redo()
	if action.is_empty():
		return

	match action.get("type", ""):
		"place":
			# Redo placement
			canvas.place_component(action.get("component_type", ""), canvas.camera.get_screen_center_position())
		"delete":
			# Redo deletion
			var components: Array[MachineComponent] = canvas.graph.get_components()
			if not components.is_empty():
				canvas.remove_component(components[-1])


func _on_save() -> void:
	_machine_name = _name_edit.text if not _name_edit.text.is_empty() else "My Machine"

	# Serialize current machine state
	var machine_data: Dictionary = _serialize_machine()

	var filename: String = InventionManager.save_invention(_machine_name, _machine_purpose, machine_data)
	if not filename.is_empty():
		_is_loaded_invention = true
		_loaded_filename = filename
		# Flash feedback
		_save_button.text = "Saved!"
		get_tree().create_timer(1.5).timeout.connect(func() -> void: _save_button.text = "Save")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menus/main_menu.tscn")


## Serialize the current machine for saving
func _serialize_machine() -> Dictionary:
	var components: Array[Dictionary] = []
	for comp: MachineComponent in canvas.graph.get_components():
		var comp_data: Dictionary = {
			"id": comp.name,
			"type": comp._get_component_type(),
			"position": [comp.position.x, comp.position.y],
			"parameters": comp.serialize(),
			"connections": [],
		}

		# Serialize wire connections from this component's output ports
		for port: Port in comp.get_all_ports():
			if port.direction == Port.Direction.OUTPUT and port.connected_to != null:
				comp_data["connections"].append({
					"from_port": port.port_name,
					"to": port.connected_to.owner_component.name,
					"to_port": port.connected_to.port_name,
				})

		components.append(comp_data)

	return {"components": components}


## Load a saved invention onto the canvas
func _load_invention(filename: String) -> void:
	var data: Dictionary = InventionManager.load_invention(filename)
	if data.is_empty():
		return

	_machine_name = data.get("name", "My Machine")
	_machine_purpose = data.get("purpose", "")
	_loaded_filename = filename
	_is_loaded_invention = true

	_name_edit.text = _machine_name
	if not _machine_purpose.is_empty():
		purpose_label.text = _machine_purpose

	# Build a temporary MachineDefinition to reuse load_machine
	var definition := MachineDefinition.new()
	definition.machine_data = data.get("machine_data", {})
	canvas.load_machine(definition)
	canvas.reset_restrictions()
	_history.clear()
