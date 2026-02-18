extends Node

## Manages player progress: level completion, stars, unlocked components.
## Autoload singleton — access via ProgressManager.
## Saves/loads from user://progress.json with backup and version migration.

const SAVE_PATH: String = "user://progress.json"
const BACKUP_PATH: String = "user://progress.backup.json"
const SAVE_VERSION: int = 2

## Starting components available before any unlocks
const STARTING_COMPONENTS: Array[String] = ["ramp", "pipe", "fan"]

## {level_id: {stars: int, time: float, hints_used: int, completed: bool}}
var _level_progress: Dictionary = {}

## Component types the player has unlocked
var _unlocked_components: Array[String] = []

## Tracked achievements: {achievement_id: {unlocked: bool, timestamp: float}}
var _achievements: Dictionary = {}

signal progress_updated()
signal achievement_unlocked(achievement_id: String)


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
	_check_achievements()


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
		_check_achievements()


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


## Get number of completed levels
func get_completed_level_count() -> int:
	var count: int = 0
	for level_id in _level_progress:
		if _level_progress[level_id].get("completed", false):
			count += 1
	return count


## Get number of completed worlds (all 4 levels done)
func get_completed_world_count() -> int:
	var count: int = 0
	for world in range(1, 5):
		var all_done: bool = true
		for level in range(1, 5):
			if not is_level_completed("%d-%d" % [world, level]):
				all_done = false
				break
		if all_done:
			count += 1
	return count


## Check if an achievement is unlocked
func is_achievement_unlocked(achievement_id: String) -> bool:
	return _achievements.get(achievement_id, {}).get("unlocked", false)


## Get all unlocked achievement IDs
func get_unlocked_achievements() -> Array[String]:
	var result: Array[String] = []
	for aid in _achievements:
		if _achievements[aid].get("unlocked", false):
			result.append(aid)
	return result


## Reset all progress (used from settings)
func reset_progress() -> void:
	_level_progress.clear()
	_unlocked_components = STARTING_COMPONENTS.duplicate()
	_achievements.clear()
	save_progress()
	progress_updated.emit()


## Save progress to disk with backup
func save_progress() -> void:
	# Create backup of existing save before writing
	if FileAccess.file_exists(SAVE_PATH):
		var existing := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if existing:
			var backup := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
			if backup:
				backup.store_string(existing.get_as_text())

	var data: Dictionary = {
		"version": SAVE_VERSION,
		"level_progress": _level_progress,
		"unlocked_components": _unlocked_components,
		"achievements": _achievements,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))


## Load progress from disk with corruption recovery
func load_progress() -> void:
	var data: Dictionary = _try_load_file(SAVE_PATH)
	if data.is_empty():
		# Primary save failed — try backup
		data = _try_load_file(BACKUP_PATH)
		if data.is_empty():
			return
		push_warning("ProgressManager: Restored from backup save")

	# Version migration
	var version: int = int(data.get("version", 1))
	data = _migrate(data, version)

	if data.has("level_progress"):
		_level_progress = data["level_progress"]
	if data.has("unlocked_components"):
		_unlocked_components.clear()
		for comp in data["unlocked_components"]:
			_unlocked_components.append(comp)
	if data.has("achievements"):
		_achievements = data["achievements"]


## Attempt to load and parse a JSON save file; returns empty dict on failure
func _try_load_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	if text.is_empty():
		return {}
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_warning("ProgressManager: Failed to parse '%s'" % path)
		return {}
	if json.data is Dictionary:
		return json.data
	return {}


## Migrate save data from older versions to current
func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	if from_version < 2:
		# v1 → v2: add achievements field
		if not data.has("achievements"):
			data["achievements"] = {}
		data["version"] = 2
	return data


## Check and unlock achievements based on current state
func _check_achievements() -> void:
	var defs: Array[Dictionary] = _get_achievement_definitions()
	for adef in defs:
		var aid: String = adef["id"]
		if is_achievement_unlocked(aid):
			continue
		if _evaluate_achievement(adef):
			_achievements[aid] = {"unlocked": true, "timestamp": Time.get_unix_time_from_system()}
			achievement_unlocked.emit(aid)
			save_progress()


## Evaluate whether an achievement condition is met
func _evaluate_achievement(adef: Dictionary) -> bool:
	match adef["type"]:
		"levels_completed":
			return get_completed_level_count() >= adef["threshold"]
		"total_stars":
			return get_total_stars() >= adef["threshold"]
		"components_unlocked":
			return _unlocked_components.size() >= adef["threshold"]
		"world_completed":
			return is_level_completed("%d-4" % adef["world"])
		"all_worlds":
			return get_completed_world_count() >= 4
		"perfect_world":
			for level in range(1, 5):
				if get_level_stars("%d-%d" % [adef["world"], level]) < 3:
					return false
			return true
	return false


## Achievement definitions — id, display name, description, unlock condition
func get_achievement_definitions() -> Array[Dictionary]:
	return _get_achievement_definitions()


func _get_achievement_definitions() -> Array[Dictionary]:
	return [
		{"id": "first_fix", "name": "First Fix", "desc": "Complete your first level", "type": "levels_completed", "threshold": 1},
		{"id": "apprentice", "name": "Apprentice", "desc": "Complete 4 levels", "type": "levels_completed", "threshold": 4},
		{"id": "journeyman", "name": "Journeyman", "desc": "Complete 8 levels", "type": "levels_completed", "threshold": 8},
		{"id": "master_mechanic", "name": "Master Mechanic", "desc": "Complete all 16 levels", "type": "levels_completed", "threshold": 16},
		{"id": "star_collector", "name": "Star Collector", "desc": "Earn 10 stars", "type": "total_stars", "threshold": 10},
		{"id": "star_hoarder", "name": "Star Hoarder", "desc": "Earn 30 stars", "type": "total_stars", "threshold": 30},
		{"id": "perfectionist", "name": "Perfectionist", "desc": "Earn all 48 stars", "type": "total_stars", "threshold": 48},
		{"id": "tinkerer", "name": "Tinkerer", "desc": "Unlock 10 components", "type": "components_unlocked", "threshold": 10},
		{"id": "full_toolbox", "name": "Full Toolbox", "desc": "Unlock all components", "type": "components_unlocked", "threshold": 21},
		{"id": "home_hero", "name": "Home Hero", "desc": "Complete World 1: Home of Tomorrow", "type": "world_completed", "world": 1},
		{"id": "sky_captain", "name": "Sky Captain", "desc": "Complete World 2: Sky Factory", "type": "world_completed", "world": 2},
		{"id": "dream_weaver", "name": "Dream Weaver", "desc": "Complete World 3: Dream Workshop", "type": "world_completed", "world": 3},
		{"id": "mad_scientist", "name": "Mad Scientist", "desc": "Complete World 4: Impossible Lab", "type": "world_completed", "world": 4},
		{"id": "everything_done", "name": "Grand Inventor", "desc": "Complete all four worlds", "type": "all_worlds"},
		{"id": "perfect_w1", "name": "Home Perfection", "desc": "3 stars on every World 1 level", "type": "perfect_world", "world": 1},
		{"id": "perfect_w4", "name": "Impossible Perfection", "desc": "3 stars on every World 4 level", "type": "perfect_world", "world": 4},
	]
