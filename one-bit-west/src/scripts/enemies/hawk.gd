class_name Hawk
extends BaseEnemy

@export var type: BaseEnemy.Type = BaseEnemy.Type.HAWK



var sm: EnemySM
@export var charge_delay := 3.0         # how long to wait before charging
@export var orbit_radius := 8.0         # how far to stay from player
@export var orbit_speed := 1.2          # radians per second (higher = faster circle)

@export var CHARGE_SPEED := 14.0
@export var FLY_HEIGHT := 5.0

func _ready():
	super._ready()
	sm = EnemySM.new()

	var roam = HawkRoamState.new()
	var dive = HawkDiveState.new()

	roam.enemy = self
	roam.next = dive
	dive.enemy = self
	dive.next = roam


	sm.current = roam
	sm.enter()


func _physics_process(delta: float) -> void:
	if touch_timer > 0:
		touch_timer -= delta

	sm.update(delta)
	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider.is_in_group("player") && collider.has_method("take_damage") && touch_timer <= 0:
			print("collision: ", collision, " collider: ", collider, "TAKE TOUCH DAMAGE")
			collider.take_damage(damage)
			touch_timer = touch_cooldown


class HawkRoamState extends EnemyState:
	var next: EnemyState
	var orbit_angle := 0.0          # current angle around the player
	var charge_timer := 0.0         # countdown before charging

	func enter() -> void:
		# Start
		enemy.velocity = Vector3.ZERO
		var offset = enemy.global_position - enemy.player.global_position
		orbit_angle = atan2(offset.x, offset.z)
		charge_timer = randf_range(2.0, enemy.charge_delay)
		enemy.orbit_speed *= [-1.0, 1.0].pick_random()

	func update(_delta: float) -> EnemyState:
		orbit_angle += enemy.orbit_speed * _delta

		var target = enemy.player.global_position + Vector3(
			cos(orbit_angle) * enemy.orbit_radius,
			enemy.FLY_HEIGHT,
			sin(orbit_angle) * enemy.orbit_radius
		)

		var dir = (target - enemy.global_position).normalized()
		enemy.velocity = dir * enemy.move_speed


		charge_timer -= _delta
		if charge_timer <= 0.0:
			return next

		return self



class HawkDiveState extends EnemyState:
	var next: EnemyState
	var dive_target := Vector3.ZERO
	var done := false
	var elapsed := 0.0
	const MAX_DIVE_TIME := 2.5

	func enter():
		done = false
		elapsed = 0.0
		dive_target = enemy.player.global_position

	func update(_delta) -> EnemyState:
		elapsed += _delta

		var to_target = dive_target - enemy.global_position
		if to_target.length() < 0.01:
			return next

		var dir = to_target.normalized()
		enemy.velocity = dir * enemy.CHARGE_SPEED

		if enemy.global_position.distance_to(dive_target) < 1.5:
			return next

		if elapsed >= MAX_DIVE_TIME:
			return next

		return self
