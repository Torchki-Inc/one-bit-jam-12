extends CharacterBody3D

@export var health := 100

func take_damage(amount: int):
	health -= amount
	print(name, " took ", amount, " damage. HP: ", health)

	if health <= 0:
		die()

func die():
	queue_free()
