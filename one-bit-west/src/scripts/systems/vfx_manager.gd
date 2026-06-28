extends Node

const HIT_PUFF = preload("res://src/assets/vfx/hit_puff.tscn")
const DEATH_BURST = preload("res://src/assets/vfx/death_burst.tscn")

# EffectRoot — чистый контейнер для VFX, уже есть в main.tscn
var effect_root: Node3D

func _get_effect_root() -> Node3D:
    if effect_root:
        return effect_root
    effect_root = get_tree().get_first_node_in_group("effect_root")
    return effect_root

func spawn_hit_puff(pos: Vector3) -> void:
    var root = _get_effect_root()
    if not root:
        return
    var p = HIT_PUFF.instantiate()
    root.add_child(p)
    p.global_position = pos
    p.emitting = true
    get_tree().create_timer(p.lifetime + 0.1).timeout.connect(p.queue_free)

func hitstop(duration: float = 0.025, scale: float = 0.05) -> void:
    Engine.time_scale = scale
    # true = process_always, чтобы таймер тикал при замедлении
    await get_tree().create_timer(duration, true, false, true).timeout
    Engine.time_scale = 1.0

func spawn_death_burst(pos: Vector3) -> void:
    var root = _get_effect_root()
    if not root:
        return
    var p = DEATH_BURST	.instantiate()
    root.add_child(p)
    p.global_position = pos
    p.emitting = true
    get_tree().create_timer(p.lifetime + 0.1).timeout.connect(p.queue_free)
