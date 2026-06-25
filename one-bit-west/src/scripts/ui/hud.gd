extends Control

@onready var health_label: Label = $HealthLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var health_bar: TextureProgressBar = $TextureProgressBar

func _process(delta: float) -> void:
	$Label.text = str(Engine.get_frames_per_second())

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$AmmoLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HealthLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$TextureProgressBar.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_max_health(value: int):
	health_bar.max_value = value

func set_health(value: int) -> void:
	health_label.text = "HP: " + str(value)
	health_bar.value = value


func set_ammo(current: int, reserve: int) -> void:
	ammo_label.text = "Ammo: " + str(current) + " / " + str(reserve)
