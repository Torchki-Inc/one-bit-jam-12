extends Node3D

@onready var mesh: MeshInstance3D = $MeshInstance3D

var mat: StandardMaterial3D
var base_scale := Vector3.ONE

func _ready():
	mat = mesh.get_active_material(0).duplicate()
	mesh.material_override = mat
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0, 0, 0, 0.25)

	base_scale = mesh.scale
	visible = true

func _process(delta):
	var t := Time.get_ticks_msec() * 0.001
	var pulse := 1.0 + sin(t * 7.0) * 0.06
	mesh.scale = base_scale * pulse


func flash():
	if mat == null:
		return

	var tween = create_tween()
	mat.albedo_color = Color(0, 0, 0, 0.9)

	tween.tween_property(mat, "albedo_color",
		Color(0, 0, 0, 0.15), 0.12)
