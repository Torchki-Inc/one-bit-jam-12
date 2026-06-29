extends Node

const DEATH_SCREEN := preload("res://src/scenes/ui/death_screen.tscn")

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
	AudioManager.play_music(AudioManager.BASE_LOOP)

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

	player.died.connect(_on_player_died)

	var spawn := get_player_spawn()

	if spawn:
		player.global_position = spawn.global_position
		player.global_rotation = spawn.global_rotation
	else:
		player.global_position = Vector3(0, 1, 0)

	player.hud = hud
	player.setup_hud()

func get_player_spawn() -> Marker3D:
	if current_level == null:
		return null

	var spawn := current_level.get_node_or_null("SpawnPoints/PlayerSpawn")

	if spawn and spawn is Marker3D:

		print(spawn.global_position)
		return spawn


	return null

func initialise_manager() -> void:
	if game_manager == null:
		push_error("No game_manager assigned in Main.gd")
		return

	var manager := game_manager.instantiate()
	systems.add_child(manager)

func _on_player_died() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_packed(DEATH_SCREEN)
