class_name Wave
extends Resource

@export var spawn_rate: float
@export var wave_duration: float
@export var score_regen: float
@export var allowed_enemies: Dictionary[BaseEnemy.Type, bool] = {
	BaseEnemy.Type.DOG: false,
	BaseEnemy.Type.RIDER: false,
	BaseEnemy.Type.BANDIT: false,
	BaseEnemy.Type.SHOTGUN: false,
	BaseEnemy.Type.HAWK: false,
	BaseEnemy.Type.GHOST: false,
}

@export var enemy_cost: Dictionary[BaseEnemy.Type, int] = {
	BaseEnemy.Type.DOG: 3,
	BaseEnemy.Type.RIDER: 2,
	BaseEnemy.Type.BANDIT: 5,
	BaseEnemy.Type.SHOTGUN: 4,
	BaseEnemy.Type.HAWK: 3,
	BaseEnemy.Type.GHOST: 1,
}
