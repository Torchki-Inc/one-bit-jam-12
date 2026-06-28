extends Sprite3D

enum WeaponType {
	REVOLVER,
	SHOTGUN
}

@export var type := WeaponType.REVOLVER

const SPRITE_DIR := "res://src/assets/weapons"

const REVOLVER_TEXTURES = [
	preload("res://src/assets/weapons/revolver/revovler.png"),
	preload("res://src/assets/weapons/revolver/revovler1.png"),
	preload("res://src/assets/weapons/revolver/revovler2.png"),
	preload("res://src/assets/weapons/revolver/revovler3.png"),
]

const SHOTGUN_TEXTURES = [
	preload("res://src/assets/weapons/shotgun/shotgun.png"),
	preload("res://src/assets/weapons/shotgun/shotgun1.png"),
	preload("res://src/assets/weapons/shotgun/shotgun2.png"),
	preload("res://src/assets/weapons/shotgun/shotgun3.png"),
	preload("res://src/assets/weapons/shotgun/shotgun4.png"),
]

# Revolver stats
@export_group("Revolver")
@export var revolver_damage := 2
@export var revolver_range := 30.0
@export var revolver_fire_rate := 0.35
@export var max_revolver_ammo := 6
@export var current_revolver_ammo := 6
@export var reserve_revolver_ammo := 24
@export var revolver_reload_time := 1.2

# Shotgun stats
@export_group("Shotgun")
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
var reload_animation_id := 0

signal ammo_changed(current: int, type: int)

func _ready() -> void:
	set_idle_texture()

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

	var type_n := 0 if type == WeaponType.REVOLVER else 1
	emit_signal("ammo_changed", get_current_ammo(), type_n)

	match type:
		WeaponType.REVOLVER:
			shoot_revolver(camera)
		WeaponType.SHOTGUN:
			shoot_shotgun(camera)

	await get_tree().create_timer(get_fire_rate()).timeout
	can_shoot = true

	if get_current_ammo() == 0:
		reload()

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

		elif hit_object.get_parent().has_method("take_damage"):
			hit_object.get_parent().take_damage(revolver_damage)

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
				hit_object.take_damage(shotgun_damage)

				print("Shotgun hit: ", hit_object.name)

			elif hit_object.get_parent().has_method("take_damage"):
				hit_object.get_parent().take_damage(shotgun_damage)

				print("Shotgun hit: ", hit_object.get_parent().name)

		else:
			print("Miss")

func reload() -> void:
	if is_reloading:
		return

	if get_current_ammo() >= get_max_ammo():
		return

	is_reloading = true
	can_shoot = false
	reload_animation_id += 1
	play_reload_animation(reload_animation_id)

	print("Reloading...")

	await get_tree().create_timer(get_reload_time()).timeout

	var needed_ammo := get_max_ammo() - get_current_ammo()
	var ammo_to_load = min(needed_ammo, get_reserve_ammo())

	add_current_ammo(ammo_to_load)

	var type_n := 0 if type == WeaponType.REVOLVER else 1
	emit_signal("ammo_changed", get_current_ammo(), type_n)

	is_reloading = false
	can_shoot = true
	set_idle_texture()

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

		WeaponType.SHOTGUN:
			reserve_shotgun_ammo -= amount

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

func update_ammo_display() -> void:
	ammo_changed.emit(get_current_ammo(), get_reserve_ammo())

func play_reload_animation(animation_id: int) -> void:
	var frames := get_reload_frames()
	if frames.is_empty():
		return

	var frame_time := get_reload_time() / float(frames.size())

	for frame in frames:
		if animation_id != reload_animation_id or !is_reloading:
			return

		texture = frame
		await get_tree().create_timer(frame_time).timeout

	if animation_id == reload_animation_id:
		set_idle_texture()


func get_reload_frames() -> Array:
	match type:
		WeaponType.REVOLVER:
			return REVOLVER_TEXTURES.slice(1)
		WeaponType.SHOTGUN:
			return SHOTGUN_TEXTURES.slice(1)

	return []


func set_idle_texture() -> void:
	match type:
		WeaponType.REVOLVER:
			texture = REVOLVER_TEXTURES[0]
		WeaponType.SHOTGUN:
			texture = SHOTGUN_TEXTURES[0]

func set_weapon_type(new_type: int) -> void:
	if type == new_type:
		return

	type = new_type
	reload_animation_id += 1
	is_reloading = false
	can_shoot = true
	set_idle_texture()
	var type_n := 0 if type == WeaponType.REVOLVER else 1
	emit_signal("ammo_changed", get_current_ammo(), type_n)

func add_reserve_ammo(amount: int) -> void:
	print("Adding reserve ammo: ", amount)
	reserve_shotgun_ammo += amount
	emit_signal("ammo_changed", get_current_ammo(), 1)
