extends RefCounted
class_name Command
## Command.gd - Base command class
## For future expansion into a full command pattern.

enum Type { NONE, MOVE, ATTACK, CAPTURE, STOP }

var type: Type = Type.NONE
var target_position: Vector3 = Vector3.ZERO
var target_unit: Node3D = null
var target_point: Node3D = null
var timestamp: int = 0


func _init() -> void:
	timestamp = Time.get_ticks_msec()


func execute(_squad: Node3D) -> void:
	pass


func is_complete(_squad: Node3D) -> bool:
	return true
