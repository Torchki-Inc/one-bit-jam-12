extends CSGBox3D

@export var box_size := Vector3(9.0, 5.0, 7.0)

const FACE_OFFSET := 0.01

const BACK_MAT := preload("res://src/materials/buildings/back.tres")
const SIDE_MAT := preload("res://src/materials/buildings/side.tres")

const FRONT_MATS: Array[Material] = [
	preload("res://src/materials/buildings/front_bank.tres"),
	preload("res://src/materials/buildings/front_house1.tres"),
	preload("res://src/materials/buildings/front_house2.tres"),
	preload("res://src/materials/buildings/front_saloon.tres"),
	preload("res://src/materials/buildings/front_sheriff.tres"),
]

func _ready() -> void:
	var random_front_mat: Material = FRONT_MATS.pick_random()
	var back_mat: Material = BACK_MAT
	var side_mat: Material = SIDE_MAT

	var swap_front_back := randf() < 0.5

	var mat_on_front: Material = random_front_mat
	var mat_on_back: Material = back_mat

	if swap_front_back:
		mat_on_front = back_mat
		mat_on_back = random_front_mat

	make_quad(
		"Front",
		Vector3(box_size.x / 2.0 + FACE_OFFSET, 0, 0),
		Vector2(box_size.z, box_size.y),
		Vector3(0, 90, 0),
		mat_on_front
	)

	make_quad(
		"Back",
		Vector3(-box_size.x / 2.0 - FACE_OFFSET, 0, 0),
		Vector2(box_size.z, box_size.y),
		Vector3(0, -90, 0),
		mat_on_back
	)

	make_quad(
		"Left",
		Vector3(0, 0, -box_size.z / 2.0 - FACE_OFFSET),
		Vector2(box_size.x, box_size.y),
		Vector3(0, 180, 0),
		side_mat
	)

	make_quad(
		"Right",
		Vector3(0, 0, box_size.z / 2.0 + FACE_OFFSET),
		Vector2(box_size.x, box_size.y),
		Vector3(0, 0, 0),
		side_mat
	)


func make_quad(
	face_name: String,
	pos: Vector3,
	quad_size: Vector2,
	rot_deg: Vector3,
	mat: Material
) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = face_name

	var quad := QuadMesh.new()
	quad.size = quad_size

	mesh_instance.mesh = quad
	mesh_instance.position = pos
	mesh_instance.rotation_degrees = rot_deg
	mesh_instance.material_override = mat

	add_child(mesh_instance)
