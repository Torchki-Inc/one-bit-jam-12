extends Camera3D

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var walk_intensity: float = 0.02 # Footstep bob strength
var walk_speed: float = 12.0 # Bob frequency
var noise_time: float = 0.0
var base_position: Vector3 = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	base_position = position
	print("parent: ", get_parent())
	print("grandparent: ", get_parent().get_parent())
	print("is CharacterBody3D: ", get_parent().get_parent() is CharacterBody3D)


func shake(intensity: float, duration: float = 0.15) -> void:
	shake_intensity = intensity
	shake_duration = duration


func _process(delta: float) -> void:
	noise_time += delta

	var bob_offset := Vector3.ZERO
	var parent_body := get_parent().get_parent() as CharacterBody3D
	if parent_body and parent_body.is_on_floor():
		var speed_factor := parent_body.velocity.length() / 7.5 # normalize to SPEED
		if speed_factor > 0.05:
			bob_offset.y = sin(noise_time * walk_speed) * walk_intensity * speed_factor
			bob_offset.x = cos(noise_time * walk_speed * 0.5) * walk_intensity * 0.5 * speed_factor

	position = base_position + bob_offset
