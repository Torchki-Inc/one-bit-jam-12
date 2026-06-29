extends Control

const GAME_SCENE_PATH := "res://src/scenes/main/main.tscn"
const MAIN_MENU_SCENE_PATH := "res://src/scenes/ui/main_menu.tscn"

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_main_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
