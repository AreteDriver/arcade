extends Node
## Economy.gd - Supply generation and spending system
## Manages team resources for reinforcement drops.

signal supply_changed(team: int, amount: int)
signal reinforcement_requested(team: int, squad_type: int, position: Vector3)
signal reinforcement_ready(team: int)

const SUPPLY_PER_POINT_PER_TICK: int = 10
const SUPPLY_TICK_INTERVAL: float = 1.0
const BASE_SUPPLY: int = 100

# Reinforcement costs
const COST_INFANTRY: int = 50
const COST_SUPPORT: int = 60
const COST_VEHICLE: int = 100

# Reinforcement cooldowns (seconds)
const COOLDOWN_INFANTRY: float = 5.0
const COOLDOWN_SUPPORT: float = 7.0
const COOLDOWN_VEHICLE: float = 12.0

var team_supply: Array[int] = [BASE_SUPPLY, BASE_SUPPLY]
var team_cooldowns: Array[float] = [0.0, 0.0]

var _supply_timer: float = 0.0


func _ready() -> void:
	# Connect to GameState signals if available
	if GameState:
		GameState.match_started.connect(_on_match_started)


func _physics_process(delta: float) -> void:
	if GameState.current_phase != GameState.MatchPhase.PLAYING:
		return

	# Update supply tick
	_supply_timer += delta
	if _supply_timer >= SUPPLY_TICK_INTERVAL:
		_supply_timer -= SUPPLY_TICK_INTERVAL
		_process_supply_tick()

	# Update cooldowns
	for team in [GameState.Team.PLAYER, GameState.Team.ENEMY]:
		if team_cooldowns[team] > 0:
			team_cooldowns[team] = maxf(0.0, team_cooldowns[team] - delta)
			if team_cooldowns[team] == 0.0:
				reinforcement_ready.emit(team)


func _on_match_started() -> void:
	team_supply = [BASE_SUPPLY, BASE_SUPPLY]
	team_cooldowns = [0.0, 0.0]
	_supply_timer = 0.0


func _process_supply_tick() -> void:
	for team in [GameState.Team.PLAYER, GameState.Team.ENEMY]:
		var owned_points := GameState.get_capture_points_by_owner(team)
		var supply_gain := owned_points.size() * SUPPLY_PER_POINT_PER_TICK
		if supply_gain > 0:
			add_supply(team, supply_gain)


func add_supply(team: int, amount: int) -> void:
	team_supply[team] += amount
	supply_changed.emit(team, team_supply[team])


func get_supply(team: int) -> int:
	return team_supply[team]


func get_cooldown(team: int) -> float:
	return team_cooldowns[team]


func can_afford(team: int, squad_type: int) -> bool:
	var cost := get_cost(squad_type)
	return team_supply[team] >= cost


func is_off_cooldown(team: int) -> bool:
	return team_cooldowns[team] <= 0.0


func can_reinforce(team: int, squad_type: int) -> bool:
	return can_afford(team, squad_type) and is_off_cooldown(team)


func get_cost(squad_type: int) -> int:
	match squad_type:
		GameState.SquadType.INFANTRY:
			return COST_INFANTRY
		GameState.SquadType.SUPPORT:
			return COST_SUPPORT
		GameState.SquadType.VEHICLE:
			return COST_VEHICLE
	return 999999


func get_cooldown_duration(squad_type: int) -> float:
	match squad_type:
		GameState.SquadType.INFANTRY:
			return COOLDOWN_INFANTRY
		GameState.SquadType.SUPPORT:
			return COOLDOWN_SUPPORT
		GameState.SquadType.VEHICLE:
			return COOLDOWN_VEHICLE
	return 999.0


func request_reinforcement(team: int, squad_type: int, position: Vector3) -> bool:
	if not can_reinforce(team, squad_type):
		return false

	var cost := get_cost(squad_type)
	var cooldown := get_cooldown_duration(squad_type)

	team_supply[team] -= cost
	team_cooldowns[team] = cooldown

	supply_changed.emit(team, team_supply[team])
	reinforcement_requested.emit(team, squad_type, position)

	# Actually spawn the squad
	GameState.spawn_squad(squad_type, team, position)

	return true


func get_affordable_squad_types(team: int) -> Array[int]:
	var result: Array[int] = []
	for squad_type in [GameState.SquadType.INFANTRY, GameState.SquadType.SUPPORT, GameState.SquadType.VEHICLE]:
		if can_afford(team, squad_type):
			result.append(squad_type)
	return result
