class_name BanditRevolver
extends BaseEnemy

var sm: EnemySM
@onready var shoot_point: Marker3D = $ShootPoint



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


func make_shot():
	var space_state := get_world_3d().direct_space_state

	var from := self.shoot_point.global_position
	var direction := (player.global_position - from).normalized()
	var to: Vector3 = from + direction * self.shoot_radius

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]


	var result := space_state.intersect_ray(query)

	if result:
		var hit_object = result["collider"]

		if hit_object.has_method("take_damage"):
			hit_object.take_damage(self.damage)

			print("Revolver hit: ", hit_object.name)

		elif hit_object.get_parent().has_method("take_damage"):
			hit_object.get_parent().take_damage(self.damage)

			print("Revolver hit: ", hit_object.name)
	else:
		print(self.get_instance_id(), " misses")

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
		enemy.make_shot()

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
