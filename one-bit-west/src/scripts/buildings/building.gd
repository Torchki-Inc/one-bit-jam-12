extends CSGBox3D

@export var box_size := Vector3(9.0, 5.0, 7.0)

const MATERIAL_DIR := "res://src/materials/buildings/"

const BACK_MAT_PATH := MATERIAL_DIR + "back.tres"
const SIDE_MAT_PATH := MATERIAL_DIR + "side.tres"

const FACE_OFFSET := 0.01

func _ready() -> void:
	var random_front_mat := get_random_front_material()
	var back_mat := load(BACK_MAT_PATH)
	var side_mat := load(SIDE_MAT_PATH)

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


func get_random_front_material() -> Material:
	var files := DirAccess.get_files_at(MATERIAL_DIR)
	var front_files: Array[String] = []

	for file in files:
		if file.begins_with("front_") and file.ends_with(".tres"):
			front_files.append(file)

	if front_files.is_empty():
		push_error("No front_*.tres materials found in " + MATERIAL_DIR)
		return null

	var chosen_file: String = front_files.pick_random()
	return load(MATERIAL_DIR + chosen_file)


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
