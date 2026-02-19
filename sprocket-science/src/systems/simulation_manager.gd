extends Node

## Manages simulation state: play, pause, reset.
## Autoload singleton — access via SimulationManager.

enum SimState { STOPPED, PLAYING, PAUSED }

var current_state: SimState = SimState.STOPPED
var graph: ComponentGraph = null

signal simulation_started()
signal simulation_paused()
signal simulation_stopped()
signal simulation_state_changed(new_state: SimState)


func _ready() -> void:
	set_physics_process(false)


## Set the component graph to evaluate
func set_graph(new_graph: ComponentGraph) -> void:
	graph = new_graph


## Start or resume simulation
func play() -> void:
	if graph == null or graph.is_empty():
		return

	if current_state == SimState.STOPPED:
		# Activate all components
		for component in graph.get_components():
			component.set_state(MachineComponent.State.ACTIVE)

	current_state = SimState.PLAYING
	set_physics_process(true)
	simulation_started.emit()
	simulation_state_changed.emit(current_state)


## Pause simulation (components freeze)
func pause() -> void:
	if current_state != SimState.PLAYING:
		return
	current_state = SimState.PAUSED
	set_physics_process(false)
	simulation_paused.emit()
	simulation_state_changed.emit(current_state)


## Stop and reset simulation
func stop() -> void:
	current_state = SimState.STOPPED
	set_physics_process(false)

	if graph:
		for component in graph.get_components():
			component.reset_component()

	simulation_stopped.emit()
	simulation_state_changed.emit(current_state)


## Toggle play/pause
func toggle() -> void:
	match current_state:
		SimState.STOPPED:
			play()
		SimState.PLAYING:
			pause()
		SimState.PAUSED:
			play()


func is_playing() -> bool:
	return current_state == SimState.PLAYING


func is_stopped() -> bool:
	return current_state == SimState.STOPPED


func _physics_process(delta: float) -> void:
	if graph == null or current_state != SimState.PLAYING:
		return

	# Evaluate components in topological order
	var order: Array[MachineComponent] = graph.get_evaluation_order()
	for component in order:
		if component.current_state == MachineComponent.State.ACTIVE:
			component._process_component(delta)
