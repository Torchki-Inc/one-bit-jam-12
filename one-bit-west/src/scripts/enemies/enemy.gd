class_name BaseEnemy
extends CharacterBody3D

const GRAVITY := 9.81

@export var health := 100
@export var move_speed := 3.0
@export var shoot_radius := 10.0
@export var damage := 5.0
@export var touch_damage := 5.0
@export var touch_cooldown := 1.0
@export var touch_timer := 0.0

var player: Node3D
@onready var nav_agent = $NavigationAgent3D

func _physics_process(_delta: float) -> void:
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

func take_damage(amount: int):
	health -= amount
	print(name, " took ", amount, " damage. HP: ", health)

	if health <= 0:
		die()


func die():
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
