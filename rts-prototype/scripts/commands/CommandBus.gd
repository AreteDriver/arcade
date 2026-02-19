extends Node
## CommandBus.gd - Central command dispatcher (Autoload)
## Decouples UI from simulation by routing all commands through a single bus.
## This is the primary interface for issuing orders to squads.

signal command_issued(command_type: String, squads: Array, target: Variant)
signal move_command_issued(squads: Array[Node3D], position: Vector3)
signal attack_command_issued(squads: Array[Node3D], target: Node3D)
signal capture_command_issued(squads: Array[Node3D], point: Node3D)
signal stop_command_issued(squads: Array[Node3D])

# Command history for potential replay/networking
var command_history: Array[Dictionary] = []
var _command_id: int = 0


func _ready() -> void:
	pass


func issue_move(squads: Array, position: Vector3) -> void:
	if squads.is_empty():
		return

	var typed_squads: Array[Node3D] = []
	for squad in squads:
		if is_instance_valid(squad) and squad is Node3D:
			typed_squads.append(squad)

	if typed_squads.is_empty():
		return

	# Calculate formation positions
	var positions := _calculate_formation_positions(position, typed_squads.size())

	for i in typed_squads.size():
		var squad := typed_squads[i]
		squad.issue_move_command(positions[i])

	_log_command("move", typed_squads, position)
	command_issued.emit("move", typed_squads, position)
	move_command_issued.emit(typed_squads, position)


func issue_attack(squads: Array, target: Node3D) -> void:
	if squads.is_empty() or not is_instance_valid(target):
		return

	var typed_squads: Array[Node3D] = []
	for squad in squads:
		if is_instance_valid(squad) and squad is Node3D:
			typed_squads.append(squad)

	if typed_squads.is_empty():
		return

	for squad in typed_squads:
		squad.issue_attack_command(target)

	_log_command("attack", typed_squads, target)
	command_issued.emit("attack", typed_squads, target)
	attack_command_issued.emit(typed_squads, target)


func issue_capture(squads: Array, capture_point: Node3D) -> void:
	if squads.is_empty() or not is_instance_valid(capture_point):
		return

	var typed_squads: Array[Node3D] = []
	for squad in squads:
		if is_instance_valid(squad) and squad is Node3D:
			typed_squads.append(squad)

	if typed_squads.is_empty():
		return

	for squad in typed_squads:
		squad.issue_capture_command(capture_point)

	_log_command("capture", typed_squads, capture_point)
	command_issued.emit("capture", typed_squads, capture_point)
	capture_command_issued.emit(typed_squads, capture_point)


func issue_stop(squads: Array) -> void:
	if squads.is_empty():
		return

	var typed_squads: Array[Node3D] = []
	for squad in squads:
		if is_instance_valid(squad) and squad is Node3D:
			typed_squads.append(squad)

	if typed_squads.is_empty():
		return

	for squad in typed_squads:
		squad.stop_command()

	_log_command("stop", typed_squads, null)
	command_issued.emit("stop", typed_squads, null)
	stop_command_issued.emit(typed_squads)


func _calculate_formation_positions(center: Vector3, count: int) -> Array[Vector3]:
	var positions: Array[Vector3] = []

	if count == 1:
		positions.append(center)
		return positions

	# Simple grid formation
	var cols := ceili(sqrt(float(count)))
	var spacing := 3.0

	var start_x := center.x - (cols - 1) * spacing / 2.0
	var start_z := center.z - (cols - 1) * spacing / 2.0

	for i in count:
		var row := i / cols
		var col := i % cols
		var pos := Vector3(
			start_x + col * spacing,
			center.y,
			start_z + row * spacing
		)
		positions.append(pos)

	return positions


func _log_command(command_type: String, squads: Array[Node3D], target: Variant) -> void:
	_command_id += 1

	var squad_ids: Array[int] = []
	for squad in squads:
		squad_ids.append(squad.get_instance_id())

	var target_id: int = -1
	if target is Node3D and is_instance_valid(target):
		target_id = target.get_instance_id()

	var entry := {
		"id": _command_id,
		"type": command_type,
		"squads": squad_ids,
		"target": target_id,
		"timestamp": Time.get_ticks_msec()
	}

	command_history.append(entry)

	# Limit history size
	if command_history.size() > 1000:
		command_history.pop_front()


func get_last_command() -> Dictionary:
	if command_history.is_empty():
		return {}
	return command_history.back()


func clear_history() -> void:
	command_history.clear()
