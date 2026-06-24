extends Control

@onready var health_label: Label = $HealthLabel
@onready var ammo_label: Label = $AmmoLabel

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$AmmoLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HealthLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_health(value: int) -> void:
	health_label.text = "HP: " + str(value)

func set_ammo(current: int, reserve: int) -> void:
	ammo_label.text = "Ammo: " + str(current) + " / " + str(reserve)
