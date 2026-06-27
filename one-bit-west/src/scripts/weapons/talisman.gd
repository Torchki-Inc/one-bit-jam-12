class_name Talisman
extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		get_tree().get_first_node_in_group("game_master").kill_all_ghosts()
		queue_free()
