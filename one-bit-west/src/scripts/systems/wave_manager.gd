extends Node

enum State {
	IDLE,
	WAVE_ACTIVE,
	WAVE_COOLDOWN,
}

var state: State = State.IDLE

var current_wave_index := 0
var current_wave: Wave

var wave_time := 0.0
var next_burst := 0

var spawn_points: Array[Marker3D] = []

@export var waves: Array[Wave] = []

@onready var timer: Timer = Timer.new()
@onready var spawn_point_root = $"../../World/LevelRoot/Level0/SpawnPoints"
@onready var entity_root = $"../../World/EntityRoot"

const ENEMY_SCENES = {
	BaseEnemy.Type.DOG: preload("res://src/scenes/enemies/dog.tscn"),
	BaseEnemy.Type.BANDIT: preload("res://src/scenes/enemies/revolver_bandit.tscn"),
	BaseEnemy.Type.RIDER: preload("res://src/scenes/enemies/rider.tscn"),
	BaseEnemy.Type.SHOTGUN: preload("res://src/scenes/enemies/shotgun_bandit.tscn"),
	BaseEnemy.Type.HAWK: preload("res://src/scenes/enemies/hawk.tscn"),
	BaseEnemy.Type.GHOST: preload("res://src/scenes/enemies/ghost.tscn"),
}

# --------------------
# Lifecycle
# --------------------


func _ready() -> void:
	add_child(timer)
	timer.timeout.connect(_on_wave_finished)

	if waves.is_empty():
		push_error("WaveManager: no waves assigned")
		return

	take_available_spawnpoints()
	start_wave(0)

# --------------------
# State entry
# --------------------


func start_wave(index: int) -> void:
	current_wave_index = index
	current_wave = waves[current_wave_index]

	wave_time = 0.0
	next_burst = 0

	state = State.WAVE_ACTIVE

	timer.start(current_wave.wave_duration)


func start_cooldown() -> void:
	state = State.WAVE_COOLDOWN
	timer.start(current_wave.cooldown_duration)

# --------------------
# Wave flow
# --------------------


func _on_wave_finished() -> void:
	if current_wave_index + 1 >= waves.size():
		state = State.IDLE
		print("All waves completed")
		get_tree().change_scene_to_file("res://src/scenes/ui/main_menu.tscn")

	if state == State.WAVE_ACTIVE:
		start_cooldown()
	elif state == State.WAVE_COOLDOWN:
		start_wave(current_wave_index + 1)

# --------------------
# Burst system (deterministic tick)
# --------------------


func _process(delta: float) -> void:
	if state != State.WAVE_ACTIVE:
		return

	wave_time += delta

	while next_burst < current_wave.bursts.size():
		var burst = current_wave.bursts[next_burst]

		if wave_time < burst.time:
			break

		spawn_burst(burst)
		next_burst += 1

# --------------------
# Spawning
# --------------------


func spawn_burst(burst: Burst) -> void:
	var budget := burst.budget

	while budget > 0:
		if get_alive_enemy_count() >= current_wave.max_alive:
			return

		var enemy_type := pick_enemy_to_spawn(budget)
		if enemy_type == BaseEnemy.Type.NONE:
			return

		spawn_enemy(enemy_type)
		budget -= get_enemy_cost(enemy_type)


func spawn_enemy(type: BaseEnemy.Type) -> void:
	var scene: PackedScene = ENEMY_SCENES.get(type, null)
	if scene == null:
		push_error("Missing scene for type: %s" % type)
		return

	if spawn_points.is_empty():
		push_error("No spawn points available")
		return

	var marker = spawn_points[randi() % spawn_points.size()]
	var pos = find_valid_spawn(marker)

	var enemy = scene.instantiate()
	entity_root.add_child(enemy)
	enemy.global_position = pos

# --------------------
# Enemy selection
# --------------------


func pick_enemy_to_spawn(remaining_budget: int) -> BaseEnemy.Type:
	var allowed := current_wave.allowed_enemies.keys().filter(
		func(type):
			return current_wave.allowed_enemies.get(type, false) and get_enemy_cost(type) <= remaining_budget
	)

	if allowed.is_empty():
		return BaseEnemy.Type.NONE

	var total_weight := 0
	for t in allowed:
		total_weight += current_wave.spawn_weight.get(t, 1)

	var roll := randi() % total_weight
	var cumulative := 0

	for t in allowed:
		cumulative += current_wave.spawn_weight.get(t, 1)
		if roll < cumulative:
			return t

	return allowed[0]


func get_enemy_cost(type: BaseEnemy.Type) -> int:
	match type:
		BaseEnemy.Type.DOG:
			return 1
		BaseEnemy.Type.BANDIT:
			return 2
		BaseEnemy.Type.RIDER:
			return 4
		BaseEnemy.Type.SHOTGUN:
			return 5
		BaseEnemy.Type.HAWK:
			return 3
		BaseEnemy.Type.GHOST:
			return 8
		_:
			return 999

# --------------------
# Utility
# --------------------


func get_alive_enemy_count() -> int:
	return get_tree().get_nodes_in_group("enemy").size()


func take_available_spawnpoints() -> void:
	for child in spawn_point_root.get_children():
		if child is Marker3D and child.name != "PlayerSpawn":
			spawn_points.append(child)


func find_valid_spawn(marker: Marker3D) -> Vector3:
	var space = get_viewport().get_world_3d().direct_space_state

	var shape = SphereShape3D.new()
	shape.radius = 0.5

	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.collision_mask = 1

	for i in 5:
		var offset = Vector3(randf_range(-3, 3), 0.5, randf_range(-3, 3))
		params.transform.origin = marker.global_position + offset

		if space.intersect_shape(params, 1).is_empty():
			return marker.global_position + offset

	return marker.global_position
