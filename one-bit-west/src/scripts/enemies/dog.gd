class_name Dog
extends BaseEnemy

@export var type: BaseEnemy.Type = BaseEnemy.Type.DOG

var sm: EnemySM
@export var JUMP_HEIGHT := 4.0
@export var JUMP_SPEED := 6.0


func _ready():
	super._ready()
	sm = EnemySM.new()

	var roam = DogRoamState.new()
	var jump = DogJumpState.new()

	roam.enemy = self
	roam.next = jump
	jump.enemy = self
	jump.next = roam

	sm.current = roam
	sm.enter()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	sm.update(delta)


class DogRoamState extends EnemyState:
	var next: EnemyState
	var timer := 0.0
	var roam_target := Vector3.ZERO


	func enter():
		_pick_new_target()


	func update(delta) -> EnemyState:
		timer -= delta
		if timer <= 0.0:
			_pick_new_target()

		enemy.move_toward_target(roam_target, delta)

		if enemy.global_position.distance_to(enemy.player.global_position) < enemy.shoot_radius:
			return next
		return self


	func _pick_new_target():
		# var offset = Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
		roam_target = enemy.player.global_position # + offset
		timer = randf_range(2.0, 4.0)


class DogJumpState extends EnemyState:
	var next: EnemyState
	var timer := 0.0
	var jump_duration := 1.0


	func enter():
		timer = jump_duration
		_launch()


	func _launch():
		var direction = (enemy.player.global_position - enemy.global_position).normalized()
		enemy.velocity = Vector3(direction.x * enemy.JUMP_SPEED, enemy.JUMP_HEIGHT, direction.z * enemy.JUMP_SPEED)


	func update(delta) -> EnemyState:
		if enemy.is_on_floor() and timer < jump_duration - 0.1:
			enemy.velocity.x = 0
			enemy.velocity.z = 0
			return next
		timer -= delta
		return self
