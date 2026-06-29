
class_name BaseEnemy
extends CharacterBody3D

enum Type { DOG, RIDER, BANDIT, SHOTGUN, HAWK, GHOST, NONE }

const GRAVITY := 9.81

#@export var spawn_cost := 10.0
@export var health := 100
@export var move_speed := 3.0
@export var shoot_radius := 10.0
@export var damage := 5.0
@export var touch_damage := 5.0
@export var touch_cooldown := 1.0
@export var sprites: EnemySprites
@export var dead_sprite_offset := 80.0

@export_group("animation")
@export var waddle_enabled := true
@export var waddle_amount_deg := 6.0
@export var waddle_speed := 10.0

var waddle_time := 0.0
var original_modulate: Color
var touch_timer := 0.0
const KILL_DEPTH = -20
var dead := false
var stun_timer := 0.0

var player: Node3D
@onready var nav_agent = $NavigationAgent3D

@onready var sprite: Sprite3D = $Sprite3D
var hit_tween: Tween


func _physics_process(_delta: float) -> void:
	if dead:
		return
	if stun_timer > 0:
		stun_timer -= _delta
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if global_position.y < KILL_DEPTH:
		queue_free()
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * _delta

	if touch_timer > 0:
		touch_timer -= _delta

	move_and_slide()
	_update_waddle(_delta)

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider.is_in_group("player") && collider.has_method("take_damage") && touch_timer <= 0:
			collider.take_damage(damage)
			touch_timer = touch_cooldown


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemy")
	original_modulate = sprite.modulate

	await get_tree().physics_frame
	if nav_agent.get_navigation_map() == RID():
		print("WARNING: nav map не назначен!")
	else:
		print("nav map OK: ", nav_agent.get_navigation_map())

	await get_tree().physics_frame
	nav_agent.max_speed = move_speed

	if sprites.walk != null:
		sprite.texture = sprites.walk


func take_damage(amount: int):
	if dead or not is_inside_tree():
		return
	health -= amount
	stun_timer = 0.15
	flash_hit()
	if health <= 0:
		die()


func die():
	if dead:
		return
	dead = true
	remove_from_group("enemy")
	var pos := global_position # кешируем до queue_free
	VfxManager.spawn_death_burst(pos)
	# TODO:
	# play death animation
	# leave dead spprite
	leave_body()



func _update_waddle(_delta: float) -> void:
	print("waddle spd: ", Vector2(velocity.x, velocity.z).length())
	if not waddle_enabled:
		return

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()

	if horizontal_speed > 0.1:
		waddle_time += _delta * waddle_speed * (horizontal_speed / move_speed)
		sprite.rotation_degrees.z = sin(waddle_time) * waddle_amount_deg
	else:
		sprite.rotation_degrees.z = lerp(sprite.rotation_degrees.z, 0.0, _delta * 5.0)


# calculate and move sprite toward player
func move_toward_target(target_pos: Vector3, _delta: float):
	nav_agent.target_position = target_pos

	var next: Vector3 = nav_agent.get_next_path_position()
	var dir := (next - global_position)
	dir.y = 0
	dir = dir.normalized()

	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	face_direction(dir)


# prevent sprites from moving backwards
func face_direction(move_dir: Vector3):
	if move_dir.x != 0:
		$Sprite3D.flip_h = move_dir.x < 0


func flash_hit() -> void:
	if hit_tween:
		hit_tween.kill()
	sprite.modulate = Color(0, 0, 0, 1) # белый флэш
	hit_tween = create_tween()
	hit_tween.tween_property(sprite, "modulate", original_modulate, 0.12)


func leave_body():
	print("called leave body")
	sprite.texture = sprites.dead
	sprite.offset.y -= dead_sprite_offset
	set_process(false)
	set_physics_process(false)
	add_to_group("dead")
	$CollisionShape3D.disabled = true
