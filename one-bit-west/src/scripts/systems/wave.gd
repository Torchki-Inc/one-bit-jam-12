class_name Wave
extends Resource

@export_group("General")
@export var max_alive := 12
@export var cooldown_duration := 5.0

@export_group("Spawning")
@export var bursts: Array[Burst]

@export_group("Enemy Pool")
@export var allowed_enemies: Dictionary[BaseEnemy.Type, bool] = {
	BaseEnemy.Type.DOG: false,
	BaseEnemy.Type.RIDER: false,
	BaseEnemy.Type.BANDIT: false,
	BaseEnemy.Type.SHOTGUN: false,
	BaseEnemy.Type.HAWK: false,
	BaseEnemy.Type.GHOST: false,
}

@export var spawn_weight: Dictionary[BaseEnemy.Type, int] = {
	BaseEnemy.Type.DOG: 3,
	BaseEnemy.Type.RIDER: 2,
	BaseEnemy.Type.BANDIT: 5,
	BaseEnemy.Type.SHOTGUN: 4,
	BaseEnemy.Type.HAWK: 3,
	BaseEnemy.Type.GHOST: 1,
}
