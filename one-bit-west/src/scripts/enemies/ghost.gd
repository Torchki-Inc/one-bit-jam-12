class_name Ghost
extends BaseEnemy

@export var type: BaseEnemy.Type = BaseEnemy.Type.GHOST

@export var HOVER_HEIGHT := 1.2   # высота над полом
@export var HOVER_SPEED := 4.0    # скорость выравнивания по Y
var sm: EnemySM


func _ready():
	super._ready()
	sm = EnemySM.new()

	var roam = GhostRoamState.new()

	roam.enemy = self
	sm.current = roam
	sm.enter()

func take_damage(_amount: int):
	pass

func _physics_process(delta: float) -> void:
	_hover(delta)
	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider.is_in_group("player") && collider.has_method("take_damage") && touch_timer <= 0:
			print("collision: ", collision, " collider: ", collider, "TAKE TOUCH DAMAGE")
			collider.take_damage(damage)
			self.die()
	sm.update(delta)


func _hover(delta: float) -> void:
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * 10)
	query.exclude = [self]
	var result = space.intersect_ray(query)

	if result:
		var floor_y = result.position.y
		var target_y = floor_y + HOVER_HEIGHT

		velocity.y = (target_y - global_position.y) * HOVER_SPEED
	else:
		velocity.y = 0


class GhostRoamState extends EnemyState:
	var next: EnemyState
	var timer := 0.0

	func enter():
		_pick_new_target()

	func update(delta) -> EnemyState:
		timer -= delta
		if timer <= 0.0:
			_pick_new_target()

		# move_toward_target трогает только X/Z, Y управляет _hover
		var target = enemy.player.global_position
		var dir = (target - enemy.global_position)
		dir.y = 0
		dir = dir.normalized()
		enemy.velocity.x = dir.x * enemy.move_speed
		enemy.velocity.z = dir.z * enemy.move_speed

		return self

	func _pick_new_target():
		timer = randf_range(2.0, 4.0)
