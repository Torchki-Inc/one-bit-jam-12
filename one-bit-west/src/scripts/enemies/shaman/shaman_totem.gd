class_name ShamanTotem
extends CharacterBody3D

@export var hp: float = 50.0


func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		queue_free()
