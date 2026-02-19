class_name ChallengeManager
extends Node

## Manages the active challenge state for a Discovery Mode level.
## Configures canvas restrictions per challenge type and checks completion.

signal challenge_completed(stars: int)
signal objective_updated(text: String)

var _definition: MachineDefinition = null
var _canvas: MachineCanvas = null
var _start_time: float = 0.0
var _elapsed_time: float = 0.0
var _hints_used: int = 0
var _is_active: bool = false
var _is_completed: bool = false


## Initialize the challenge from a machine definition
func setup(definition: MachineDefinition, canvas: MachineCanvas) -> void:
	_definition = definition
	_canvas = canvas
	_is_active = false
	_is_completed = false
	_elapsed_time = 0.0
	_hints_used = 0


## Start the challenge — configure canvas restrictions and begin tracking
func start_challenge() -> void:
	if _definition == null or _canvas == null:
		return

	_is_active = true
	_is_completed = false
	_start_time = Time.get_ticks_msec() / 1000.0

	_configure_restrictions()

	if _definition.objectives.size() > 0:
		objective_updated.emit(_definition.objectives[0])


## Configure canvas restrictions based on challenge type
func _configure_restrictions() -> void:
	match _definition.challenge_type:
		"broken":
			# Layout locked, player can only place repair components from tray
			_canvas.allow_placement = true
			_canvas.allow_wiring = true
			_canvas.allow_parameter_edit = false
			_canvas.allow_removal = true
			_canvas.locked_component_ids = _definition.locked_component_ids.duplicate()

		"miscalibrated":
			# Parameter edit only — no placement, wiring, or removal
			_canvas.allow_placement = false
			_canvas.allow_wiring = false
			_canvas.allow_parameter_edit = true
			_canvas.allow_removal = false
			_canvas.locked_component_ids = _definition.locked_component_ids.duplicate()

		"incomplete":
			# Can place and wire, but locked components stay
			_canvas.allow_placement = true
			_canvas.allow_wiring = true
			_canvas.allow_parameter_edit = true
			_canvas.allow_removal = false
			_canvas.locked_component_ids = _definition.locked_component_ids.duplicate()

		"overloaded":
			# Full access — add components, rewire allowed
			_canvas.allow_placement = true
			_canvas.allow_wiring = true
			_canvas.allow_parameter_edit = true
			_canvas.allow_removal = true
			_canvas.locked_component_ids = []


## Check completion each physics frame during simulation
func check_completion() -> void:
	if not _is_active or _is_completed:
		return
	if not SimulationManager.is_playing():
		return

	_elapsed_time = Time.get_ticks_msec() / 1000.0 - _start_time

	var completed: bool = false
	match _definition.challenge_type:
		"broken":
			completed = _check_broken()
		"miscalibrated":
			completed = _check_miscalibrated()
		"incomplete":
			completed = _check_incomplete()
		"overloaded":
			completed = _check_overloaded()

	if completed:
		_is_completed = true
		_is_active = false
		var stars: int = _calculate_stars()
		challenge_completed.emit(stars)


## Broken: all components must be in ACTIVE state (no BROKEN)
func _check_broken() -> bool:
	for comp: MachineComponent in _canvas.graph.get_components():
		if comp.current_state == MachineComponent.State.BROKEN:
			return false
	# Must have run for at least 1 second to confirm stability
	return _elapsed_time > 1.0


## Miscalibrated: all parameters within 5% of target values
func _check_miscalibrated() -> bool:
	var targets: Dictionary = _definition.challenge_data.get("target_params", {})
	for comp_id in targets:
		var comp: MachineComponent = _canvas.graph.get_component(comp_id)
		if comp == null:
			return false
		var param_targets: Dictionary = targets[comp_id]
		for param_name in param_targets:
			var target_val: float = param_targets[param_name]
			var current_val: float = comp.get_parameter(param_name)
			var param_data: Dictionary = comp.parameters.get(param_name, {})
			var range_size: float = param_data.get("max", 100.0) - param_data.get("min", 0.0)
			var tolerance: float = range_size * 0.05
			if absf(current_val - target_val) > tolerance:
				return false
	return true


## Incomplete: all ghost slots filled and simulation running for 1+ second
func _check_incomplete() -> bool:
	var missing_slots: Array = _definition.challenge_data.get("missing_slots", [])
	if missing_slots.is_empty():
		return _elapsed_time > 1.0

	# Check that the graph has enough components (original + missing)
	var original_count: int = _definition.machine_data.get("components", []).size()
	var current_count: int = _canvas.graph.get_count()
	if current_count < original_count + missing_slots.size():
		return false

	return _elapsed_time > 1.0


## Overloaded: no components in OVERLOADED state
func _check_overloaded() -> bool:
	for comp: MachineComponent in _canvas.graph.get_components():
		if comp.current_state == MachineComponent.State.OVERLOADED:
			return false
	return _elapsed_time > 1.5


## Calculate star rating based on time and hints
func _calculate_stars() -> int:
	if _elapsed_time <= _definition.par_time_3_star and _hints_used == 0:
		return 3
	elif _elapsed_time <= _definition.par_time_2_star:
		return 2
	return 1


## Use a hint (called by ObjectiveTracker)
func use_hint() -> String:
	if _hints_used < _definition.hints.size():
		var hint: String = _definition.hints[_hints_used]
		_hints_used += 1
		return hint
	return ""


## Get number of hints remaining
func get_hints_remaining() -> int:
	return _definition.hints.size() - _hints_used


## Get elapsed time since challenge started
func get_elapsed_time() -> float:
	return _elapsed_time


## Check if challenge is currently active
func is_active() -> bool:
	return _is_active
