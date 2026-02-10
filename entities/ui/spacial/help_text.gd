extends Node3D

@export var wobble_height := 0.12
@export var wobble_speed := 1.5
@export var wobble_degrees := 4.0

var _base_position: Vector3
var _base_rotation: Vector3

func _ready() -> void:
	_base_position = position
	_base_rotation = rotation

func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	position.y = _base_position.y + sin(t * wobble_speed) * wobble_height
	rotation = _base_rotation + Vector3(0.0, deg_to_rad(wobble_degrees) * sin(t * wobble_speed), 0.0)
	#var camera := get_viewport().get_camera_3d()
	#if camera:
		#_face_target.look_at(camera.global_position, Vector3.UP)
		#_face_target.global_basis = _face_target.global_basis.rotated(Vector3.UP, PI)
