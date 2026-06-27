extends Node

var wave_time := 0.0
var next_burst := 0
var wave_started := false
var current_wave_index := 0
var current_wave: Wave
var spawn_points: Array[Marker3D] = []
@export var waves: Array[Wave] = []

@onready var timer = Timer.new()
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


func _ready() -> void:
	add_child(timer)

	timer.timeout.connect(_on_timer_timeout)

	if waves.is_empty():
		push_error("WaveManager: no waves assigned!")
		return
	current_wave = waves[current_wave_index]
	take_aviable_spawnpoints()


func _process(delta):
	if Input.is_action_pressed("debug_wave_start"):
		timer.start(current_wave.wave_duration)
		wave_started = true
	if !wave_started:
		return

	wave_time += delta

	if next_burst < current_wave.bursts.size():
		var burst = current_wave.bursts[next_burst]

		if wave_time >= burst.time:
			spawn_burst(burst)
			next_burst += 1


func pick_enemy_to_spawn(remaining_budget: int) -> BaseEnemy.Type:
	var allowed = current_wave.allowed_enemies.keys().filter(
		func(type):
			return current_wave.allowed_enemies[type] \
					and get_enemy_cost(type) <= remaining_budget
	)

	if allowed.is_empty():
		return BaseEnemy.Type.DOG # or whatever fallback you prefer

	var total_weight := 0
	for type in allowed:
		total_weight += current_wave.spawn_weight[type]

	var roll := randi() % total_weight
	var cumulative := 0

	for type in allowed:
		cumulative += current_wave.spawn_weight[type]
		if roll < cumulative:
			return type

	return allowed[0]


func spawn_burst(burst: Burst):
	var budget = burst.budget

	while budget > 0:
		if get_alive_enemy_count() >= current_wave.max_alive:
			break
		var enemy = pick_enemy_to_spawn(budget)

		if enemy == BaseEnemy.Type.NONE:
			break

		spawn_enemy(enemy)

		budget -= get_enemy_cost(enemy)


func get_enemy_cost(type: BaseEnemy.Type):
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


func get_alive_enemy_count():
	return get_tree().get_nodes_in_group("enemy").size()


func spawn_enemy(type: BaseEnemy.Type) -> void:
	if spawn_points.is_empty():
		push_error("WaveManaget: No spawnpoints aviable!")
		return

	var marker: Marker3D = spawn_points[randi() % spawn_points.size()]

	var spawn_pos := find_valid_spawn(marker)

	var scene: PackedScene = ENEMY_SCENES.get(type, null)
	if scene == null:
		push_error("No scene for enemy type: %s" % type)
		return
	print("Enemy spawned: %s" % type)

	var enemy = scene.instantiate()
	entity_root.add_child(enemy)
	enemy.global_position = spawn_pos


# Set up next wave
func next_wave():
	if current_wave_index + 1 < waves.size():
		current_wave_index += 1
		current_wave = waves[current_wave_index]
		wave_time = 0
		next_burst = 0
		wave_started = true
		timer.start(current_wave.wave_duration)

	else:
		print("No more waves")


func _on_timer_timeout():
	print("Wave ended")
	next_wave()


func take_aviable_spawnpoints():
	for child in spawn_point_root.get_children():
		if child is Marker3D && child.name != "PlayerSpawn":
			spawn_points.append(child)


func find_valid_spawn(marker: Marker3D) -> Vector3:
	var space = get_viewport().get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = 0.5 # под размер капсулы врага

	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.collision_mask = 1 # слой геометрии

	for i in 5: # максимум 5 попыток1
		var offset = Vector3(randf_range(-3, 3), 0.5, randf_range(-3, 3))
		params.transform.origin = marker.global_position + offset
		var result = space.intersect_shape(params, 1)
		if result.is_empty():
			return marker.global_position + offset

	return marker.global_position # fallback на центр маркера
