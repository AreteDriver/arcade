class_name MachineDefinition
extends Resource

## Defines a pre-built machine with its challenge configuration.
## Used by Discovery Mode to load levels.

## Machine identity
@export var machine_name: String = ""
@export var machine_description: String = ""
@export var world: int = 1
@export var level: int = 1

## Challenge configuration
@export_enum("broken", "miscalibrated", "incomplete", "overloaded") var challenge_type: String = "incomplete"

## Full machine layout — same format as ComponentGraph.serialize()
## {"components": [{"id", "type", "position", "parameters", "connections"}, ...]}
@export var machine_data: Dictionary = {}

## Challenge-specific data
## broken: {"broken_ids": ["comp_001"]}
## miscalibrated: {"target_params": {"comp_001": {"speed": 75.0}}}
## incomplete: {"missing_slots": [{"position": [x,y], "type": "pipe", "connections": [...]}]}
## overloaded: {"overload_threshold": 0} — goal is 0 components in OVERLOADED state
@export var challenge_data: Dictionary = {}

## Objectives shown to player
@export var objectives: Array[String] = []

## Progressive hints (revealed one at a time)
@export var hints: Array[String] = []

## Star rating thresholds (seconds)
@export var par_time_3_star: float = 30.0
@export var par_time_2_star: float = 60.0

## Components unlocked upon completion
@export var unlock_rewards: Array[String] = []

## Story dialog
@export var intro_dialog: Array[String] = []
@export var success_dialog: Array[String] = []

## Components available in the tray for this level
@export var available_components: Array[String] = []

## Components that are locked (cannot be moved/edited) in this level
@export var locked_component_ids: Array[String] = []


## Get the level ID string (e.g., "1-2")
func get_level_id() -> String:
	return "%d-%d" % [world, level]
