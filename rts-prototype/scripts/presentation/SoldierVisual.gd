extends Node3D
class_name SoldierVisual
## SoldierVisual.gd - Individual soldier visual representation
## Lightweight formation visual that follows its squad.

var target_offset: Vector3 = Vector3.ZERO
var move_speed: float = 8.0

var _body_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D


func _ready() -> void:
	# Visuals are created by Squad.gd if scene doesn't exist
	pass


func set_color(color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color

	if _body_mesh:
		_body_mesh.material_override = mat
	if _head_mesh:
		_head_mesh.material_override = mat.duplicate()

	# Also apply to any existing children
	for child in get_children():
		if child is MeshInstance3D:
			child.material_override = mat.duplicate()


func set_visible_soldiers(count: int, my_index: int) -> void:
	# Show/hide based on squad casualties
	visible = my_index < count
