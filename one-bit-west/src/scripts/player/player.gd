extends CharacterBody3D

@export var hud: Control

const SPEED: float = 7.5
const ACCELERATION: float = 25.0
const SENSITIVITY: float = 0.004

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

@onready var weapon := $Head/Weapon

var max_health := 100
var health := max_health

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func setup_hud():
	hud.set_max_health(max_health)
	hud.set_health(health)
	weapon.ammo_changed.connect(hud.set_ammo)
	weapon.update_ammo_display()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * SENSITIVITY)

		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(
			camera.rotation.x,
			deg_to_rad(-70),
			deg_to_rad(70),
		)

	if event.is_action_pressed("shoot"):
		weapon.shoot(camera);

	if event.is_action_pressed("change_weapon"):
		match weapon.type:
			weapon.WeaponType.REVOLVER:
				weapon.type = weapon.WeaponType.SHOTGUN
			weapon.WeaponType.SHOTGUN:
				weapon.type = weapon.WeaponType.REVOLVER

		var type_n := 0 if weapon.type == weapon.WeaponType.REVOLVER else 1
		hud.set_ammo(weapon.get_current_ammo(), type_n)


func _physics_process(delta: float) -> void:
	# Simple gravity (only if you have floors)
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Input
	var input_dir: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down",
	)

	# Movement direction relative to view
	var direction: Vector3 = (head.global_basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var target_velocity: Vector3 = direction * SPEED

	# Smooth acceleration (Doom-like feel)
	velocity.x = move_toward(velocity.x, target_velocity.x, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, ACCELERATION * delta)

	move_and_slide()


func take_damage(amount: int):
	health -= amount
	print(name, " took ", amount, " damage. HP: ", health)

	hud.set_health(health)
