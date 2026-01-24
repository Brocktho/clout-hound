@tool
extends Node
class_name GrindRailBatch

## Generates Path3D nodes for all MeshInstance3D nodes with a name prefix.

@export var name_prefix: String = "GR_"
@export var path_suffix: String = "_Path3D"
@export var path_mode: GrindRailFromMesh.PathMode = GrindRailFromMesh.PathMode.OPEN
@export var point_spacing: float = 0.5
@export var max_points: int = 512
@export var raycast_max_distance: float = 0.0
@export var min_hit_distance: float = 0.01
@export var closed_edge_penalty: float = 10.0

@export var generate_paths_button: bool:
	set(value):
		if value:
			generate_paths()
			generate_paths_button = false

func generate_paths() -> void:
	var root = get_tree().edited_scene_root if Engine.is_editor_hint() else self
	if not root:
		push_warning("GrindRailBatch: No scene root found.")
		return

	var meshes: Array = []
	_collect_meshes(root, meshes)

	for mesh_instance in meshes:
		if not mesh_instance.name.begins_with(name_prefix):
			continue
		if not mesh_instance.mesh:
			continue
		var options = {
			"path_name": mesh_instance.name + path_suffix,
			"path_mode": path_mode,
			"point_spacing": point_spacing,
			"max_points": max_points,
			"raycast_max_distance": raycast_max_distance,
			"min_hit_distance": min_hit_distance,
			"closed_edge_penalty": closed_edge_penalty,
		}
		GrindRailFromMesh.generate_path_for_mesh_instance(mesh_instance, options)

func _collect_meshes(node: Node, meshes: Array) -> void:
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		_collect_meshes(child, meshes)
