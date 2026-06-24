class_name BanditRevolver
extends BaseEnemy

var sm: EnemySM
@export var revolver_damage := 2


func _ready():
	super._ready()
	sm = EnemySM.new()

	var roam = BanditRoamState.new()
	var prepare = BanditPrepareState.new()
	var shoot = BanditShootState.new()
	var wait = BanditWaitState.new()

	roam.enemy = self
	roam.next = prepare
	prepare.enemy = self
	prepare.next = shoot
	shoot.enemy = self
	shoot.next = wait
	wait.enemy = self
	wait.next = roam

	sm.current = roam
	sm.enter()


func _physics_process(delta: float) -> void:
	sm.update(delta)


func shoot():
	pass

#region States

class BanditRoamState extends EnemyState:
	var next: EnemyState
	var timer := 0.0
	var roam_target := Vector3.ZERO


	func enter():
		print("Enter Roam state")

		_pick_new_target()


	func update(delta) -> EnemyState:
		timer -= delta
		if timer <= 0.0:
			_pick_new_target()

		enemy.move_toward_target(roam_target, delta)

		if enemy.global_position.distance_to(enemy.player.global_position) < enemy.shoot_radius:
			print("in shooting position")
			return next # -> PrepareState
		return self


	func _pick_new_target():
		var offset = Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
		roam_target = enemy.player.global_position + offset
		timer = randf_range(2.0, 4.0)


class BanditPrepareState extends EnemyState:
	var next: EnemyState
	var timer := 0.0


	func enter():
		timer = 0.8
		# enemy.anim_state.travel("prepare") 


	func update(delta) -> EnemyState:
		timer -= delta
		if timer <= 0.0:
			return next # -> ShootState
		return self


class BanditShootState extends EnemyState:
	var next: EnemyState


	func enter():
		print("Enter Soot state")
		enemy.shoot()

		pass
		# enemy.anim_state.travel("shoot")
		# spawn bullet here


	func update(delta) -> EnemyState:
		return next # instant for now, add anim wait later


class BanditWaitState extends EnemyState:
	var next: EnemyState
	var timer := 0.0


	func enter():
		print("Enter Wait state")
		timer = randf_range(0.8, 1.5)


	func update(delta) -> EnemyState:
		timer -= delta
		if timer <= 0.0:
			return next # -> RoamState
		return self

#endregion
