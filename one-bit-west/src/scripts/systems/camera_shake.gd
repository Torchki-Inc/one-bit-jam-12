extends Camera3D

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var walk_intensity: float = 0.02
var walk_speed: float = 12.0
var noise_time: float = 0.0
var base_position: Vector3 = Vector3.ZERO
var base_rotation: Vector3 = Vector3.ZERO


var kick_tween: Tween

func _ready() -> void:
    base_position = position
    base_rotation = rotation

func shake(intensity: float, duration: float = 0.15) -> void:
    shake_intensity = intensity
    shake_duration = duration

func kick(angle_deg: float = 3.0, back_distance: float = 0.04) -> void:
    if kick_tween:
        kick_tween.kill()

    var kick_rad := deg_to_rad(angle_deg)

    # Immediate recoil
    rotation.x -= kick_rad
    position.z += back_distance
    position.x += randf_range(-0.01, 0.01)

    kick_tween = create_tween()

    # Fast recovery from position
    kick_tween.parallel().tween_property(
        self,
        "position:z",
        base_position.z,
        0.08
    )

    kick_tween.parallel().tween_property(
        self,
        "position:x",
        base_position.x,
        0.10
    )

    # Slower recovery from rotation
    kick_tween.parallel().tween_property(
        self,
        "rotation:x",
        base_rotation.x,
        0.12
    ).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
    noise_time += delta

    var bob_offset := Vector3.ZERO
    var parent_body := get_parent().get_parent() as CharacterBody3D
    if parent_body and parent_body.is_on_floor():
        var speed_factor := parent_body.velocity.length() / 7.5
        if speed_factor > 0.05:
            bob_offset.y = sin(noise_time * walk_speed) * walk_intensity * speed_factor
            bob_offset.x = cos(noise_time * walk_speed * 0.5) * walk_intensity * 0.5 * speed_factor

    position = base_position + bob_offset
