extends Node

## Manages player progress: level completion, stars, unlocked components.
## Autoload singleton — access via ProgressManager.
## Saves/loads from user://progress.json.

const SAVE_PATH: String = "user://progress.json"

## Starting components available before any unlocks
const STARTING_COMPONENTS: Array[String] = ["ramp", "pipe", "fan"]

## {level_id: {stars: int, time: float, hints_used: int, completed: bool}}
var _level_progress: Dictionary = {}

## Component types the player has unlocked
var _unlocked_components: Array[String] = []

signal progress_updated()


func _ready() -> void:
	_unlocked_components = STARTING_COMPONENTS.duplicate()
	load_progress()


## Mark a level as completed with a star rating
func complete_level(level_id: String, stars: int, time: float, hints_used: int) -> void:
	var existing: Dictionary = _level_progress.get(level_id, {})
	var best_stars: int = maxi(existing.get("stars", 0), stars)
	var best_time: float = time
	if existing.has("time") and existing["time"] > 0:
		best_time = minf(existing["time"], time)

	_level_progress[level_id] = {
		"stars": best_stars,
		"time": best_time,
		"hints_used": mini(existing.get("hints_used", hints_used), hints_used),
		"completed": true,
	}
	save_progress()
	progress_updated.emit()


## Check if a level is unlocked (first level always unlocked, others need previous completed)
func is_level_unlocked(world: int, level: int) -> bool:
	if level == 1:
		return is_world_unlocked(world)
	# Previous level in same world must be completed
	var prev_id: String = "%d-%d" % [world, level - 1]
	return is_level_completed(prev_id)


## Check if a world is unlocked (world 1 always, others need previous world's last level)
func is_world_unlocked(world: int) -> bool:
	if world <= 1:
		return true
	# Last level of previous world must be completed
	var prev_world_last: String = "%d-4" % [world - 1]
	return is_level_completed(prev_world_last)


## Check if a level has been completed
func is_level_completed(level_id: String) -> bool:
	return _level_progress.get(level_id, {}).get("completed", false)


## Get star count for a level (0 if not completed)
func get_level_stars(level_id: String) -> int:
	return _level_progress.get(level_id, {}).get("stars", 0)


## Get best time for a level (0.0 if not completed)
func get_level_time(level_id: String) -> float:
	return _level_progress.get(level_id, {}).get("time", 0.0)


## Unlock a component type for sandbox/future levels
func unlock_component(type_name: String) -> void:
	if type_name not in _unlocked_components:
		_unlocked_components.append(type_name)
		save_progress()
		progress_updated.emit()


## Check if a component type is unlocked
func is_component_unlocked(type_name: String) -> bool:
	return type_name in _unlocked_components


## Get all unlocked component types
func get_unlocked_components() -> Array[String]:
	return _unlocked_components.duplicate()


## Get total stars earned across all levels
func get_total_stars() -> int:
	var total: int = 0
	for level_id in _level_progress:
		total += _level_progress[level_id].get("stars", 0)
	return total


## Reset all progress (used from settings)
func reset_progress() -> void:
	_level_progress.clear()
	_unlocked_components = STARTING_COMPONENTS.duplicate()
	save_progress()
	progress_updated.emit()


## Save progress to disk
func save_progress() -> void:
	var data: Dictionary = {
		"level_progress": _level_progress,
		"unlocked_components": _unlocked_components,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))


## Load progress from disk
func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_warning("ProgressManager: Failed to parse save file")
		return
	var data: Dictionary = json.data
	if data.has("level_progress"):
		_level_progress = data["level_progress"]
	if data.has("unlocked_components"):
		_unlocked_components.clear()
		for comp in data["unlocked_components"]:
			_unlocked_components.append(comp)
