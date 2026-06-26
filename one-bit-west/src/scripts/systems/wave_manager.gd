extends Node

var spawn_timer := 0
var wave_started := false
var current_wave_index := 0
var credits := 0
var current_wave: Wave
var spawn_points: Array[Marker3D] = []
@export var waves: Array[Wave] = []

@onready var timer = Timer.new()
@onready var spawn_point_root = $"../../World/LevelRoot/Level0/SpawnPoints"
@onready var entity_root = $"../../World/EntityRoot"


func _ready() -> void:
	add_child(timer)

	timer.timeout.connect(_on_timer_timeout)

	if waves.is_empty():
		push_error("WaveManager: no waves assigned!")
		return
	current_wave = waves[current_wave_index]
	take_aviable_spawnpoints()


func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0 && wave_started:
		_on_spawn_tick()
		spawn_timer = randf_range(current_wave.spawn_rate * 0.75, current_wave.spawn_rate * 1.25)

	if Input.is_action_pressed("debug_wave_start"):
		timer.start(current_wave.wave_duration)
		wave_started = true


# choose random enemies based on rarity
func pick_enemy_to_spawn() -> BaseEnemy.Type:
	var allowed = current_wave.allowed_enemies.keys().filter(
		func(t): return current_wave.allowed_enemies[t]
	)

	if allowed.is_empty():
		push_error("WaveManager: no enemies enabled in current wave!")
		return BaseEnemy.Type.DOG # fallback

	var total_weight := 0
	for type in allowed:
		total_weight += current_wave.enemy_weight[type]

	var roll := randi() % total_weight
	var cumulative := 0
	for type in allowed:
		cumulative += current_wave.enemy_weight[type]
		if roll < cumulative:
			return type

	return allowed[0]


func _on_spawn_tick():
	var type = pick_enemy_to_spawn()
	spawn_enemy(type)



func spawn_enemy(type: BaseEnemy.Type) -> void:
	if spawn_points.is_empty():
		push_error("WaveManaget: No spawnpoints aviable!")
		return

	var marker: Marker3D = spawn_points[randi() % spawn_points.size()]

	var spawn_pos := find_valid_spawn(marker)

	var scene: PackedScene
	match type:
		BaseEnemy.Type.DOG:
			scene = preload("res://src/scenes/enemies/dog.tscn")
		BaseEnemy.Type.BANDIT:
			scene = preload("res://src/scenes/enemies/revolver_bandit.tscn")
		BaseEnemy.Type.RIDER:
			scene = preload("res://src/scenes/enemies/rider.tscn")
		BaseEnemy.Type.SHOTGUN:
			scene = preload("res://src/scenes/enemies/shotgun_bandit.tscn")
		BaseEnemy.Type.HAWK:
			pass
		# scene = preload("res://src/scenes/enemies/hawk.tscn")
		BaseEnemy.Type.GHOST:
			pass
		# scene = preload("res://src/scenes/enemies/ghost.tscn")
	print("Enemy {} spawned: ")

	var enemy = scene.instantiate()
	entity_root.add_child(enemy)
	enemy.global_position = spawn_pos


# Set up next wave
func next_wave():
	if current_wave_index + 1 != waves.size():
		current_wave_index += 1
		current_wave = waves[current_wave_index]

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

	for i in 5: # максимум 5 попыток
		var offset = Vector3(randf_range(-3, 3), 0.5, randf_range(-3, 3))
		params.transform.origin = marker.global_position + offset
		var result = space.intersect_shape(params, 1)
		if result.is_empty():
			return marker.global_position + offset

	return marker.global_position # fallback на центр маркера
