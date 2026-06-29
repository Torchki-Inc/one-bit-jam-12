extends Node

@export var level_scene: PackedScene
@export var player_scene: PackedScene
@export var game_manager: PackedScene

@onready var level_root: Node3D = $World/LevelRoot
@onready var entity_root: Node3D = $World/EntityRoot
@onready var hud: Control = $HudLayout/Hud
@onready var systems: Node = $Systems
@onready var nav_region: Node3D = $World/LevelRoot

var current_level: Node3D
var player: CharacterBody3D


func _ready() -> void:
	load_level()
	spawn_player()
	initialise_manager()

func load_level() -> void:
	if level_scene == null:
		push_error("No level_scene assigned in Main.gd")
		return

	current_level = level_scene.instantiate()
	level_root.add_child(current_level)

	# print_debug("Baking navigation mesh...")
	# nav_region.bake_navigation_mesh()
	# await nav_region.bake_finished
	# print_debug("Navigation mesh baked.")

func spawn_player() -> void:
	if player_scene == null:
		push_error("No player_scene assigned in Main.gd")
		return

	player = player_scene.instantiate()
	entity_root.add_child(player)

	var spawn := get_player_spawn()

	if spawn:
		player.global_position = spawn.global_position
		player.global_rotation = spawn.global_rotation
	else:
		player.global_position = Vector3(0, 1, 0)

	player.hud = hud
	player.setup_hud()

func get_player_spawn() -> Marker3D:
	var spawn := $World/LevelRoot.get_node_or_null("SpawnPoints/PlayerSpawn")

	if spawn and spawn is Marker3D:
		return spawn

	return null

func initialise_manager() -> void:
	if game_manager == null:
		push_error("No game_manager assigned in Main.gd")
		return

	var manager := game_manager.instantiate()
	systems.add_child(manager)
