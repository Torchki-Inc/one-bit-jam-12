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
		die()
	if not is_on_floor():
		velocity.y -= GRAVITY * _delta

	if touch_timer > 0:
		touch_timer -= _delta

	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider.is_in_group("player") && collider.has_method("take_damage") && touch_timer <= 0:
			print("collision: ", collision, " collider: ", collider, "TAKE TOUCH DAMAGE")
			collider.take_damage(damage)
			touch_timer = touch_cooldown


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemy")


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
	var pos := global_position  # кешируем до queue_free
	VfxManager.spawn_death_burst(pos)
	# TODO:
	# play death animation
	# leave dead spprite
	queue_free()


# calculate and move sprite toward player
func move_toward_target(target_pos: Vector3, _delta: float):
	var dir = (target_pos - global_position)
	dir.y = 0
	dir = dir.normalized()
	velocity = dir * move_speed
	move_and_slide()


# prevent sprites from moving backwards
func face_direction(move_dir: Vector3):
	if move_dir.x != 0:
		$Sprite3D.flip_h = move_dir.x < 0

func flash_hit() -> void:
	if hit_tween:
		hit_tween.kill()
	sprite.modulate = Color(1, 1, 1, 1)  # белый флэш
	hit_tween = create_tween()
	hit_tween.tween_property(sprite, "modulate", Color(0, 0, 0, 1), 0.12)
