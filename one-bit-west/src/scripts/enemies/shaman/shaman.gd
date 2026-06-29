class_name ShamanBoss
extends CharacterBody3D

signal shaman_defeated
signal health_changed(new_hp: float)

@export var sprites: EnemySprites
@export var max_hp: float = 300.0
@export var summon_interval: float = 8.0
@export var teleport_interval: float = 12.0
@export var totem_respawn_delay: float = 15.0
@export var max_enemies: int = 10
@export var totem_scene: PackedScene

@onready var summon_timer: Timer = $SummonTimer
@onready var teleport_timer: Timer = $TeleportTimer
@onready var shield_vfx: Node3D = $ShieldVFX
@onready var sprite: Sprite3D = $Sprite
var hit_tween: Tween
var bob_time := 0.0

var original_modulate: Color

var hp: float
var wave_manager: WaveManager
var waypoints: Array[Marker3D] = []
var totem_positions: Array[Marker3D] = []
var waypoint_index: int = 0
var active_totems: int = 0


func _ready() -> void:
	add_to_group("boss")
	hp = max_hp
	wave_manager = get_tree().get_first_node_in_group("game_master")
	original_modulate = sprite.modulate

	for n in get_tree().get_nodes_in_group("waypoint"):
		waypoints.append(n as Marker3D)
	for n in get_tree().get_nodes_in_group("totem"):
		totem_positions.append(n as Marker3D)

	summon_timer.wait_time = summon_interval
	summon_timer.timeout.connect(_on_summon)
	teleport_timer.wait_time = teleport_interval
	teleport_timer.timeout.connect(_on_teleport)
	print("ShieldVFX _ready called")
	print("mesh: ", shield_vfx)
	await get_tree().process_frame # ждём _ready shield_vfx
	_update_shield()


func _process(delta: float) -> void:
	# плавный боб вверх-вниз
	bob_time += delta
	sprite.position.y = sin(bob_time * 2.0) * 0.15


func start() -> void:
	_spawn_totems()
	_on_summon()
	summon_timer.start()
	teleport_timer.start()

# ── Damage ───────────────────────────────────────────────────────────────────


# и вызов в take_damage когда щита нет:
func take_damage(amount: float) -> void:
	if active_totems > 0:
		if shield_vfx:
			shield_vfx.flash()
		return
	VfxManager.hitstop(0.04, 0.05)
	hp -= amount
	_flash_hit() # <--
	emit_signal("health_changed", hp)
	if hp <= 0.0:
		_die()

# ── Totem Spawning ─────────────────────────────────────────────────────────────────


func _spawn_totems() -> void:
	if totem_scene == null or totem_positions.is_empty():
		return

	var count := randi_range(2, min(4, totem_positions.size()))
	var shuffled := totem_positions.duplicate()
	shuffled.shuffle()

	for i in count:
		_spawn_totem(shuffled[i])


func _spawn_totem(pos: Marker3D) -> void:
	# проверка — уже стоит тотем на этой позиции?
	for t in get_tree().get_nodes_in_group("totem_active"):
		if t.global_position.distance_to(pos.global_position) < 1.0:
			return

	var t = totem_scene.instantiate()
	get_parent().add_child(t)
	t.global_position = pos.global_position
	t.add_to_group("totem_active")
	active_totems += 1
	t.tree_exiting.connect(func(): _on_totem_died(pos))


func _on_totem_died(pos: Marker3D) -> void:
	active_totems -= 1
	_update_shield()
	# респавн через задержку
	get_tree().create_timer(totem_respawn_delay).timeout.connect(
		func():
			if is_instance_valid(self):
				_spawn_totem(pos)
				_update_shield()
	)


# shaman.gd
func _update_shield() -> void:
	print("_update_shield called, active_totems: ", active_totems)
	print("shield_vfx: ", shield_vfx)
	if shield_vfx == null:
		return
	print("shield_vfx.visible before: ", shield_vfx.visible)
	shield_vfx.visible = active_totems > 0
	print("shield_vfx.visible after: ", shield_vfx.visible)

# ── Enemy Spawning ──────────────────────────────────────────────────────────


func _on_summon() -> void:
	if wave_manager == null:
		return
	var count := 3
	var pool := _get_pool()
	for i in count:
		if wave_manager.get_alive_enemy_count() >= max_enemies:
			break
		get_tree().create_timer(0.3 * i).timeout.connect(
			func():
				if is_instance_valid(wave_manager):
					wave_manager.spawn_enemy(pool[randi() % pool.size()])
		)


func _get_pool() -> Array:
	var ratio := hp / max_hp
	if ratio > 0.6:
		return [BaseEnemy.Type.BANDIT, BaseEnemy.Type.DOG]
	elif ratio > 0.3:
		return [BaseEnemy.Type.BANDIT, BaseEnemy.Type.HAWK, BaseEnemy.Type.SHOTGUN]
	else:
		return [BaseEnemy.Type.HAWK, BaseEnemy.Type.GHOST, BaseEnemy.Type.SHOTGUN]

# ── Teleport ───────────────────────────────────────────────────────────────


func _on_teleport() -> void:
	print("try teleport")
	if waypoints.is_empty():
		print("no waypoints")
		return
	waypoint_index = (waypoint_index + 1) % waypoints.size()
	global_position = waypoints[waypoint_index].global_position

# ── смерть ─────────────────────────────────────────────────────────────────


func _die() -> void:
	VfxManager.hitstop(0.08, 0.02)
	summon_timer.stop()
	teleport_timer.stop()
	emit_signal("shaman_defeated")
	await get_tree().create_timer(2.0).timeout
	queue_free()


func _flash_hit() -> void:
	if hit_tween:
		hit_tween.kill()
	sprite.modulate = Color(1, 1, 1, 1)
	hit_tween = create_tween()
	hit_tween.tween_property(sprite, "modulate", original_modulate, 0.15)
