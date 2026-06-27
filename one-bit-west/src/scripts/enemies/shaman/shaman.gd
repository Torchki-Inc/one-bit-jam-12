class_name ShamanBoss
extends CharacterBody3D

signal phase_changed(phase: int)
signal shaman_defeated

# ── exports ────────────────────────────────────────────────────────────────
@export var max_hp: float = 300.0
@export var vulnerability_duration: float = 4.0
@export var ritual_cast_duration: float = 5.0

@export var phase2_hp_threshold: float = 0.60
@export var phase3_hp_threshold: float = 0.30
@export var totem_scene: PackedScene
@export var totem_positions: Array[Marker3D] = []
@export var waypoints: Array[Marker3D] = []    # phase 3 reposition

# burst configs per phase — uses same Type enum as WaveManager
@export var phase1_pool: Array[int] = [
	BaseEnemy.Type.BANDIT,
	BaseEnemy.Type.DOG,
]
@export var phase2_pool: Array[int] = [
	BaseEnemy.Type.BANDIT,
	BaseEnemy.Type.DOG,
	BaseEnemy.Type.HAWK,
]
@export var phase3_pool: Array[int] = [
	BaseEnemy.Type.SHOTGUN,
	BaseEnemy.Type.HAWK,
	BaseEnemy.Type.GHOST,
]
@export var phase_burst_count: Array[int] = [4, 5, 6]  # enemies per burst per phase

# ── node refs ──────────────────────────────────────────────────────────────
@onready var sprite: Sprite3D = $AnimatedSprite3D
@onready var vulnerability_timer: Timer = $VulnerabilityTimer
@onready var ritual_timer: Timer = $RitualTimer
@onready var ritual_circle: Node3D = $RitualCircle
@onready var shield_vfx: Node3D = $ShieldVFX

# ── state machine ──────────────────────────────────────────────────────────
enum State { IDLE, SUMMONING, VULNERABLE, RITUAL }
var state: State = State.IDLE

# ── runtime ────────────────────────────────────────────────────────────────
var hp: float
var phase: int = 1
var immune: bool = true
var active_totems: Array = []
var waypoint_index: int = 0
var wave_manager: WaveManager


# ── lifecycle ──────────────────────────────────────────────────────────────
func _ready() -> void:
	hp = max_hp

	wave_manager = get_tree().get_first_node_in_group("game_master")
	vulnerability_timer.wait_time = vulnerability_duration
	vulnerability_timer.one_shot = true
	vulnerability_timer.timeout.connect(_on_vulnerability_expired)

	ritual_timer.wait_time = ritual_cast_duration
	ritual_timer.one_shot = true
	ritual_timer.timeout.connect(_on_ritual_completed)

	ritual_circle.visible = false
	_spawn_totems()
	_enter_state(State.IDLE)

# ── public ─────────────────────────────────────────────────────────────────
func take_damage(amount: float) -> void:
	if immune:
		print("immune")
		return
	hp -= amount
	_check_phase_transition()
	if hp <= 0.0:
		_die()

# called by each enemy when it dies — wire this in BaseEnemy death or via signal
func on_summon_died() -> void:
	# use WaveManager's own counter — it already tracks the "enemy" group
	var alive := wave_manager.get_alive_enemy_count()

	if alive == 0:
		if state == State.RITUAL:
			_cancel_ritual()
		_enter_state(State.VULNERABLE)

# ── state machine ──────────────────────────────────────────────────────────
func _enter_state(new_state: State) -> void:
	state = new_state
	match state:

		State.IDLE:
			immune = true
			_update_shield_vfx(true)
			#sprite.play("idle")
			var delay := 2.0 if phase == 1 else 1.2
			await get_tree().create_timer(delay).timeout
			if state == State.IDLE:
				_enter_state(State.RITUAL)

		State.SUMMONING:
			immune = true
			_update_shield_vfx(true)
			#sprite.play("summon")
			await get_tree().create_timer(1.2).timeout
			_spawn_burst()
			_enter_state(State.IDLE)

		State.VULNERABLE:
			immune = false
			_update_shield_vfx(false)
			#sprite.play("stagger")
			vulnerability_timer.start()

		State.RITUAL:
			#sprite.play("ritual")
			ritual_circle.visible = true
			ritual_timer.start()

# ── timer callbacks ────────────────────────────────────────────────────────
func _on_vulnerability_expired() -> void:
	if state != State.VULNERABLE:
		return
	if phase == 3:
		_reposition()
	_enter_state(State.SUMMONING)

func _on_ritual_completed() -> void:
	ritual_circle.visible = false
	_spawn_burst(true)   # mass resurrection — double count
	_enter_state(State.IDLE)

func _cancel_ritual() -> void:
	ritual_timer.stop()
	ritual_circle.visible = false

# ── spawning ───────────────────────────────────────────────────────────────
func _spawn_burst(mass_resurrection: bool = false) -> void:
	var pool := _pool_for_phase()
	var count: int = phase_burst_count[phase - 1]
	if mass_resurrection:
		count *= 2

	var wm := get_tree().get_first_node_in_group("game_master")
	if wm == null:
		push_error("ShamanBoss: WaveManager not found")
		return

	for i in count:
		var type: int = pool[randi() % pool.size()]
		get_tree().create_timer(0.3 * i).timeout.connect(
			func():
				if is_instance_valid(wm):
					wm.spawn_enemy(type)
		)

# ── helpers ────────────────────────────────────────────────────────────────
func _pool_for_phase() -> Array[int]:
	match phase:
		1: return phase1_pool
		2: return phase2_pool
		_: return phase3_pool

func _check_phase_transition() -> void:
	var ratio := hp / max_hp
	if phase == 1 and ratio <= phase2_hp_threshold:
		_set_phase(2)
	elif phase == 2 and ratio <= phase3_hp_threshold:
		_set_phase(3)

func _set_phase(new_phase: int) -> void:
	phase = new_phase
	emit_signal("phase_changed", phase)
	for t in active_totems:
		if is_instance_valid(t):
			t.queue_free()
	active_totems.clear()
	_spawn_totems()

func _spawn_totems() -> void:
	if totem_scene == null:
		return
	var count := phase
	for i in min(count, totem_positions.size()):
		var t = totem_scene.instantiate()
		get_parent().add_child(t)
		t.global_position = totem_positions[i].global_position
		t.tree_exiting.connect(func(): active_totems.erase(t))
		active_totems.append(t)

func _reposition() -> void:
	if waypoints.is_empty():
		return
	waypoint_index = (waypoint_index + 1) % waypoints.size()
	global_position = waypoints[waypoint_index].global_position

func _update_shield_vfx(active: bool) -> void:
	shield_vfx.visible = active

func _die() -> void:
	immune = true
	vulnerability_timer.stop()
	ritual_timer.stop()
	#sprite.play("death")
	emit_signal("shaman_defeated")
	await get_tree().create_timer(2.0).timeout
	queue_free()
