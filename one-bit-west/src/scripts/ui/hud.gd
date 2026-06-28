extends Control

@onready var health_label: Label = $HealthLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var health_bar: TextureProgressBar = $TextureProgressBar
@onready var ammo_counter: TextureRect = $TextureRect
@onready var boss_bar: TextureProgressBar = $BossBar # добавь нод в сцену
@onready var reserve_ammo_container: HBoxContainer = $ReserveAmmoContainer

var shaman: ShamanBoss

const REVOLVER_AMMO_TEXTURES = [
	preload("res://src/assets/HUD/ammo/revovlerammo0.png"),
	preload("res://src/assets/HUD/ammo/revovlerammo1.png"),
	preload("res://src/assets/HUD/ammo/revovlerammo2.png"),
	preload("res://src/assets/HUD/ammo/revovlerammo3.png"),
	preload("res://src/assets/HUD/ammo/revovlerammo4.png"),
	preload("res://src/assets/HUD/ammo/revovlerammo5.png"),
	preload("res://src/assets/HUD/ammo/revovlerammo6.png"),
]

const SHOTGUN_AMMO_TEXTURES = [
	preload("res://src/assets/HUD/ammo/shotgunammo0.png"),
	preload("res://src/assets/HUD/ammo/shotgunammo1.png"),
	preload("res://src/assets/HUD/ammo/shotgunammo2.png"),
]

const SHOTGUN_RESERVE_BULLET_TEXTURE = preload("res://src/assets/weapons/shotgun/shotgunammo.png")

func _process(delta: float) -> void:
	$Label.text = str(Engine.get_frames_per_second())

	if not shaman:
		shaman = get_tree().get_first_node_in_group("boss")
		if shaman:
			boss_bar.visible = true
			boss_bar.max_value = shaman.max_hp

	if shaman:
		if is_instance_valid(shaman):
			boss_bar.value = shaman.hp
		else:
			boss_bar.visible = false
			shaman = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$AmmoLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HealthLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$TextureProgressBar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar.visible = false


func set_max_health(value: int):
	health_bar.max_value = value


func set_health(value: int) -> void:
	health_label.text = "HP: " + str(value)
	health_bar.value = value


func set_ammo(current: int, type: int, reserve: int) -> void:
	ammo_label.text = "Ammo: " + str(current)

	for child in reserve_ammo_container.get_children():
			child.queue_free()

	for i in reserve:
		var shell := TextureRect.new()
		shell.texture = SHOTGUN_RESERVE_BULLET_TEXTURE
		shell.custom_minimum_size = Vector2(70, 70)
		shell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shell.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		reserve_ammo_container.add_child(shell)

	match type:
		0:
			ammo_counter.texture = REVOLVER_AMMO_TEXTURES[current]
		1:
			ammo_counter.texture = SHOTGUN_AMMO_TEXTURES[current]
