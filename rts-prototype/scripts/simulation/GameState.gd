extends Node
## GameState.gd - Authoritative match state manager
## Handles teams, victory conditions, squad registry, and match flow.

signal match_started
signal match_ended(winning_team: int)
signal squad_spawned(squad: Node3D)
signal squad_destroyed(squad: Node3D)
signal score_updated(team: int, score: int)
signal tickets_updated(team: int, tickets: int)

enum Team { PLAYER = 0, ENEMY = 1 }
enum MatchPhase { PRE_MATCH, PLAYING, POST_MATCH }
enum SquadType { INFANTRY, SUPPORT, VEHICLE }

const INITIAL_TICKETS: int = 200
const VICTORY_SCORE: int = 500
const SCORE_PER_POINT_PER_TICK: int = 1
const TICKET_DRAIN_PER_KILL: int = 5
const SCORE_TICK_INTERVAL: float = 1.0

var current_phase: MatchPhase = MatchPhase.PRE_MATCH
var team_scores: Array[int] = [0, 0]
var team_tickets: Array[int] = [INITIAL_TICKETS, INITIAL_TICKETS]
var all_squads: Array[Node3D] = []
var capture_points: Array[Node3D] = []
var squad_scene: PackedScene
var map_node: Node3D

var _score_timer: float = 0.0


func _ready() -> void:
	squad_scene = load("res://scenes/units/Squad.tscn")


func _physics_process(delta: float) -> void:
	if current_phase != MatchPhase.PLAYING:
		return

	_score_timer += delta
	if _score_timer >= SCORE_TICK_INTERVAL:
		_score_timer -= SCORE_TICK_INTERVAL
		_process_score_tick()
		_check_victory_conditions()


func start_match() -> void:
	current_phase = MatchPhase.PLAYING
	team_scores = [0, 0]
	team_tickets = [INITIAL_TICKETS, INITIAL_TICKETS]
	_score_timer = 0.0
	match_started.emit()


func end_match(winning_team: int) -> void:
	current_phase = MatchPhase.POST_MATCH
	match_ended.emit(winning_team)


func register_squad(squad: Node3D) -> void:
	if squad not in all_squads:
		all_squads.append(squad)
		squad_spawned.emit(squad)


func unregister_squad(squad: Node3D) -> void:
	var idx := all_squads.find(squad)
	if idx >= 0:
		all_squads.remove_at(idx)
		squad_destroyed.emit(squad)

		# Apply ticket drain to the squad's team
		var team: int = squad.team
		team_tickets[team] = maxi(0, team_tickets[team] - TICKET_DRAIN_PER_KILL)
		tickets_updated.emit(team, team_tickets[team])


func register_capture_point(point: Node3D) -> void:
	if point not in capture_points:
		capture_points.append(point)


func get_squads_for_team(team: int) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for squad in all_squads:
		if squad.team == team:
			result.append(squad)
	return result


func get_enemy_squads(my_team: int) -> Array[Node3D]:
	var enemy_team := Team.ENEMY if my_team == Team.PLAYER else Team.PLAYER
	return get_squads_for_team(enemy_team)


func get_nearest_enemy(position: Vector3, my_team: int) -> Node3D:
	var enemies := get_enemy_squads(my_team)
	var nearest: Node3D = null
	var nearest_dist := INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist := position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return nearest


func spawn_squad(squad_type: SquadType, team: int, position: Vector3) -> Node3D:
	if not squad_scene:
		push_error("Squad scene not loaded")
		return null

	var squad := squad_scene.instantiate() as Node3D
	squad.squad_type = squad_type
	squad.team = team
	squad.global_position = position

	if map_node:
		map_node.add_child(squad)
	else:
		get_tree().current_scene.add_child(squad)

	register_squad(squad)
	return squad


func get_capture_points_by_owner(team: int) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for point in capture_points:
		if point.owning_team == team:
			result.append(point)
	return result


func get_contested_capture_points() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for point in capture_points:
		if point.is_contested:
			result.append(point)
	return result


func get_neutral_capture_points() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for point in capture_points:
		if point.owning_team == -1:
			result.append(point)
	return result


func _process_score_tick() -> void:
	for team in [Team.PLAYER, Team.ENEMY]:
		var owned_points := get_capture_points_by_owner(team)
		var score_gain := owned_points.size() * SCORE_PER_POINT_PER_TICK
		if score_gain > 0:
			team_scores[team] += score_gain
			score_updated.emit(team, team_scores[team])


func _check_victory_conditions() -> void:
	# Check score victory
	for team in [Team.PLAYER, Team.ENEMY]:
		if team_scores[team] >= VICTORY_SCORE:
			end_match(team)
			return

	# Check ticket depletion
	for team in [Team.PLAYER, Team.ENEMY]:
		if team_tickets[team] <= 0:
			var winner := Team.ENEMY if team == Team.PLAYER else Team.PLAYER
			end_match(winner)
			return


func get_spawn_position_for_team(team: int) -> Vector3:
	var owned := get_capture_points_by_owner(team)
	if owned.size() > 0:
		# Spawn near a random owned point
		var point: Node3D = owned[randi() % owned.size()]
		var offset := Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
		return point.global_position + offset
	else:
		# Fallback spawn positions
		if team == Team.PLAYER:
			return Vector3(-40, 0, 0)
		else:
			return Vector3(40, 0, 0)
