extends CharacterBody3D
class_name Squad
## Squad.gd - Core squad simulation entity
## Handles movement, combat, and state machine for commands.

signal health_changed(squad: Squad, current: float, max_hp: float)
signal command_changed(squad: Squad, command_type: String)
signal squad_died(squad: Squad)

enum State { IDLE, MOVING, ATTACKING, CAPTURING, DEAD }

@export var squad_type: int = GameState.SquadType.INFANTRY
@export var team: int = GameState.Team.PLAYER

# Stats based on squad type (set in _ready)
var max_health: float = 100.0
var current_health: float = 100.0
var move_speed: float = 8.0
var soldier_count: int = 5

# State machine
var current_state: State = State.IDLE
var current_command: Node = null
var target_position: Vector3
var target_unit: Node3D = null
var target_capture_point: Node3D = null

# Combat
var attack_cooldown: float = 0.0
var in_combat: bool = false

# Visuals
var _soldier_visuals: Array[Node3D] = []
var _selection_ring: MeshInstance3D
var _health_bar: Node3D
var _body_mesh: MeshInstance3D

# Formation
const FORMATION_SPREAD: float = 1.5
const STEERING_FORCE: float = 15.0
const ARRIVAL_THRESHOLD: float = 1.5

# Team colors
const COLOR_PLAYER := Color(0.2, 0.5, 1.0)
const COLOR_ENEMY := Color(1.0, 0.2, 0.2)


func _ready() -> void:
	_apply_squad_type_stats()
	_setup_visuals()
	_spawn_soldier_visuals()


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	_update_state_machine(delta)
	_update_combat(delta)
	_update_soldier_formations(delta)
	_update_health_bar()


func _apply_squad_type_stats() -> void:
	match squad_type:
		GameState.SquadType.INFANTRY:
			max_health = 100.0
			move_speed = 8.0
			soldier_count = 5
		GameState.SquadType.SUPPORT:
			max_health = 80.0
			move_speed = 6.0
			soldier_count = 4
		GameState.SquadType.VEHICLE:
			max_health = 200.0
			move_speed = 12.0
			soldier_count = 1

	current_health = max_health


func _setup_visuals() -> void:
	# Main body (invisible, just for collision)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 1.0
	shape.height = 2.0
	collision.shape = shape
	collision.position.y = 1.0
	add_child(collision)

	collision_layer = 2  # Units layer
	collision_mask = 1 | 4  # Ground + obstacles

	# Selection ring
	_selection_ring = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 2.0
	ring.outer_radius = 2.5
	ring.rings = 16
	ring.ring_segments = 32
	_selection_ring.mesh = ring
	_selection_ring.rotation.x = -PI / 2
	_selection_ring.position.y = 0.1

	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.0, 1.0, 0.0, 0.8)
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_selection_ring.material_override = ring_material
	_selection_ring.visible = false
	add_child(_selection_ring)

	# Health bar background
	_health_bar = Node3D.new()
	_health_bar.position.y = 3.5

	var bg := MeshInstance3D.new()
	var bg_mesh := BoxMesh.new()
	bg_mesh.size = Vector3(2.2, 0.3, 0.05)
	bg.mesh = bg_mesh
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.1, 0.1, 0.1)
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg.material_override = bg_mat
	bg.name = "Background"
	_health_bar.add_child(bg)

	var fg := MeshInstance3D.new()
	var fg_mesh := BoxMesh.new()
	fg_mesh.size = Vector3(2.0, 0.2, 0.06)
	fg.mesh = fg_mesh
	var fg_mat := StandardMaterial3D.new()
	fg_mat.albedo_color = Color(0.2, 0.8, 0.2)
	fg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fg.material_override = fg_mat
	fg.name = "Foreground"
	fg.position.z = 0.01
	_health_bar.add_child(fg)

	add_child(_health_bar)


func _spawn_soldier_visuals() -> void:
	var soldier_scene := load("res://scenes/units/SoldierVisual.tscn") as PackedScene

	for i in soldier_count:
		var soldier: Node3D
		if soldier_scene:
			soldier = soldier_scene.instantiate()
		else:
			soldier = _create_primitive_soldier()

		soldier.name = "Soldier_%d" % i
		add_child(soldier)
		_soldier_visuals.append(soldier)

		# Set team color
		_set_soldier_color(soldier, team)

		# Initial formation position
		var angle := (2 * PI / soldier_count) * i
		var offset := Vector3(cos(angle), 0, sin(angle)) * FORMATION_SPREAD
		soldier.position = offset
		soldier.position.y = 0


func _create_primitive_soldier() -> Node3D:
	var soldier := Node3D.new()

	if squad_type == GameState.SquadType.VEHICLE:
		# Vehicle mesh
		var body := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(3.0, 1.5, 4.0)
		body.mesh = box
		body.position.y = 0.75
		body.name = "Body"
		soldier.add_child(body)

		var turret := MeshInstance3D.new()
		var turret_mesh := BoxMesh.new()
		turret_mesh.size = Vector3(1.5, 0.8, 2.0)
		turret.mesh = turret_mesh
		turret.position = Vector3(0, 1.75, -0.3)
		turret.name = "Turret"
		soldier.add_child(turret)
	else:
		# Infantry capsule
		var body := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.3
		capsule.height = 1.6
		body.mesh = capsule
		body.position.y = 0.8
		body.name = "Body"
		soldier.add_child(body)

		# Head
		var head := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.2
		head.mesh = sphere
		head.position.y = 1.7
		head.name = "Head"
		soldier.add_child(head)

	return soldier


func _set_soldier_color(soldier: Node3D, soldier_team: int) -> void:
	var color := COLOR_PLAYER if soldier_team == GameState.Team.PLAYER else COLOR_ENEMY

	for child in soldier.get_children():
		if child is MeshInstance3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = color
			child.material_override = mat


func _update_state_machine(delta: float) -> void:
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.MOVING:
			_state_moving(delta)
		State.ATTACKING:
			_state_attacking(delta)
		State.CAPTURING:
			_state_capturing(delta)


func _state_idle(_delta: float) -> void:
	velocity = Vector3.ZERO


func _state_moving(delta: float) -> void:
	var to_target := target_position - global_position
	to_target.y = 0
	var distance := to_target.length()

	if distance < ARRIVAL_THRESHOLD:
		current_state = State.IDLE
		command_changed.emit(self, "idle")
		return

	var direction := to_target.normalized()
	velocity = direction * move_speed

	move_and_slide()


func _state_attacking(delta: float) -> void:
	if not is_instance_valid(target_unit):
		current_state = State.IDLE
		target_unit = null
		command_changed.emit(self, "idle")
		return

	var distance := global_position.distance_to(target_unit.global_position)
	var engage_range := CombatResolver.get_engagement_range()

	if distance > engage_range:
		# Move closer
		var direction := (target_unit.global_position - global_position).normalized()
		direction.y = 0
		velocity = direction * move_speed
		move_and_slide()
	else:
		# In range, stop and shoot
		velocity = Vector3.ZERO
		# Combat handled in _update_combat


func _state_capturing(delta: float) -> void:
	if not is_instance_valid(target_capture_point):
		current_state = State.IDLE
		target_capture_point = null
		command_changed.emit(self, "idle")
		return

	var distance := global_position.distance_to(target_capture_point.global_position)
	var capture_radius: float = target_capture_point.capture_radius if target_capture_point.has_method("get_team") else 10.0

	if distance > capture_radius - 2.0:
		# Move into capture zone
		var direction := (target_capture_point.global_position - global_position).normalized()
		direction.y = 0
		velocity = direction * move_speed
		move_and_slide()
	else:
		# Inside zone, just hold
		velocity = Vector3.ZERO


func _update_combat(delta: float) -> void:
	in_combat = false

	# Find and engage enemies in range
	var targets := CombatResolver.find_targets_in_range(self)

	if targets.is_empty():
		return

	in_combat = true

	# If we have an explicit target and it's in range, prioritize it
	var primary_target: Node3D = null
	if is_instance_valid(target_unit) and target_unit in targets:
		primary_target = target_unit
	else:
		primary_target = CombatResolver.get_best_target(self)

	if primary_target:
		CombatResolver.resolve_combat_tick(self, primary_target, delta)


func _update_soldier_formations(delta: float) -> void:
	for i in _soldier_visuals.size():
		var soldier := _soldier_visuals[i]
		if not is_instance_valid(soldier):
			continue

		var angle := (2 * PI / _soldier_visuals.size()) * i
		var target_offset := Vector3(cos(angle), 0, sin(angle)) * FORMATION_SPREAD

		# Add some variation based on movement
		if velocity.length() > 0.1:
			target_offset += velocity.normalized() * 0.3 * sin(Time.get_ticks_msec() * 0.01 + i)

		soldier.position = soldier.position.lerp(target_offset, delta * 5.0)
		soldier.position.y = 0


func _update_health_bar() -> void:
	if not _health_bar:
		return

	var health_pct := current_health / max_health
	var fg := _health_bar.get_node_or_null("Foreground") as MeshInstance3D

	if fg:
		fg.scale.x = health_pct
		fg.position.x = (health_pct - 1.0)

		var mat := fg.material_override as StandardMaterial3D
		if mat:
			if health_pct > 0.6:
				mat.albedo_color = Color(0.2, 0.8, 0.2)
			elif health_pct > 0.3:
				mat.albedo_color = Color(0.8, 0.8, 0.2)
			else:
				mat.albedo_color = Color(0.8, 0.2, 0.2)

	# Billboard effect
	if _health_bar and is_inside_tree():
		var camera := get_viewport().get_camera_3d()
		if camera:
			_health_bar.look_at(camera.global_position, Vector3.UP)


# Command interface
func issue_move_command(position: Vector3) -> void:
	target_position = position
	target_unit = null
	target_capture_point = null
	current_state = State.MOVING
	command_changed.emit(self, "move")


func issue_attack_command(target: Node3D) -> void:
	target_unit = target
	target_capture_point = null
	current_state = State.ATTACKING
	command_changed.emit(self, "attack")


func issue_capture_command(capture_point: Node3D) -> void:
	target_capture_point = capture_point
	target_unit = null
	current_state = State.CAPTURING
	command_changed.emit(self, "capture")


func stop_command() -> void:
	current_state = State.IDLE
	target_position = global_position
	target_unit = null
	target_capture_point = null
	command_changed.emit(self, "idle")


# Health interface
func take_damage(amount: float) -> void:
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(self, current_health, max_health)

	if current_health <= 0:
		_die()


func heal(amount: float) -> void:
	current_health = minf(max_health, current_health + amount)
	health_changed.emit(self, current_health, max_health)


func _die() -> void:
	current_state = State.DEAD
	squad_died.emit(self)
	GameState.unregister_squad(self)

	# Death effect
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.3)
	tween.tween_callback(queue_free)


# Selection interface
func set_selected(selected: bool) -> void:
	if _selection_ring:
		_selection_ring.visible = selected


func is_selected() -> bool:
	return _selection_ring.visible if _selection_ring else false


func get_team() -> int:
	return team


func get_state_name() -> String:
	match current_state:
		State.IDLE: return "Idle"
		State.MOVING: return "Moving"
		State.ATTACKING: return "Attacking"
		State.CAPTURING: return "Capturing"
		State.DEAD: return "Dead"
	return "Unknown"


func get_type_name() -> String:
	match squad_type:
		GameState.SquadType.INFANTRY: return "Infantry"
		GameState.SquadType.SUPPORT: return "Support"
		GameState.SquadType.VEHICLE: return "Vehicle"
	return "Unknown"
