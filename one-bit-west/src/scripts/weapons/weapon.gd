extends Sprite3D

enum WeaponType {
	REVOLVER,
	SHOTGUN
}

@export var type := WeaponType.REVOLVER

# Revolver stats
@export var revolver_damage := 2
@export var revolver_range := 30.0
@export var revolver_fire_rate := 0.35
@export var max_revolver_ammo := 6
@export var current_revolver_ammo := 6
@export var reserve_revolver_ammo := 24
@export var revolver_reload_time := 1.2

# Shotgun stats
@export var shotgun_damage := 1
@export var shotgun_range := 15.0
@export var shotgun_fire_rate := 0.9
@export var shotgun_pellets := 8
@export var shotgun_spread := 8.0
@export var max_shotgun_ammo := 2
@export var current_shotgun_ammo := 2
@export var reserve_shotgun_ammo := 12
@export var shotgun_reload_time := 2.0

var can_shoot := true
var is_reloading := false

func shoot(camera:Camera3D):
	if is_reloading:
		print("Reloading")
		return

	if !can_shoot:
		return

	if get_current_ammo() <= 0:
		print("No ammo")
		reload()
		return

	can_shoot = false
	use_ammo(1)

	match type:
		WeaponType.REVOLVER:
			shoot_revolver(camera)
		WeaponType.SHOTGUN:
			shoot_shotgun(camera)

	await get_tree().create_timer(get_fire_rate()).timeout
	can_shoot = true

func shoot_revolver(camera:Camera3D):
	var space_state := get_world_3d().direct_space_state

	var from := camera.global_position
	var direction := - camera.global_transform.basis.z
	var to := from + direction * revolver_range

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]

	var result := space_state.intersect_ray(query)

	if result:
		var hit_object = result["collider"]

		if hit_object.has_method("take_damage"):
			hit_object.take_damage(revolver_damage)

			print("Revolver hit: ", hit_object.name)
		else:
			print("Miss")

func shoot_shotgun(camera:Camera3D):
	for i in shotgun_pellets:
		var space_state := get_world_3d().direct_space_state

		var from := camera.global_position
		var direction := - camera.global_transform.basis.z

		var spread_x := deg_to_rad(randf_range(-shotgun_spread, shotgun_spread))
		var spread_y := deg_to_rad(randf_range(-shotgun_spread, shotgun_spread))

		direction = direction.rotated(camera.global_transform.basis.x, spread_y)
		direction = direction.rotated(camera.global_transform.basis.y, spread_x)
		direction = direction.normalized()

		var to := from + direction * shotgun_range

		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [self]

		var result := space_state.intersect_ray(query)

		if result:
			var hit_object = result["collider"]

			if hit_object.has_method("take_damage"):
				hit_object.take_damage(revolver_damage)

				print("Shotgun hit: ", hit_object.name)
			else:
				print("Miss")

func reload() -> void:
	if is_reloading:
		return

	if get_current_ammo() >= get_max_ammo():
		return

	if get_reserve_ammo() <= 0:
		print("No reserve ammo")
		return

	is_reloading = true
	can_shoot = false

	print("Reloading...")

	await get_tree().create_timer(get_reload_time()).timeout

	var needed_ammo := get_max_ammo() - get_current_ammo()
	var ammo_to_load = min(needed_ammo, get_reserve_ammo())

	add_current_ammo(ammo_to_load)
	remove_reserve_ammo(ammo_to_load)

	is_reloading = false
	can_shoot = true

	print("Reloaded")

func use_ammo(n:int):
	match type:
		WeaponType.REVOLVER:
			current_revolver_ammo -= n
		WeaponType.SHOTGUN:
			current_shotgun_ammo -= n

func add_current_ammo(amount: int) -> void:
	match type:
		WeaponType.REVOLVER:
			current_revolver_ammo += amount
			current_revolver_ammo = min(current_revolver_ammo, max_revolver_ammo)

		WeaponType.SHOTGUN:
			current_shotgun_ammo += amount
			current_shotgun_ammo = min(current_shotgun_ammo, max_shotgun_ammo)

func get_current_ammo() -> int:
	match type:
		WeaponType.REVOLVER:
			return current_revolver_ammo
		WeaponType.SHOTGUN:
			return current_shotgun_ammo

	return 0


func get_max_ammo() -> int:
	match type:
		WeaponType.REVOLVER:
			return max_revolver_ammo
		WeaponType.SHOTGUN:
			return max_shotgun_ammo

	return 0


func get_reserve_ammo() -> int:
	match type:
		WeaponType.REVOLVER:
			return reserve_revolver_ammo
		WeaponType.SHOTGUN:
			return reserve_shotgun_ammo

	return 0

func remove_reserve_ammo(amount: int) -> void:
	match type:
		WeaponType.REVOLVER:
			reserve_revolver_ammo -= amount
			reserve_revolver_ammo = max(reserve_revolver_ammo, 0)

		WeaponType.SHOTGUN:
			reserve_shotgun_ammo -= amount
			reserve_shotgun_ammo = max(reserve_shotgun_ammo, 0)

func get_reload_time() -> float:
	match type:
		WeaponType.REVOLVER:
			return revolver_reload_time
		WeaponType.SHOTGUN:
			return shotgun_reload_time

	return 1.0

func get_fire_rate() -> float:
	match type:
		WeaponType.REVOLVER:
			return revolver_fire_rate
		WeaponType.SHOTGUN:
			return shotgun_fire_rate

	return 0.5
