extends Node

var current_wave_index := 0
var credits := 0
var timer: Timer
var current_wave: Wave
@export var waves: Array[Wave] = []


func _ready() -> void:
	timer = Timer.new()
	add_child(timer)

	timer.timeout.connect(_on_timer_timeout)

	if waves.is_empty():
		push_error("WaveManager: no waves assigned!")
		return
	current_wave = waves[current_wave_index]


func _process(delta: float) -> void:
	credits += current_wave.score_regen * delta

	if Input.is_action_pressed("move_up"):
		timer.start(current_wave.wave_duration)


# choose random enemies based on rarity
func pick_enemy_to_spawn() -> BaseEnemy.Type:
	var allowed = current_wave.allowed_enemies

	var total_weight := 0
	for type in allowed:
		total_weight += current_wave.enemy_cost[type]

	var roll := randi() % total_weight

	var cumulative := 0
	for type in allowed:
		cumulative += current_wave.enemy_cost[type]
		if roll < cumulative:
			return type

	return allowed[0]


func _on_spawn_tick():
	var type = pick_enemy_to_spawn()
	if credits > current_wave.enemy_cost[type]:
		#spawn_enemy(type)
		pass
	else:
		print("Not enough credits")


func spawn_enemy():
	print("Enemy {} spawned: ")

	pass


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
