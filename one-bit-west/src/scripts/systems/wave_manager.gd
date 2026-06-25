extends Node

#temporary
var timer := 5

var credits := 0
var current_wave: Wave
@export var waves: Array[Wave] = []


func _ready() -> void:
	current_wave = waves[0]


func _process(delta: float) -> void:
	credits += current_wave.score_regen * delta
	timer -= delta
	if timer <= 0:
		print("curret credits: ", credits)
		_on_spawn_tick()
		timer = 5


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
		pass #spawn_enemy(current_wave.enemy_cost[type])
	else:
		print("Not enough credits")


func spawn_enemy():
	print("Enemy {} spawned: ")

	pass


# do i need it?
func set_wave(next: int):
	if next != waves.size() - 1:
		current_wave = waves[next]
	else:
		pass
