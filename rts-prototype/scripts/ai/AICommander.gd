extends Node
class_name AICommander
## AICommander.gd - AI decision-making for enemy team
## Evaluates map state and issues commands to AI-controlled squads.

signal ai_command_issued(squad: Node3D, command_type: String, target: Variant)

@export var team: int = GameState.Team.ENEMY
@export var decision_interval: float = 2.0
@export var aggression: float = 0.5  # 0 = defensive, 1 = aggressive

var _decision_timer: float = 0.0
var _reinforce_check_timer: float = 0.0
const REINFORCE_CHECK_INTERVAL: float = 5.0


func _physics_process(delta: float) -> void:
	if GameState.current_phase != GameState.MatchPhase.PLAYING:
		return

	_decision_timer += delta
	_reinforce_check_timer += delta

	if _decision_timer >= decision_interval:
		_decision_timer = 0.0
		_make_decisions()

	if _reinforce_check_timer >= REINFORCE_CHECK_INTERVAL:
		_reinforce_check_timer = 0.0
		_consider_reinforcements()


func _make_decisions() -> void:
	var my_squads := GameState.get_squads_for_team(team)

	for squad in my_squads:
		if not is_instance_valid(squad):
			continue

		# Skip if already busy with something important
		if squad.current_state == Squad.State.ATTACKING and is_instance_valid(squad.target_unit):
			continue

		_decide_for_squad(squad)


func _decide_for_squad(squad: Node3D) -> void:
	# Priority 1: Respond to nearby enemies
	var nearby_enemy := _find_nearby_threat(squad)
	if nearby_enemy:
		var should_attack := randf() < aggression + 0.3
		if should_attack:
			squad.issue_attack_command(nearby_enemy)
			ai_command_issued.emit(squad, "attack", nearby_enemy)
			return

	# Priority 2: Capture objectives
	var target_point := _find_best_capture_target(squad)
	if target_point:
		squad.issue_capture_command(target_point)
		ai_command_issued.emit(squad, "capture", target_point)
		return

	# Priority 3: Defend owned points
	var defend_point := _find_point_to_defend(squad)
	if defend_point:
		var dist := squad.global_position.distance_to(defend_point.global_position)
		if dist > defend_point.capture_radius:
			squad.issue_capture_command(defend_point)
			ai_command_issued.emit(squad, "defend", defend_point)
		return

	# Priority 4: Patrol toward center
	_patrol_toward_center(squad)


func _find_nearby_threat(squad: Node3D) -> Node3D:
	var threat_range := CombatResolver.get_engagement_range() * 1.5
	var enemies := GameState.get_enemy_squads(team)

	var nearest: Node3D = null
	var nearest_dist := INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var dist := squad.global_position.distance_to(enemy.global_position)
		if dist < threat_range and dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return nearest


func _find_best_capture_target(squad: Node3D) -> Node3D:
	var best_point: Node3D = null
	var best_score := -INF

	for point in GameState.capture_points:
		if not is_instance_valid(point):
			continue

		var score := _evaluate_capture_point(squad, point)
		if score > best_score:
			best_score = score
			best_point = point

	# Only return if score is positive (worth capturing)
	return best_point if best_score > 0 else null


func _evaluate_capture_point(squad: Node3D, point: Node3D) -> float:
	var score := 0.0
	var distance := squad.global_position.distance_to(point.global_position)

	# Ownership factor
	if point.owning_team == -1:  # Neutral
		score += 100.0
	elif point.owning_team != team:  # Enemy owned
		score += 150.0
	else:  # Already owned
		score -= 200.0  # Don't need to capture

	# Distance penalty
	score -= distance * 1.0

	# Contestation bonus (prioritize contested points)
	if point.is_contested:
		score += 50.0

	# Already have squads there penalty
	var my_squads_at_point := 0
	for s in GameState.get_squads_for_team(team):
		if is_instance_valid(s) and s != squad:
			if s.target_capture_point == point or \
			   s.global_position.distance_to(point.global_position) < point.capture_radius:
				my_squads_at_point += 1

	score -= my_squads_at_point * 30.0

	return score


func _find_point_to_defend(squad: Node3D) -> Node3D:
	var owned_points := GameState.get_capture_points_by_owner(team)

	if owned_points.is_empty():
		return null

	# Prioritize contested points
	for point in owned_points:
		if point.is_contested:
			return point

	# Otherwise, defend nearest owned point with few defenders
	var best_point: Node3D = null
	var best_score := -INF

	for point in owned_points:
		var distance := squad.global_position.distance_to(point.global_position)
		var defenders := _count_defenders(point)

		var score := 100.0 - distance - defenders * 50.0

		if score > best_score:
			best_score = score
			best_point = point

	return best_point


func _count_defenders(point: Node3D) -> int:
	var count := 0
	for squad in GameState.get_squads_for_team(team):
		if not is_instance_valid(squad):
			continue
		if squad.target_capture_point == point or \
		   squad.global_position.distance_to(point.global_position) < point.capture_radius:
			count += 1
	return count


func _patrol_toward_center(squad: Node3D) -> void:
	# Move toward map center with some randomness
	var center := Vector3.ZERO
	var offset := Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))
	var target := center + offset

	squad.issue_move_command(target)
	ai_command_issued.emit(squad, "patrol", target)


func _consider_reinforcements() -> void:
	# Check if we can and should spawn reinforcements
	if not Economy.is_off_cooldown(team):
		return

	var my_squad_count := GameState.get_squads_for_team(team).size()
	var enemy_squad_count := GameState.get_enemy_squads(team).size()

	# Spawn if we have fewer squads or randomly
	var should_spawn := my_squad_count < enemy_squad_count or \
						(my_squad_count < 5 and randf() < 0.3)

	if not should_spawn:
		return

	# Choose squad type based on situation
	var squad_type := _choose_reinforcement_type()

	if not Economy.can_afford(team, squad_type):
		# Try cheaper option
		squad_type = GameState.SquadType.INFANTRY
		if not Economy.can_afford(team, squad_type):
			return

	# Find spawn position
	var spawn_pos := _find_spawn_position()

	Economy.request_reinforcement(team, squad_type, spawn_pos)


func _choose_reinforcement_type() -> int:
	var my_squads := GameState.get_squads_for_team(team)

	# Count current composition
	var infantry_count := 0
	var support_count := 0
	var vehicle_count := 0

	for squad in my_squads:
		match squad.squad_type:
			GameState.SquadType.INFANTRY:
				infantry_count += 1
			GameState.SquadType.SUPPORT:
				support_count += 1
			GameState.SquadType.VEHICLE:
				vehicle_count += 1

	# Prefer balanced composition
	if vehicle_count == 0 and Economy.can_afford(team, GameState.SquadType.VEHICLE):
		return GameState.SquadType.VEHICLE
	elif infantry_count <= support_count:
		return GameState.SquadType.INFANTRY
	else:
		return GameState.SquadType.SUPPORT


func _find_spawn_position() -> Vector3:
	# Prefer spawning at owned capture points
	var owned := GameState.get_capture_points_by_owner(team)

	if owned.size() > 0:
		var point: Node3D = owned[randi() % owned.size()]
		var offset := Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
		return point.global_position + offset
	else:
		# Fallback to team spawn area
		return GameState.get_spawn_position_for_team(team)
