extends Node
## CombatResolver.gd - DPS calculations and damage application
## Handles all combat resolution with cover and range modifiers.

signal damage_dealt(attacker: Node3D, target: Node3D, amount: float)
signal squad_killed(squad: Node3D, killer: Node3D)

const ENGAGEMENT_RANGE: float = 25.0
const OPTIMAL_RANGE: float = 15.0
const COVER_DAMAGE_REDUCTION: float = 0.5
const LINE_OF_SIGHT_CHECK_HEIGHT: float = 1.0

# Base DPS values per squad type
const DPS_INFANTRY: float = 20.0
const DPS_SUPPORT: float = 12.0
const DPS_VEHICLE: float = 35.0

# Damage modifiers
const VEHICLE_VS_INFANTRY_BONUS: float = 1.3
const INFANTRY_VS_VEHICLE_PENALTY: float = 0.6


func get_base_dps(squad_type: int) -> float:
	match squad_type:
		GameState.SquadType.INFANTRY:
			return DPS_INFANTRY
		GameState.SquadType.SUPPORT:
			return DPS_SUPPORT
		GameState.SquadType.VEHICLE:
			return DPS_VEHICLE
	return 10.0


func calculate_damage(attacker: Node3D, target: Node3D, delta: float) -> float:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return 0.0

	var distance := attacker.global_position.distance_to(target.global_position)

	# Out of range check
	if distance > ENGAGEMENT_RANGE:
		return 0.0

	# Base DPS
	var base_dps := get_base_dps(attacker.squad_type)

	# Range falloff (linear from optimal to max range)
	var range_modifier := 1.0
	if distance > OPTIMAL_RANGE:
		var falloff_range := ENGAGEMENT_RANGE - OPTIMAL_RANGE
		var beyond_optimal := distance - OPTIMAL_RANGE
		range_modifier = 1.0 - (beyond_optimal / falloff_range) * 0.5

	# Type matchup modifiers
	var type_modifier := 1.0
	if attacker.squad_type == GameState.SquadType.VEHICLE:
		if target.squad_type != GameState.SquadType.VEHICLE:
			type_modifier = VEHICLE_VS_INFANTRY_BONUS
	elif attacker.squad_type == GameState.SquadType.INFANTRY:
		if target.squad_type == GameState.SquadType.VEHICLE:
			type_modifier = INFANTRY_VS_VEHICLE_PENALTY

	# Cover check
	var cover_modifier := 1.0
	if is_target_in_cover(attacker, target):
		cover_modifier = 1.0 - COVER_DAMAGE_REDUCTION

	# Calculate final damage
	var damage := base_dps * range_modifier * type_modifier * cover_modifier * delta

	return damage


func is_target_in_cover(attacker: Node3D, target: Node3D) -> bool:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return false

	var space_state := attacker.get_world_3d().direct_space_state
	if not space_state:
		return false

	var from := attacker.global_position + Vector3.UP * LINE_OF_SIGHT_CHECK_HEIGHT
	var to := target.global_position + Vector3.UP * LINE_OF_SIGHT_CHECK_HEIGHT

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 4  # Obstacles layer (layer 3)
	query.exclude = [attacker.get_rid(), target.get_rid()] if attacker.has_method("get_rid") else []

	var result := space_state.intersect_ray(query)

	return result.size() > 0


func has_line_of_sight(from_unit: Node3D, to_unit: Node3D) -> bool:
	if not is_instance_valid(from_unit) or not is_instance_valid(to_unit):
		return false

	var space_state := from_unit.get_world_3d().direct_space_state
	if not space_state:
		return true  # Assume LOS if can't check

	var from := from_unit.global_position + Vector3.UP * LINE_OF_SIGHT_CHECK_HEIGHT
	var to := to_unit.global_position + Vector3.UP * LINE_OF_SIGHT_CHECK_HEIGHT

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 4  # Obstacles layer

	var result := space_state.intersect_ray(query)

	# No obstruction means we have LOS
	return result.size() == 0


func apply_damage(attacker: Node3D, target: Node3D, amount: float) -> void:
	if not is_instance_valid(target) or amount <= 0:
		return

	target.take_damage(amount)
	damage_dealt.emit(attacker, target, amount)

	if target.current_health <= 0:
		squad_killed.emit(target, attacker)


func resolve_combat_tick(attacker: Node3D, target: Node3D, delta: float) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return

	var damage := calculate_damage(attacker, target, delta)
	if damage > 0:
		apply_damage(attacker, target, damage)


func is_in_range(from_pos: Vector3, to_pos: Vector3) -> bool:
	return from_pos.distance_to(to_pos) <= ENGAGEMENT_RANGE


func get_engagement_range() -> float:
	return ENGAGEMENT_RANGE


func find_targets_in_range(squad: Node3D) -> Array[Node3D]:
	var targets: Array[Node3D] = []
	var enemies := GameState.get_enemy_squads(squad.team)

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if is_in_range(squad.global_position, enemy.global_position):
			targets.append(enemy)

	return targets


func get_best_target(squad: Node3D) -> Node3D:
	var targets := find_targets_in_range(squad)
	if targets.is_empty():
		return null

	# Prioritize: lowest HP, then closest
	var best_target: Node3D = null
	var best_score := -INF

	for target in targets:
		if not is_instance_valid(target):
			continue

		var distance := squad.global_position.distance_to(target.global_position)
		var hp_factor := 100.0 - target.current_health  # Lower HP = higher priority
		var dist_factor := (ENGAGEMENT_RANGE - distance) * 2  # Closer = higher priority

		var score := hp_factor + dist_factor

		if score > best_score:
			best_score = score
			best_target = target

	return best_target
