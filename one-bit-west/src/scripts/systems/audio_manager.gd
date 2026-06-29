extends Node

const BASE_LOOP := preload("res://src/assets/audio/base_loop.wav")
const BOSS_LOOP := preload("res://src/assets/audio/boss_loop.wav")

const REVOLVER := preload("res://src/assets/audio/revolver.wav")
const SHOTGUN := preload("res://src/assets/audio/shotgun.wav")
const RELOAD := preload("res://src/assets/audio/reload.mp3")

const HIT_WALL := preload("res://src/assets/audio/hitwall.wav")
const HIT_ENEMY := preload("res://src/assets/audio/hit_not_wall.wav")
const PICKUP := preload("res://src/assets/audio/pickup.wav")

var music_player: AudioStreamPlayer


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	# Cheap looping.
	music_player.finished.connect(func():
		if music_player.stream != null:
			music_player.play()
	)


func play(sound: AudioStream, volume_db := -5.0, pitch_random := 0.0) -> void:
	if sound == null:
		return

	var p := AudioStreamPlayer.new()
	p.stream = sound
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_random, pitch_random)

	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func play_3d(sound: AudioStream, pos: Vector3, volume_db := -5.0, pitch_random := 0.0) -> void:
	if sound == null:
		return

	var p := AudioStreamPlayer3D.new()
	p.stream = sound
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_random, pitch_random)
	p.max_distance = 30.0

	add_child(p)
	p.global_position = pos

	p.finished.connect(p.queue_free)
	p.play()


func play_music(sound: AudioStream, volume_db := -5.0) -> void:
	if music_player.stream == sound and music_player.playing:
		return

	music_player.stop()
	music_player.stream = sound
	music_player.volume_db = volume_db
	music_player.play()


func stop_music() -> void:
	music_player.stop()
	music_player.stream = null
