class_name BanditShotgun
extends BaseEnemy

@export var type: BaseEnemy.Type = BaseEnemy.Type.SHOTGUN

var sm: EnemySM
@onready var shoot_point: Marker3D = $ShootPoint
@export var shotgun_spread := 8.0
@export var shotgun_pellets := 8


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

func die() -> void:
	if randf() < 0.75:
		_drop_ammo(1)
	super.die()

func _physics_process(delta: float) -> void:
	if dead or not is_inside_tree():
		return

	if sm == null:
		return

	sm.update(delta)

	if dead or not is_inside_tree():
		return

	super._physics_process(delta)

func _drop_ammo(amount: int) -> void:
	var pickup = preload("res://src/scenes/weapons/ammo_pickup.tscn").instantiate()
	pickup.amount = amount
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = global_position - Vector3(0, 1, 0)

func make_shot():
	if dead or not is_inside_tree():
		return
	var space_state := get_world_3d().direct_space_state
	var from := shoot_point.global_position

	var player_vel := Vector3.ZERO
	if player is CharacterBody3D:
		player_vel = player.velocity
	var dist := from.distance_to(player.global_position)
	var travel_time := dist / 200.0
	var predicted_pos := player.global_position + player_vel * travel_time
	var aim_error := Vector3(
		randf_range(-0.8, 0.8),
		randf_range(-0.2, 0.2),
		randf_range(-0.8, 0.8)
	)
	var direction := (predicted_pos + aim_error - from).normalized()

	for i in shotgun_pellets:
		if dead or not is_inside_tree():
			return

		# Спред применяется к direction, ПОТОМ считается to
		var spread_x := deg_to_rad(randf_range(-shotgun_spread, shotgun_spread))
		var spread_y := deg_to_rad(randf_range(-shotgun_spread, shotgun_spread))
		var spread_dir := direction.rotated(shoot_point.global_transform.basis.x, spread_y)
		spread_dir = spread_dir.rotated(shoot_point.global_transform.basis.y, spread_x)
		spread_dir = spread_dir.normalized()

		var to := from + spread_dir * shoot_radius

		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [self]
		var result := space_state.intersect_ray(query)

		if result:
			var hit_object = result["collider"]
			if hit_object.has_method("take_damage"):
				hit_object.take_damage(damage)
			elif hit_object.get_parent().has_method("take_damage"):
				hit_object.get_parent().take_damage(damage)


#region States

class BanditRoamState extends EnemyState:
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
		enemy.sprite.texture = enemy.sprites.attack

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
		if !enemy.is_inside_tree():
				return
		if enemy.dead:
				return
		enemy.make_shot()

		pass
		# enemy.anim_state.travel("shoot")
		# spawn bullet here


	func update(_delta) -> EnemyState:
		return next # instant for now, add anim wait later


class BanditWaitState extends EnemyState:
	var next: EnemyState
	var timer := 0.0


	func enter():
		enemy.sprite.texture = enemy.sprites.walk
		timer = randf_range(0.8, 1.5)


	func update(delta) -> EnemyState:
		timer -= delta
		if timer <= 0.0:
			return next # -> RoamState
		return self

#endregion
