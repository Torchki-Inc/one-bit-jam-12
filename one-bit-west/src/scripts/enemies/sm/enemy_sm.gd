class_name EnemySM
extends RefCounted

var current: EnemyState


func enter():
	current.enter()


func update(delta: float):
	var next = current.update(delta)
	if next != current:
		current.exit()
		current = next
		current.enter()
