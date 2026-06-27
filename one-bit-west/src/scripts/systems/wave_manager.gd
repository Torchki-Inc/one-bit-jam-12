class_name WaveManager
extends Node

enum State { IDLE, WAVE_ACTIVE, WAVE_COOLDOWN }

var state: State = State.IDLE
var current_wave_index := 0
var current_wave: Wave
var wave_time := 0.0
var next_burst := 0
var spawning_finished := false
var boss_fight := false

var spawn_points: Array[Marker3D] = []

@export var waves: Array[Wave] = []

@onready var timer: Timer = Timer.new()
@onready var spawn_point_root = $"../../World/LevelRoot/Level0/SpawnPoints"
@onready var entity_root = $"../../World/EntityRoot"

const ENEMY_SCENES = {
	BaseEnemy.Type.DOG:    preload("res://src/scenes/enemies/dog.tscn"),
	BaseEnemy.Type.BANDIT: preload("res://src/scenes/enemies/revolver_bandit.tscn"),
	BaseEnemy.Type.RIDER:  preload("res://src/scenes/enemies/rider.tscn"),
	BaseEnemy.Type.SHOTGUN:preload("res://src/scenes/enemies/shotgun_bandit.tscn"),
	BaseEnemy.Type.HAWK:   preload("res://src/scenes/enemies/hawk.tscn"),
	BaseEnemy.Type.GHOST:  preload("res://src/scenes/enemies/ghost.tscn"),
}
const SHAMAN = preload("res://src/scenes/enemies/shaman/shaman.tscn")

# --------------------
# Lifecycle
# --------------------

func _ready() -> void:
	add_child(timer)
	timer.timeout.connect(_on_cooldown_finished)

	if waves.is_empty():
		push_error("WaveManager: no waves assigned")
		return

	take_available_spawnpoints()
	start_wave(0)

# --------------------
# Wave flow
# --------------------

func start_wave(index: int) -> void:
	current_wave_index = index
	current_wave = waves[index]
	wave_time = 0.0
	next_burst = 0
	spawning_finished = false
	state = State.WAVE_ACTIVE

func start_cooldown() -> void:
	state = State.WAVE_COOLDOWN
	timer.start(current_wave.cooldown_duration)

func _on_cooldown_finished() -> void:
	if current_wave_index + 1 < waves.size():
		start_wave(current_wave_index + 1)

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

	if not spawning_finished and next_burst >= current_wave.bursts.size():
		spawning_finished = true

	if spawning_finished and get_alive_enemy_count() == 0 and not boss_fight:
		if current_wave_index + 1 >= waves.size():
			boss_fight = true
			state = State.IDLE
			_start_boss_sequence()
		else:
			start_cooldown()

func _start_boss_sequence() -> void:
	# ждём пока враги из последнего burst реально заспавнятся
	await get_tree().process_frame
	await get_tree().process_frame
	while get_alive_enemy_count() > 0:
		await get_tree().process_frame
	await get_tree().create_timer(3.0).timeout
	spawn_boss(SHAMAN)

# --------------------
# Spawning
# --------------------

func spawn_burst(burst: Burst) -> void:
	var budget := burst.budget
	var delay := 0.0

	while budget > 0:
		if get_alive_enemy_count() >= current_wave.max_alive:
			return

		var enemy_type := pick_enemy_to_spawn(budget)
		if enemy_type == BaseEnemy.Type.NONE:
			return

		get_tree().create_timer(delay).timeout.connect(
			func(): spawn_enemy(enemy_type)
		)

		budget -= get_enemy_cost(enemy_type)
		delay += 0.3

func spawn_boss(boss_scene: PackedScene) -> void:
	if boss_scene == null or spawn_points.is_empty():
		push_error("spawn_boss: missing scene or spawn points")
		return

	var pos := find_valid_spawn(spawn_points[0])
	var boss := boss_scene.instantiate()
	entity_root.add_child(boss)
	boss.global_position = pos
	boss.start()

func spawn_enemy(type: BaseEnemy.Type) -> void:
	var scene: PackedScene = ENEMY_SCENES.get(type)
	if scene == null:
		push_error("WaveManager: missing scene for type %s" % type)
		return
	if spawn_points.is_empty():
		push_error("WaveManager: no spawn points")
		return

	var marker := spawn_points[randi() % spawn_points.size()]
	var enemy := scene.instantiate()
	entity_root.add_child(enemy)
	enemy.global_position = find_valid_spawn(marker)

# --------------------
# Enemy selection
# --------------------

func pick_enemy_to_spawn(remaining_budget: int) -> BaseEnemy.Type:
	var allowed := current_wave.allowed_enemies.keys().filter(
		func(type):
			return current_wave.allowed_enemies.get(type, false) \
				and get_enemy_cost(type) <= remaining_budget
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
		BaseEnemy.Type.DOG:     return 1
		BaseEnemy.Type.BANDIT:  return 2
		BaseEnemy.Type.RIDER:   return 4
		BaseEnemy.Type.SHOTGUN: return 3
		BaseEnemy.Type.HAWK:    return 2
		BaseEnemy.Type.GHOST:   return 6
		_:                      return 999

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
	var space := get_viewport().get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = 0.5
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.collision_mask = 1

	for i in 5:
		var offset := Vector3(randf_range(-3, 3), 0.5, randf_range(-3, 3))
		params.transform.origin = marker.global_position + offset
		if space.intersect_shape(params, 1).is_empty():
			return marker.global_position + offset

	return marker.global_position
