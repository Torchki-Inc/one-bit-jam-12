class_name AmmoPickup
extends Area3D

@export var amount: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.add_shotgun_ammo(amount)
		queue_free()
