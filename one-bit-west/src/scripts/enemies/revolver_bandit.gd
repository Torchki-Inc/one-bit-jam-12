class_name BanditRevolver
extends BaseEnemy

@export var type: BaseEnemy.Type = BaseEnemy.Type.BANDIT


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
	if dead or not is_inside_tree():
		return

	if sm == null:
		return

	sm.update(delta)

	if dead or not is_inside_tree():
		return

	super._physics_process(delta)

func die() -> void:
	if randf() < 0.5:
		_drop_ammo(1)
	super.die()

func _drop_ammo(amount: int) -> void:
	var pickup = preload("res://src/scenes/weapons/ammo_pickup.tscn").instantiate()
	pickup.amount = amount
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = global_position - Vector3(0, 1, 0)

func make_shot():
	if dead or not is_inside_tree():
			return
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


		elif hit_object.get_parent().has_method("take_damage"):
			hit_object.get_parent().take_damage(self.damage)

	else:
		print(self.get_instance_id(), " misses")

func _draw_ray(from: Vector3, to: Vector3):
	var mesh_instance := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.RED

	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	mesh.surface_add_vertex(from)
	mesh.surface_add_vertex(to)
	mesh.surface_end()

	mesh_instance.mesh = mesh
	get_tree().root.add_child(mesh_instance)

	await get_tree().create_timer(0.05).timeout
	mesh_instance.queue_free()

#region States

class BanditRoamState extends EnemyState:
	var next: EnemyState
	var timer := 0.0
	var roam_target := Vector3.ZERO


	func enter():
		if !enemy.is_inside_tree():
				return
		if enemy.dead:
				return
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
		enemy.make_shot()

		# enemy.anim_state.travel("shoot")
		# spawn bullet here


	func update(_delta) -> EnemyState:
		return next # instant for now, add anim wait later


class BanditWaitState extends EnemyState:
	var next: EnemyState
	var timer := 0.0


	func enter():
		enemy.sprite.texture = enemy.sprites.walk
		timer = randf_range(1.5, 2.0)


	func update(delta) -> EnemyState:
		timer -= delta
		if timer <= 0.0:
			return next # -> RoamState
		return self

#endregion
