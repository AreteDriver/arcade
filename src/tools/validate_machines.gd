@tool
extends EditorScript

## Machine Definition Validator — run from Editor > Run Script.
## Validates all .tres machine definitions for consistency:
## - All component types exist in the registry
## - Connection ports reference valid component IDs
## - Challenge data references valid component IDs
## - Required fields are present
## - Par times are sensible
## - Unlock rewards reference valid component types

const MACHINE_DIR: String = "res://content/machines/"
const VALID_TYPES: Array[String] = [
	"ramp", "pipe", "fan", "gear", "spring", "switch", "conveyor", "valve",
	"fusion_core", "gravity_node", "plasma_conduit", "quantum_coupler",
	"chrono_spring", "phase_gate", "warp_belt", "holo_projector",
	"dimensional_splitter", "time_loop_relay", "emotion_sensor",
	"sound_forge", "cloud_weaver",
]
const VALID_CHALLENGES: Array[String] = ["broken", "miscalibrated", "incomplete", "overloaded"]

var _errors: Array[String] = []
var _warnings: Array[String] = []
var _files_checked: int = 0


func _run() -> void:
	_errors.clear()
	_warnings.clear()
	_files_checked = 0

	print("=== Machine Definition Validator ===")
	print("")

	for world in range(1, 5):
		for level in range(1, 5):
			var path: String = "%sworld%d/level_%d_%d.tres" % [MACHINE_DIR, world, world, level]
			_validate_file(path, world, level)

	print("")
	print("=== Results ===")
	print("Files checked: %d" % _files_checked)

	if _warnings.size() > 0:
		print("")
		print("WARNINGS (%d):" % _warnings.size())
		for w in _warnings:
			print("  [WARN] %s" % w)

	if _errors.size() > 0:
		print("")
		print("ERRORS (%d):" % _errors.size())
		for e in _errors:
			print("  [ERR]  %s" % e)
	else:
		print("")
		print("All definitions valid!")


func _validate_file(path: String, expected_world: int, expected_level: int) -> void:
	if not ResourceLoader.exists(path):
		_errors.append("%s — file not found" % path)
		return

	var res: Resource = ResourceLoader.load(path)
	if res == null or not (res is MachineDefinition):
		_errors.append("%s — not a valid MachineDefinition" % path)
		return

	_files_checked += 1
	var def: MachineDefinition = res as MachineDefinition
	var prefix: String = "level_%d_%d" % [expected_world, expected_level]

	# World/level match filename
	if def.world != expected_world:
		_errors.append("%s — world is %d, expected %d" % [prefix, def.world, expected_world])
	if def.level != expected_level:
		_errors.append("%s — level is %d, expected %d" % [prefix, def.level, expected_level])

	# Required fields
	if def.machine_name.is_empty():
		_errors.append("%s — missing machine_name" % prefix)
	if def.challenge_type not in VALID_CHALLENGES:
		_errors.append("%s — invalid challenge_type '%s'" % [prefix, def.challenge_type])
	if def.objectives.is_empty():
		_warnings.append("%s — no objectives defined" % prefix)
	if def.intro_dialog.is_empty():
		_warnings.append("%s — no intro_dialog" % prefix)
	if def.success_dialog.is_empty():
		_warnings.append("%s — no success_dialog" % prefix)

	# Par times
	if def.par_time_3_star <= 0:
		_warnings.append("%s — par_time_3_star is %s" % [prefix, str(def.par_time_3_star)])
	if def.par_time_2_star <= def.par_time_3_star:
		_warnings.append("%s — par_time_2_star (%s) <= par_time_3_star (%s)" % [
			prefix, str(def.par_time_2_star), str(def.par_time_3_star)])

	# Machine data — component validation
	var data: Dictionary = def.machine_data
	if not data.has("components"):
		_errors.append("%s — machine_data missing 'components' key" % prefix)
		return

	var comp_ids: Array[String] = []
	for comp: Dictionary in data["components"]:
		var comp_id: String = comp.get("id", "")
		var comp_type: String = comp.get("type", "")

		if comp_id.is_empty():
			_errors.append("%s — component missing 'id'" % prefix)
		if comp_type.is_empty():
			_errors.append("%s — component '%s' missing 'type'" % [prefix, comp_id])
		elif comp_type not in VALID_TYPES:
			_errors.append("%s — component '%s' has unknown type '%s'" % [prefix, comp_id, comp_type])

		if not comp.has("position"):
			_warnings.append("%s — component '%s' missing position" % [prefix, comp_id])

		comp_ids.append(comp_id)

	# Validate connections reference existing component IDs
	for comp: Dictionary in data["components"]:
		for conn: Dictionary in comp.get("connections", []):
			var target: String = conn.get("to", "")
			if target not in comp_ids:
				_errors.append("%s — component '%s' connects to unknown ID '%s'" % [
					prefix, comp.get("id", "?"), target])

	# Validate available_components
	for avail in def.available_components:
		if avail not in VALID_TYPES:
			_errors.append("%s — available_components has unknown type '%s'" % [prefix, avail])

	# Validate unlock_rewards
	for reward in def.unlock_rewards:
		if reward not in VALID_TYPES:
			_errors.append("%s — unlock_rewards has unknown type '%s'" % [prefix, reward])

	# Validate locked_component_ids reference existing components
	for locked_id in def.locked_component_ids:
		if locked_id not in comp_ids:
			_warnings.append("%s — locked_component_ids references unknown '%s'" % [prefix, locked_id])

	# Challenge-specific validation
	_validate_challenge(prefix, def.challenge_type, def.challenge_data, comp_ids)

	print("  [OK] %s — '%s' (%s)" % [prefix, def.machine_name, def.challenge_type])


func _validate_challenge(prefix: String, ctype: String, cdata: Dictionary, comp_ids: Array[String]) -> void:
	match ctype:
		"broken":
			if not cdata.has("broken_ids"):
				_errors.append("%s — broken challenge missing 'broken_ids'" % prefix)
			else:
				for bid in cdata["broken_ids"]:
					if bid not in comp_ids:
						_errors.append("%s — broken_ids references unknown '%s'" % [prefix, bid])
		"miscalibrated":
			if not cdata.has("target_params"):
				_errors.append("%s — miscalibrated challenge missing 'target_params'" % prefix)
			else:
				for cid in cdata["target_params"]:
					if cid not in comp_ids:
						_errors.append("%s — target_params references unknown component '%s'" % [prefix, cid])
		"incomplete":
			if not cdata.has("missing_slots"):
				_errors.append("%s — incomplete challenge missing 'missing_slots'" % prefix)
			else:
				for slot: Dictionary in cdata["missing_slots"]:
					var slot_type: String = slot.get("type", "")
					if slot_type not in VALID_TYPES:
						_errors.append("%s — missing_slots has unknown type '%s'" % [prefix, slot_type])
		"overloaded":
			if not cdata.has("overload_threshold") and not cdata.has("target_overloaded"):
				_warnings.append("%s — overloaded challenge missing threshold config" % prefix)
