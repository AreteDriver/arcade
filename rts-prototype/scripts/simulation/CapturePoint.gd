extends Area3D
class_name CapturePoint
## CapturePoint.gd - Capture zone simulation logic
## Handles capture progress, ownership, and contestation.

signal ownership_changed(point: CapturePoint, old_owner: int, new_owner: int)
signal capture_progress_changed(point: CapturePoint, progress: float, capturing_team: int)
signal contested_state_changed(point: CapturePoint, is_contested: bool)

@export var point_id: String = "A"
@export var capture_time: float = 8.0
@export var capture_radius: float = 10.0

var owning_team: int = -1  # -1 = neutral
var capture_progress: float = 0.0
var capturing_team: int = -1
var is_contested: bool = false

var _squads_in_zone: Array[Node3D] = []
var _zone_mesh: MeshInstance3D
var _flag_mesh: MeshInstance3D
var _label_3d: Label3D

# Team colors
const COLOR_NEUTRAL := Color(0.5, 0.5, 0.5, 0.3)
const COLOR_PLAYER := Color(0.2, 0.5, 1.0, 0.3)
const COLOR_ENEMY := Color(1.0, 0.2, 0.2, 0.3)
const COLOR_CONTESTED := Color(1.0, 0.8, 0.0, 0.4)


func _ready() -> void:
	_setup_visuals()
	_setup_collision()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Register with GameState
	GameState.register_capture_point(self)


func _physics_process(delta: float) -> void:
	if GameState.current_phase != GameState.MatchPhase.PLAYING:
		return

	_clean_invalid_squads()
	_update_capture_logic(delta)
	_update_visuals()


func _setup_visuals() -> void:
	# Zone indicator (cylinder)
	_zone_mesh = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = capture_radius
	cylinder.bottom_radius = capture_radius
	cylinder.height = 0.2
	_zone_mesh.mesh = cylinder

	var zone_material := StandardMaterial3D.new()
	zone_material.albedo_color = COLOR_NEUTRAL
	zone_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	zone_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_zone_mesh.material_override = zone_material
	_zone_mesh.position.y = 0.1
	add_child(_zone_mesh)

	# Flag pole and flag
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.15
	pole_mesh.bottom_radius = 0.15
	pole_mesh.height = 8.0
	pole.mesh = pole_mesh
	pole.position.y = 4.0

	var pole_material := StandardMaterial3D.new()
	pole_material.albedo_color = Color(0.3, 0.3, 0.3)
	pole.material_override = pole_material
	add_child(pole)

	# Flag
	_flag_mesh = MeshInstance3D.new()
	var flag := BoxMesh.new()
	flag.size = Vector3(3.0, 2.0, 0.1)
	_flag_mesh.mesh = flag
	_flag_mesh.position = Vector3(1.5, 7.0, 0)

	var flag_material := StandardMaterial3D.new()
	flag_material.albedo_color = Color(0.5, 0.5, 0.5)
	_flag_mesh.material_override = flag_material
	add_child(_flag_mesh)

	# Point label
	_label_3d = Label3D.new()
	_label_3d.text = point_id
	_label_3d.font_size = 128
	_label_3d.position = Vector3(0, 10, 0)
	_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_3d.no_depth_test = true
	add_child(_label_3d)


func _setup_collision() -> void:
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = capture_radius
	shape.height = 5.0
	collision.shape = shape
	collision.position.y = 2.5
	add_child(collision)

	collision_layer = 8  # Layer 4 (capture zones)
	collision_mask = 2   # Layer 2 (units)
	monitoring = true
	monitorable = false


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("get_team") and body not in _squads_in_zone:
		_squads_in_zone.append(body)


func _on_body_exited(body: Node3D) -> void:
	var idx := _squads_in_zone.find(body)
	if idx >= 0:
		_squads_in_zone.remove_at(idx)


func _clean_invalid_squads() -> void:
	_squads_in_zone = _squads_in_zone.filter(func(s): return is_instance_valid(s))


func _update_capture_logic(delta: float) -> void:
	var player_count := 0
	var enemy_count := 0

	for squad in _squads_in_zone:
		if not is_instance_valid(squad):
			continue
		if squad.team == GameState.Team.PLAYER:
			player_count += 1
		else:
			enemy_count += 1

	var old_contested := is_contested
	is_contested = player_count > 0 and enemy_count > 0

	if is_contested != old_contested:
		contested_state_changed.emit(self, is_contested)

	if is_contested:
		# Contested - no progress
		return

	var dominant_team := -1
	var capture_strength := 0

	if player_count > enemy_count:
		dominant_team = GameState.Team.PLAYER
		capture_strength = player_count - enemy_count
	elif enemy_count > player_count:
		dominant_team = GameState.Team.ENEMY
		capture_strength = enemy_count - player_count

	if dominant_team == -1:
		# No one in zone, decay progress slowly
		if capture_progress > 0:
			capture_progress = maxf(0.0, capture_progress - delta / capture_time * 0.5)
			capture_progress_changed.emit(self, capture_progress, capturing_team)
		return

	if owning_team == dominant_team:
		# Already owned, no change needed
		if capture_progress > 0 and capturing_team != dominant_team:
			capture_progress = maxf(0.0, capture_progress - delta / capture_time)
			if capture_progress == 0:
				capturing_team = -1
			capture_progress_changed.emit(self, capture_progress, capturing_team)
		return

	# Capturing or decapping
	if capturing_team == dominant_team or capturing_team == -1:
		capturing_team = dominant_team
		var rate := delta / capture_time * capture_strength
		capture_progress = minf(1.0, capture_progress + rate)
		capture_progress_changed.emit(self, capture_progress, capturing_team)

		if capture_progress >= 1.0:
			_complete_capture(dominant_team)
	else:
		# Decapping first
		capture_progress = maxf(0.0, capture_progress - delta / capture_time)
		if capture_progress == 0:
			capturing_team = dominant_team
		capture_progress_changed.emit(self, capture_progress, capturing_team)


func _complete_capture(new_owner: int) -> void:
	var old_owner := owning_team
	owning_team = new_owner
	capture_progress = 0.0
	capturing_team = -1

	ownership_changed.emit(self, old_owner, new_owner)


func _update_visuals() -> void:
	var zone_color: Color
	var flag_color: Color

	if is_contested:
		zone_color = COLOR_CONTESTED
		flag_color = Color(1.0, 0.8, 0.0)
	elif owning_team == GameState.Team.PLAYER:
		zone_color = COLOR_PLAYER
		flag_color = Color(0.2, 0.5, 1.0)
	elif owning_team == GameState.Team.ENEMY:
		zone_color = COLOR_ENEMY
		flag_color = Color(1.0, 0.2, 0.2)
	else:
		zone_color = COLOR_NEUTRAL
		flag_color = Color(0.5, 0.5, 0.5)

	if _zone_mesh and _zone_mesh.material_override:
		(_zone_mesh.material_override as StandardMaterial3D).albedo_color = zone_color

	if _flag_mesh and _flag_mesh.material_override:
		(_flag_mesh.material_override as StandardMaterial3D).albedo_color = flag_color


func get_team() -> int:
	return owning_team


func is_owned_by(team: int) -> bool:
	return owning_team == team


func get_squads_in_zone() -> Array[Node3D]:
	return _squads_in_zone.duplicate()
