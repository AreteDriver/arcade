extends Node

## Registry of available component types.
## Autoload singleton — access via ComponentRegistry.

## {type_name: {scene_path, display_name, description, icon, tier}}
var _registry: Dictionary = {}


func _ready() -> void:
	_register_tier1_components()
	_register_tier2_components()
	_register_tier3_components()


func _register_tier1_components() -> void:
	register_component("ramp", {
		"scene_path": "res://src/components/tier1/ramp.tscn",
		"display_name": "Ramp",
		"description": "Angled surface. Objects roll down based on angle and friction.",
		"tier": 1,
		"category": "mechanical",
	})
	register_component("pipe", {
		"scene_path": "res://src/components/tier1/pipe.tscn",
		"display_name": "Pipe",
		"description": "Tube that carries flow. Spawns particles that travel through.",
		"tier": 1,
		"category": "flow",
	})
	register_component("fan", {
		"scene_path": "res://src/components/tier1/fan.tscn",
		"display_name": "Fan",
		"description": "Blows objects with wind force. Adjust speed and direction.",
		"tier": 1,
		"category": "force",
	})
	register_component("gear", {
		"scene_path": "res://src/components/tier1/gear.tscn",
		"display_name": "Gear",
		"description": "Transfers and scales energy. Size affects torque/speed ratio.",
		"tier": 1,
		"category": "mechanical",
	})
	register_component("spring", {
		"scene_path": "res://src/components/tier1/spring.tscn",
		"display_name": "Spring",
		"description": "Bouncy energy storage. Launches objects upward.",
		"tier": 1,
		"category": "mechanical",
	})
	register_component("switch", {
		"scene_path": "res://src/components/tier1/switch.tscn",
		"display_name": "Switch",
		"description": "Trigger that activates when objects enter its area.",
		"tier": 1,
		"category": "signal",
	})
	register_component("conveyor", {
		"scene_path": "res://src/components/tier1/conveyor.tscn",
		"display_name": "Conveyor",
		"description": "Moving belt that pushes objects along its surface.",
		"tier": 1,
		"category": "mechanical",
	})
	register_component("valve", {
		"scene_path": "res://src/components/tier1/valve.tscn",
		"display_name": "Valve",
		"description": "Regulates flow. Signal input overrides threshold.",
		"tier": 1,
		"category": "flow",
	})


func _register_tier2_components() -> void:
	register_component("fusion_core", {
		"scene_path": "res://src/components/tier2/fusion_core.tscn",
		"display_name": "Fusion Core",
		"description": "Power source. Overloads when output exceeds stability.",
		"tier": 2,
		"category": "energy",
	})
	register_component("gravity_node", {
		"scene_path": "res://src/components/tier2/gravity_node.tscn",
		"display_name": "Gravity Node",
		"description": "Radial force field. Attracts or repels nearby objects.",
		"tier": 2,
		"category": "force",
	})
	register_component("plasma_conduit", {
		"scene_path": "res://src/components/tier2/plasma_conduit.tscn",
		"display_name": "Plasma Conduit",
		"description": "Glowing flow tube. Temperature and viscosity control flow speed.",
		"tier": 2,
		"category": "flow",
	})
	register_component("quantum_coupler", {
		"scene_path": "res://src/components/tier2/quantum_coupler.tscn",
		"display_name": "Quantum Coupler",
		"description": "Wireless energy transfer through quantum entanglement.",
		"tier": 2,
		"category": "energy",
	})
	register_component("chrono_spring", {
		"scene_path": "res://src/components/tier2/chrono_spring.tscn",
		"display_name": "Chrono Spring",
		"description": "Stores energy over time, then releases in a burst.",
		"tier": 2,
		"category": "energy",
	})
	register_component("phase_gate", {
		"scene_path": "res://src/components/tier2/phase_gate.tscn",
		"display_name": "Phase Gate",
		"description": "Filters flow by type. Signal input toggles gate.",
		"tier": 2,
		"category": "flow",
	})
	register_component("warp_belt", {
		"scene_path": "res://src/components/tier2/warp_belt.tscn",
		"display_name": "Warp Belt",
		"description": "Teleports objects along a path between endpoints.",
		"tier": 2,
		"category": "mechanical",
	})
	register_component("holo_projector", {
		"scene_path": "res://src/components/tier2/holo_projector.tscn",
		"display_name": "Holo Projector",
		"description": "Visual output indicator. Displays holographic patterns.",
		"tier": 2,
		"category": "signal",
	})


func _register_tier3_components() -> void:
	register_component("dimensional_splitter", {
		"scene_path": "res://src/components/tier3/dimensional_splitter.tscn",
		"display_name": "Dim. Splitter",
		"description": "Duplicates flow into parallel output paths.",
		"tier": 3,
		"category": "flow",
	})
	register_component("time_loop_relay", {
		"scene_path": "res://src/components/tier3/time_loop_relay.tscn",
		"display_name": "Time Loop Relay",
		"description": "Cycles output back to input with configurable delay.",
		"tier": 3,
		"category": "energy",
	})
	register_component("emotion_sensor", {
		"scene_path": "res://src/components/tier3/emotion_sensor.tscn",
		"display_name": "Emotion Sensor",
		"description": "Reacts to signal patterns with emotional responses.",
		"tier": 3,
		"category": "signal",
	})
	register_component("sound_forge", {
		"scene_path": "res://src/components/tier3/sound_forge.tscn",
		"display_name": "Sound Forge",
		"description": "Converts energy into musical tones with visual notes.",
		"tier": 3,
		"category": "energy",
	})
	register_component("cloud_weaver", {
		"scene_path": "res://src/components/tier3/cloud_weaver.tscn",
		"display_name": "Cloud Weaver",
		"description": "Particle system sculptor. Shapes flow into clouds.",
		"tier": 3,
		"category": "flow",
	})


## Register a component type
func register_component(type_name: String, data: Dictionary) -> void:
	_registry[type_name] = data


## Get info about a component type
func get_component_info(type_name: String) -> Dictionary:
	return _registry.get(type_name, {})


## Create an instance of a component by type
func create_component(type_name: String) -> MachineComponent:
	var info: Dictionary = _registry.get(type_name, {})
	if info.is_empty():
		push_warning("ComponentRegistry: Unknown type '%s'" % type_name)
		return null

	var scene: PackedScene = load(info["scene_path"])
	if scene == null:
		push_warning("ComponentRegistry: Failed to load scene for '%s'" % type_name)
		return null

	var instance: MachineComponent = scene.instantiate() as MachineComponent
	return instance


## Get all registered type names
func get_all_types() -> Array[String]:
	var types: Array[String] = []
	for key in _registry:
		types.append(key)
	return types


## Get types filtered by tier
func get_types_by_tier(tier: int) -> Array[String]:
	var types: Array[String] = []
	for key in _registry:
		if _registry[key].get("tier", 0) == tier:
			types.append(key)
	return types


## Get types filtered by category
func get_types_by_category(category: String) -> Array[String]:
	var types: Array[String] = []
	for key in _registry:
		if _registry[key].get("category", "") == category:
			types.append(key)
	return types


## Check if a type is registered
func has_type(type_name: String) -> bool:
	return type_name in _registry
