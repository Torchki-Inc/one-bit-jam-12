class_name BaseEnemy
extends CharacterBody3D

@export var health := 100
@export var move_speed := 3.0
@export var shoot_radius := 10.0
@export var damage := 5.0

var player: Node3D
@onready var nav_agent = $NavigationAgent3D


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func take_damage(amount: int):
	health -= amount
	print(name, " took ", amount, " damage. HP: ", health)

	if health <= 0:
		die()


func die():
	queue_free()


# calculate and move sprite toward player
func move_toward_target(target_pos: Vector3, delta: float):
	nav_agent.target_position = target_pos
	var next = nav_agent.get_next_path_position()
	var dir = (next - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()


# prevent sprites from moving backwards
func face_direction(move_dir: Vector3):
	if move_dir.x != 0:
		$Sprite3D.flip_h = move_dir.x < 0
