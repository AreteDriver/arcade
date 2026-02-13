extends Node2D

## Main game scene. Connects UI to MachineCanvas.

@onready var canvas: MachineCanvas = $MachineCanvas
@onready var tray: ComponentTray = $UILayer/ComponentTray
@onready var param_panel: ParameterPanel = $UILayer/ParameterPanel
@onready var sim_controls: SimulationControls = $UILayer/SimulationControls
@onready var title_label: Label = $UILayer/TitleLabel


func _ready() -> void:
	# Dark workshop background
	RenderingServer.set_default_clear_color(Color(0.08, 0.09, 0.12))

	# Connect UI signals
	tray.component_drag_started.connect(_on_tray_component_selected)
	canvas.component_selected.connect(_on_canvas_component_selected)
	canvas.component_deselected.connect(_on_canvas_component_deselected)
	param_panel.delete_requested.connect(_on_delete_requested)

	# Connect simulation signals to canvas
	SimulationManager.simulation_started.connect(canvas._on_simulation_started)
	SimulationManager.simulation_stopped.connect(canvas._on_simulation_stopped)


func _on_tray_component_selected(type_name: String) -> void:
	canvas.start_placing(type_name)


func _on_canvas_component_selected(component: MachineComponent) -> void:
	param_panel.show_for(component)


func _on_canvas_component_deselected() -> void:
	param_panel.hide_panel()


func _on_delete_requested(component: MachineComponent) -> void:
	canvas.remove_component(component)
