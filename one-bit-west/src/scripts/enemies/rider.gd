class_name Rider
extends BaseEnemy

@export var type: BaseEnemy.Type = BaseEnemy.Type.RIDER

var sm: EnemySM
@export var CHARGE_SPEED := 14.0


func _ready():
	super._ready()
	sm = EnemySM.new()

	var roam = RiderRoamState.new()
	var charge = RiderChargeState.new()

	roam.enemy = self
	roam.next = charge
	charge.enemy = self
	charge.next = roam


	sm.current = roam
	sm.enter()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	sm.update(delta)

func die():
	var scene = preload("res://src/scenes/enemies/revolver_bandit.tscn")
	var new_enemy = scene.instantiate()
	new_enemy.global_position = global_position + Vector3(0, 0.5, 0)
	get_parent().add_child(new_enemy)
	super.die()


class RiderRoamState extends EnemyState:
	var next: EnemyState
	var orbit_angle := 0.0          # current angle around the player
	var orbit_radius := 8.0         # how far to stay from player
	var orbit_speed := 1.2          # radians per second (higher = faster circle)
	var charge_timer := 0.0         # countdown before charging
	var charge_delay := 3.0         # how long to wait before charging

	func enter() -> void:
		# Start
		enemy.velocity = Vector3.ZERO
		var offset = enemy.global_position - enemy.player.global_position
		orbit_angle = atan2(offset.x, offset.z)
		charge_timer = randf_range(2.0, charge_delay)
		orbit_speed *= [-1.0, 1.0].pick_random()

	func update(_delta: float) -> EnemyState:
		orbit_angle += orbit_speed * _delta

		var target = enemy.player.global_position + Vector3(
			cos(orbit_angle) * orbit_radius,
			0.0,
			sin(orbit_angle) * orbit_radius
		)

		enemy.move_toward_target(target, _delta)

		charge_timer -= _delta
		if charge_timer <= 0.0:
			return next

		return self



class RiderChargeState extends EnemyState:
	var next: EnemyState
	var timer := 0.0
	var jump_duration := 1.0
	const GRAVITY := 20.0

	func enter():
		timer = jump_duration
		_charge()

	func _charge():
		var direction = (enemy.player.global_position - enemy.global_position).normalized()
		enemy.velocity = Vector3(direction.x * enemy.CHARGE_SPEED, 0.0, direction.z * enemy.CHARGE_SPEED)

	func update(delta) -> EnemyState:
		# Always apply gravity
		if not enemy.is_on_floor():
			enemy.velocity.y -= GRAVITY * delta

		# Always call move_and_slide — this is what actually moves the body
		# enemy.move_and_slide()

		timer -= delta
		if timer <= 0.0 and enemy.is_on_floor():
			return next
		return self
