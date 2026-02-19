extends Node

## Manages saving and loading inventions to user://inventions/.
## Autoload singleton — access via InventionManager.

const INVENTIONS_DIR: String = "user://inventions/"

## Invention metadata for gallery display
## {filename, name, purpose, component_count, timestamp}


func _ready() -> void:
	# Ensure inventions directory exists
	DirAccess.make_dir_recursive_absolute(INVENTIONS_DIR)


## Save an invention to disk
func save_invention(machine_name: String, purpose: String, machine_data: Dictionary) -> String:
	var filename: String = _sanitize_filename(machine_name) + "_" + str(Time.get_unix_time_from_system())
	var path: String = INVENTIONS_DIR + filename + ".json"

	var save_data: Dictionary = {
		"version": 1,
		"name": machine_name,
		"purpose": purpose,
		"timestamp": Time.get_unix_time_from_system(),
		"machine_data": machine_data,
	}

	var json_str: String = JSON.stringify(save_data, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("InventionManager: Failed to save invention to '%s'" % path)
		return ""

	file.store_string(json_str)
	file.close()
	return filename


## Load an invention from disk
func load_invention(filename: String) -> Dictionary:
	var path: String = INVENTIONS_DIR + filename + ".json"
	if not FileAccess.file_exists(path):
		push_warning("InventionManager: File not found '%s'" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var json_str: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var err: Error = json.parse(json_str)
	if err != OK:
		push_warning("InventionManager: Failed to parse '%s'" % path)
		return {}

	return json.data


## Delete an invention
func delete_invention(filename: String) -> void:
	var path: String = INVENTIONS_DIR + filename + ".json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


## List all saved inventions (metadata only)
func list_inventions() -> Array[Dictionary]:
	var inventions: Array[Dictionary] = []
	var dir := DirAccess.open(INVENTIONS_DIR)
	if dir == null:
		return inventions

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var data: Dictionary = load_invention(file_name.get_basename())
			if not data.is_empty():
				inventions.append({
					"filename": file_name.get_basename(),
					"name": data.get("name", "Unnamed"),
					"purpose": data.get("purpose", ""),
					"timestamp": data.get("timestamp", 0),
					"component_count": _count_components(data),
				})
		file_name = dir.get_next()
	dir.list_dir_end()

	# Sort by timestamp, newest first
	inventions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("timestamp", 0) > b.get("timestamp", 0)
	)
	return inventions


## Count components in a save file
func _count_components(data: Dictionary) -> int:
	var machine: Dictionary = data.get("machine_data", {})
	var components: Array = machine.get("components", [])
	return components.size()


## Sanitize a filename — letters, numbers, underscore only
func _sanitize_filename(name: String) -> String:
	var result: String = ""
	for c in name:
		if c.is_valid_identifier() or c == "_":
			result += c
		elif c == " ":
			result += "_"
	if result.is_empty():
		result = "invention"
	return result.to_lower()
