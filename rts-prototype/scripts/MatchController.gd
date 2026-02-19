extends Node
## MatchController.gd - Orchestrates match setup and lifecycle
## Connects all systems and handles initial spawns.

@export var camera: Camera3D
@export var selection_manager: SelectionManager
@export var hud: HUD
@export var ai_commander: AICommander
@export var battle_map: Node3D

const INITIAL_SQUADS_PER_TEAM: int = 2


func _ready() -> void:
	# Wait one frame for autoloads to initialize
	await get_tree().process_frame

	_setup_references()
	_spawn_initial_squads()
	_start_match()


func _setup_references() -> void:
	# Find components if not set via export
	if not camera:
		camera = get_node_or_null("../RTSCamera")
	if not selection_manager:
		selection_manager = get_node_or_null("../SelectionManager")
	if not hud:
		hud = get_node_or_null("../HUD")
	if not ai_commander:
		ai_commander = get_node_or_null("../AICommander")
	if not battle_map:
		battle_map = get_node_or_null("../BattleMap")

	# Connect selection manager to camera
	if selection_manager and camera:
		selection_manager.camera = camera

	# Connect HUD to selection manager
	if hud and selection_manager:
		hud.selection_manager = selection_manager

	# Set map reference in GameState
	if battle_map:
		GameState.map_node = battle_map


func _spawn_initial_squads() -> void:
	# Spawn player squads
	var player_spawn_base := Vector3(-40, 0, 0)
	for i in INITIAL_SQUADS_PER_TEAM:
		var offset := Vector3(0, 0, (i - 0.5) * 8)
		var squad_type: int
		if i == 0:
			squad_type = GameState.SquadType.INFANTRY
		else:
			squad_type = GameState.SquadType.SUPPORT

		GameState.spawn_squad(squad_type, GameState.Team.PLAYER, player_spawn_base + offset)

	# Spawn enemy squads
	var enemy_spawn_base := Vector3(40, 0, 0)
	for i in INITIAL_SQUADS_PER_TEAM:
		var offset := Vector3(0, 0, (i - 0.5) * 8)
		var squad_type: int
		if i == 0:
			squad_type = GameState.SquadType.INFANTRY
		else:
			squad_type = GameState.SquadType.VEHICLE

		GameState.spawn_squad(squad_type, GameState.Team.ENEMY, enemy_spawn_base + offset)


func _start_match() -> void:
	GameState.start_match()
	print("Match started!")


func _input(event: InputEvent) -> void:
	# Debug restart
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F5:
			get_tree().reload_current_scene()
