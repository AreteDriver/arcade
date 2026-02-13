extends Node2D

## Orchestrates a Discovery Mode level.
## Flow: intro dialog -> load machine + start challenge -> player solves ->
## completion detected -> success dialog -> save progress -> emit level_completed.

signal level_completed(level_id: String, stars: int)

@onready var canvas: MachineCanvas = $MachineCanvas
@onready var tray: ComponentTray = $UILayer/ComponentTray
@onready var param_panel: ParameterPanel = $UILayer/ParameterPanel
@onready var sim_controls: SimulationControls = $UILayer/SimulationControls
@onready var objective_tracker: ObjectiveTracker = $UILayer/ObjectiveTracker
@onready var dialog_box: DialogBox = $DialogBox
@onready var challenge_manager: ChallengeManager = $ChallengeManager
@onready var tutorial_overlay: TutorialOverlay = $TutorialOverlay
@onready var back_button: Button = $UILayer/BackButton

var _definition: MachineDefinition = null
var _ghost_slots: Array[GhostSlot] = []


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.08, 0.09, 0.12))

	# Connect UI signals
	tray.component_drag_started.connect(_on_tray_component_selected)
	canvas.component_selected.connect(_on_canvas_component_selected)
	canvas.component_deselected.connect(_on_canvas_component_deselected)
	param_panel.delete_requested.connect(_on_delete_requested)
	sim_controls.zoom_to_fit_pressed.connect(canvas.zoom_to_fit)
	back_button.pressed.connect(_on_back_pressed)

	# Challenge signals
	challenge_manager.challenge_completed.connect(_on_challenge_completed)
	challenge_manager.objective_updated.connect(_on_objective_updated)

	# Objective tracker
	objective_tracker.hint_requested.connect(_on_hint_requested)

	# Tutorial signals
	canvas.wire_created.connect(func(_w: Wire) -> void: tutorial_overlay.notify_action("wire_created"))
	SimulationManager.simulation_started.connect(func() -> void: tutorial_overlay.notify_action("simulation_started"))

	# Auto-start if definition was passed via LevelSelectData
	if LevelSelectData.selected_definition != null:
		start_level(LevelSelectData.selected_definition)
		LevelSelectData.selected_definition = null


## Load and start a level from a MachineDefinition
func start_level(definition: MachineDefinition) -> void:
	_definition = definition

	# Configure tray with available components
	if definition.available_components.size() > 0:
		tray.set_available_types(definition.available_components)
	else:
		tray.set_available_types([])

	# Setup challenge manager
	challenge_manager.setup(definition, canvas)

	# Show intro dialog, then load machine
	if definition.intro_dialog.size() > 0:
		dialog_box.dialog_finished.connect(_on_intro_finished, CONNECT_ONE_SHOT)
		dialog_box.show_dialog(definition.intro_dialog)
	else:
		_load_and_start()


func _on_intro_finished() -> void:
	_load_and_start()


func _load_and_start() -> void:
	# Load machine onto canvas
	canvas.load_machine(_definition)

	# Mark broken components for broken challenges
	if _definition.challenge_type == "broken":
		_apply_broken_state()

	# Create ghost slots for incomplete challenges
	if _definition.challenge_type == "incomplete":
		_create_ghost_slots()

	# Configure parameter panel based on restrictions
	if not canvas.allow_parameter_edit:
		param_panel.set_read_only(true)
	else:
		param_panel.set_read_only(false)

	# Start challenge
	challenge_manager.start_challenge()

	# Start objective tracking
	var objective_text: String = _definition.objectives[0] if _definition.objectives.size() > 0 else "Complete the challenge!"
	objective_tracker.start_tracking(objective_text)

	# Start tutorial for level 1-1
	if _definition.get_level_id() == "1-1" and not ProgressManager.is_level_completed("1-1"):
		tutorial_overlay.start_tutorial()

	# Zoom to fit the loaded machine
	canvas.zoom_to_fit()


func _apply_broken_state() -> void:
	var broken_ids: Array = _definition.challenge_data.get("broken_ids", [])
	for comp_id in broken_ids:
		var comp: MachineComponent = canvas.graph.get_component(comp_id)
		if comp:
			comp.set_state(MachineComponent.State.BROKEN)


func _create_ghost_slots() -> void:
	var missing_slots: Array = _definition.challenge_data.get("missing_slots", [])
	for slot_data: Dictionary in missing_slots:
		var ghost := GhostSlot.new()
		ghost.slot_type = slot_data.get("type", "")
		ghost.slot_connections = slot_data.get("connections", [])
		var pos: Array = slot_data.get("position", [0, 0])
		ghost.position = Vector2(pos[0], pos[1])
		canvas.component_layer.add_child(ghost)
		_ghost_slots.append(ghost)


func _physics_process(_delta: float) -> void:
	if challenge_manager.is_active():
		challenge_manager.check_completion()


func _on_challenge_completed(stars: int) -> void:
	objective_tracker.show_stars(stars)
	objective_tracker.stop_tracking()

	# Stop simulation
	SimulationManager.stop()

	# Unlock reward components
	for comp_type in _definition.unlock_rewards:
		ProgressManager.unlock_component(comp_type)

	# Save progress
	var level_id: String = _definition.get_level_id()
	ProgressManager.complete_level(level_id, stars,
		objective_tracker.get_elapsed_time(), challenge_manager._hints_used)

	# Show success dialog
	if _definition.success_dialog.size() > 0:
		dialog_box.dialog_finished.connect(_on_success_finished.bind(level_id, stars), CONNECT_ONE_SHOT)
		dialog_box.show_dialog(_definition.success_dialog)
	else:
		level_completed.emit(level_id, stars)


func _on_success_finished(level_id: String, stars: int) -> void:
	level_completed.emit(level_id, stars)


func _on_hint_requested() -> void:
	var hint: String = challenge_manager.use_hint()
	if not hint.is_empty():
		objective_tracker.set_objective(hint)


func _on_objective_updated(text: String) -> void:
	objective_tracker.set_objective(text)


func _on_tray_component_selected(type_name: String) -> void:
	canvas.start_placing(type_name)
	tutorial_overlay.notify_action("tray_clicked")


func _on_canvas_component_selected(component: MachineComponent) -> void:
	param_panel.show_for(component)
	tutorial_overlay.notify_action("component_placed")


func _on_canvas_component_deselected() -> void:
	param_panel.hide_panel()


func _on_delete_requested(component: MachineComponent) -> void:
	canvas.remove_component(component)


func _on_back_pressed() -> void:
	# Clean up and return to level select
	SimulationManager.stop()
	canvas.clear_machine()
	canvas.reset_restrictions()
	_cleanup_ghost_slots()
	SceneTransition.change_scene("res://src/scenes/menus/level_select.tscn")


func _cleanup_ghost_slots() -> void:
	for ghost in _ghost_slots:
		if is_instance_valid(ghost):
			ghost.queue_free()
	_ghost_slots.clear()
