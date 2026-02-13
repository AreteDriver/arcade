extends Node

## Registry of available component types.
## Autoload singleton — access via ComponentRegistry.

## {type_name: {scene_path, display_name, description, icon, tier}}
var _registry: Dictionary = {}


func _ready() -> void:
	_register_tier1_components()


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
