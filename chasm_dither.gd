@tool
extends Node3D

@export var corner_a: Node3D
@export var corner_b: Node3D
@export var mesh_instance: MeshInstance3D
@export var corner_a_path: NodePath = NodePath("CornerA")
@export var corner_b_path: NodePath = NodePath("CornerB")
@export var mesh_path: NodePath = NodePath("Surface")

@export var bottom_depth: float = 12.0:
	set(value):
		_bottom_depth = max(value, 0.0)
		_update_visual()
	get:
		return _bottom_depth

@export var curve_power: float = 2.0:
	set(value):
		_curve_power = max(value, 0.1)
		_update_visual()
	get:
		return _curve_power

@export var subdivisions: int = 32:
	set(value):
		_subdivisions = max(value, 1)
		_update_visual()
	get:
		return _subdivisions

@export var top_color: Color = Color(0.12, 0.14, 0.16):
	set(value):
		_top_color = value
		_update_visual()
	get:
		return _top_color

@export var bottom_color: Color = Color(0.02, 0.02, 0.03):
	set(value):
		_bottom_color = value
		_update_visual()
	get:
		return _bottom_color

@export var banding_levels: float = 6.0:
	set(value):
		_banding_levels = max(value, 1.0)
		_update_visual()
	get:
		return _banding_levels

@export var dither_scale: float = 1.0:
	set(value):
		_dither_scale = max(value, 0.01)
		_update_visual()
	get:
		return _dither_scale

@export var dither_strength: float = 1.0:
	set(value):
		_dither_strength = max(value, 0.0)
		_update_visual()
	get:
		return _dither_strength

@export var update_in_editor: bool = true

var _bottom_depth: float = 12.0
var _curve_power: float = 2.0
var _subdivisions: int = 32
var _top_color: Color = Color(0.12, 0.14, 0.16)
var _bottom_color: Color = Color(0.02, 0.02, 0.03)
var _banding_levels: float = 6.0
var _dither_scale: float = 1.0
var _dither_strength: float = 1.0
var _last_corner_a: Vector3 = Vector3.ZERO
var _last_corner_b: Vector3 = Vector3.ZERO

func _ready() -> void:
	set_process(true)
	_update_visual()

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not update_in_editor:
		return

	var corner_a := _resolve_corner(corner_a, corner_a_path)
	var corner_b := _resolve_corner(corner_b, corner_b_path)
	if corner_a == null or corner_b == null:
		return

	if corner_a.position != _last_corner_a or corner_b.position != _last_corner_b:
		_update_visual()

func _resolve_corner(node: Node3D, path: NodePath) -> Node3D:
	if node != null:
		return node
	var resolved = get_node_or_null(path)
	if resolved == null:
		return null
	return resolved as Node3D

func _resolve_mesh_instance(node: MeshInstance3D, path: NodePath) -> MeshInstance3D:
	if node != null:
		return node
	var resolved = get_node_or_null(path)
	if resolved == null:
		return null
	return resolved as MeshInstance3D

func _update_visual() -> void:
	var corner_a := _resolve_corner(corner_a, corner_a_path)
	var corner_b := _resolve_corner(corner_b, corner_b_path)
	var mesh_instance := _resolve_mesh_instance(mesh_instance, mesh_path)

	if corner_a == null or corner_b == null or mesh_instance == null:
		return

	var a_pos = corner_a.global_position
	var b_pos = corner_b.global_position
	var span_x = abs(a_pos.x - b_pos.x)
	var span_z = abs(a_pos.z - b_pos.z)
	var size = Vector2(max(span_x, 0.1), max(span_z, 0.1))

	var center = (a_pos + b_pos) * 0.5
	mesh_instance.global_position = Vector3(center.x, center.y, center.z)

	var plane := mesh_instance.mesh as PlaneMesh
	if plane == null:
		plane = PlaneMesh.new()
		mesh_instance.mesh = plane

	plane.size = size
	plane.subdivide_width = subdivisions
	plane.subdivide_depth = subdivisions

	var shader_material := mesh_instance.material_override as ShaderMaterial
	if shader_material != null:
		shader_material.set_shader_parameter("half_size", size * 0.5)
		shader_material.set_shader_parameter("bottom_depth", bottom_depth)
		shader_material.set_shader_parameter("curve_power", curve_power)
		shader_material.set_shader_parameter("top_color", top_color)
		shader_material.set_shader_parameter("bottom_color", bottom_color)
		shader_material.set_shader_parameter("banding_levels", banding_levels)
		shader_material.set_shader_parameter("dither_scale", dither_scale)
		shader_material.set_shader_parameter("dither_strength", dither_strength)

	_last_corner_a = a_pos
	_last_corner_b = b_pos
