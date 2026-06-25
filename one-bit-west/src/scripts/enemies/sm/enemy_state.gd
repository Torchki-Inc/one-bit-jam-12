class_name EnemyState
extends RefCounted

var enemy: BaseEnemy


func enter() -> void:
	pass

func update(_delta: float) -> EnemyState:
	return self
	
func exit() -> void: 
	pass 
