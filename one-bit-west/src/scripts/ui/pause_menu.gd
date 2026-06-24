extends Control

@export var main_menu_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func _on_resume_button_button_up() -> void:
	get_tree().paused = false
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_options_button_button_up() -> void:
	pass # Replace with function body.


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_packed(main_menu_scene)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
