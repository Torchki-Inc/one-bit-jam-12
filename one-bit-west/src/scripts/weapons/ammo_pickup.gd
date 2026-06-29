class_name AmmoPickup
extends Area3D

@export var amount: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var weapon = body.get_node("Head/Weapon")
		weapon.add_reserve_ammo(amount)
		AudioManager.play(AudioManager.PICKUP, -3.0, 0.05)
		queue_free()
