extends Control

@onready var fps_label = $VBoxContainer/Fps
@onready var enemies_alive_label = $VBoxContainer/EnemiesAlive
@onready var wave_time_label = $VBoxContainer/WaveTimeLeft

var game_manager: Node # assign in editor


func _process(_delta: float) -> void:
	if not game_manager:
		game_manager = get_node_or_null("../../Systems/GameManager")
		return

	fps_label.text = "Current Wave: %s" % game_manager.current_wave_index
	enemies_alive_label.text = "Enemies: %d" % game_manager.get_alive_enemy_count()
	wave_time_label.text = "Time: %.1f" % game_manager.timer.time_left # adjust to actual property
