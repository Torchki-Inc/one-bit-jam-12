extends Control

@onready var fps_label = $VBoxContainer/Fps
@onready var enemies_alive_label = $VBoxContainer/EnemiesAlive
@onready var wave_time_label = $VBoxContainer/WaveTimeLeft

var game_manager: Node # assign in editor


func _process(_delta: float) -> void:
	if not game_manager:
		game_manager = get_node_or_null("../../Systems/GameManager")
		return

	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	enemies_alive_label.text = "Enemies: %d" % game_manager.get_alive_enemy_count()

	if game_manager.boss_fight:
		wave_time_label.text = "BOSS FIGHT"
	elif game_manager.state == WaveManager.State.WAVE_COOLDOWN:
		wave_time_label.text = "Wave %d | Cooldown: %.1f" % [
			game_manager.current_wave_index,
			game_manager.timer.time_left,
		]
	else:
		wave_time_label.text = "Wave %d | T: %.1f | Burst: %d/%d" % [
			game_manager.current_wave_index,
			game_manager.wave_time,
			game_manager.next_burst,
			game_manager.current_wave.bursts.size(),
		]
