@tool
extends Path3D
class_name GrindRail

## GrindRail System
## 
## To use:
## 1. Place a Path3D in the scene and attach this script.
## 2. Create a Curve3D for the path.
## 3. Use the "Generate Rail" button in the inspector to create the collision and mesh.
##    This will create a StaticBody3D for physics and a MeshInstance3D for visibility.

@export var speed_maintenance: float = 1.0 # Factor to maintain speed
@export var rail_radius: float = 0.2 # Radius of the collision cylinder
@export var collision_segments: int = 8 # Number of sides for the cylinder approximation
@export var rail_material: Material # Material for the visible rail

@export var generate_rail_button: bool:
	set(value):
		# We use print_rich for more visible logging in editor
		print_rich("[color=green]GrindRail: Button pressed, value: ", value, "[/color]")
		if value:
			generate_rail()
			# Reset the button so it can be pressed again
			generate_rail_button = false

var _cached_global_points: PackedVector3Array = PackedVector3Array()
var _cached_global_distances: PackedFloat32Array = PackedFloat32Array()
var _cached_point_count: int = -1
var _cached_bake_interval: float = -1.0
var _cached_baked_length: float = -1.0
var _cached_transform: Transform3D = Transform3D.IDENTITY


func generate_rail() -> void:
	print_rich("[color=cyan]GrindRail: generate_rail() started[/color]")
	if not curve:
		push_warning("GrindRail: No curve defined.")
		return
	
	# Clean up existing generated nodes if any
	for child in get_children():
		if child.name == "GeneratedCollision" or child.name == "GeneratedMesh":
			print("GrindRail: Cleaning up old node: ", child.name)
			child.free()
	
	var static_body = StaticBody3D.new()
	static_body.name = "GeneratedCollision"
	add_child(static_body)
	
	var collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	static_body.add_child(collision_shape)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "GeneratedMesh"
	add_child(mesh_instance)
	
	# Set owner for editor persistence
	var root = get_tree().edited_scene_root if Engine.is_editor_hint() else self
	if not root:
		root = self
	print("GrindRail: root for persistence is ", root)
	
	static_body.owner = root
	collision_shape.owner = root
	mesh_instance.owner = root
	
	# Generate a mesh that follows the path
	var mesh = _generate_rail_mesh()
	if mesh:
		collision_shape.shape = mesh.create_trimesh_shape()
		print("GrindRail: Trimesh shape created from mesh")
		
		mesh_instance.mesh = mesh
		if rail_material:
			mesh_instance.material_override = rail_material
		print("GrindRail: MeshInstance3D updated")
	else:
		push_error("GrindRail: Failed to generate mesh")
	
	print("GrindRail: Rail generated for ", name)

func _generate_rail_mesh() -> ArrayMesh:
	var path_length = curve.get_baked_length()
	print("GrindRail: path_length = ", path_length)
	if path_length < 0.1:
		return null
		
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var interval = 0.5 # Distance between segments along the path
	var steps = ceil(path_length / interval)
	
	for i in range(steps + 1):
		var offset = min(i * interval, path_length)
		var transform_at_path = _get_path_transform(offset)
		
		# Create a circle of vertices at this step
		for j in range(collision_segments):
			var angle = j * TAU / collision_segments
			var vertex = Vector3(cos(angle) * rail_radius, sin(angle) * rail_radius, 0)
			var world_vertex = transform_at_path * vertex
			
			st.set_uv(Vector2(float(j) / collision_segments, offset / path_length))
			st.add_vertex(world_vertex)
			
		# Connect to previous circle with triangles
		if i > 0:
			for j in range(collision_segments):
				var next_j = (j + 1) % collision_segments
				
				var curr_circle_start = i * collision_segments
				var prev_circle_start = (i - 1) * collision_segments
				
				# Two triangles for each quad segment
				st.add_index(prev_circle_start + j)
				st.add_index(curr_circle_start + j)
				st.add_index(curr_circle_start + next_j)
				
				st.add_index(prev_circle_start + j)
				st.add_index(curr_circle_start + next_j)
				st.add_index(prev_circle_start + next_j)
				
	st.generate_normals()
	return st.commit()

func _get_path_transform(offset: float) -> Transform3D:
	var pos = curve.sample_baked(offset)
	var forward = Vector3.FORWARD
	
	if offset + 0.1 <= curve.get_baked_length():
		forward = (curve.sample_baked(offset + 0.1) - pos).normalized()
	elif offset - 0.1 >= 0:
		forward = (pos - curve.sample_baked(offset - 0.1)).normalized()
		
	var up = Vector3.UP
	if abs(forward.dot(Vector3.UP)) > 0.99:
		up = Vector3.RIGHT
		
	var right = up.cross(forward).normalized()
	up = forward.cross(right).normalized()
	
	return Transform3D(Basis(right, up, forward), pos)

func get_closest_offset(world_pos: Vector3) -> float:
	_ensure_baked_cache()
	var count = _cached_global_points.size()
	if count == 0:
		return 0.0
	if count == 1:
		return 0.0

	var best_offset := 0.0
	var best_dist_sq := INF
	for i in range(1, count):
		var a = _cached_global_points[i - 1]
		var b = _cached_global_points[i]
		var seg = b - a
		var seg_len_sq = seg.length_squared()
		var t := 0.0
		if seg_len_sq > 0.0:
			t = clamp((world_pos - a).dot(seg) / seg_len_sq, 0.0, 1.0)
		var proj = a + seg * t
		var dist_sq = world_pos.distance_squared_to(proj)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			var seg_len = sqrt(seg_len_sq)
			best_offset = _cached_global_distances[i - 1] + seg_len * t
	return best_offset

func get_pos_at_offset(offset: float) -> Vector3:
	_ensure_baked_cache()
	var count = _cached_global_points.size()
	if count == 0:
		return global_position
	if count == 1:
		return _cached_global_points[0]

	var total_length = _cached_global_distances[count - 1]
	if total_length <= 0.0:
		return _cached_global_points[0]

	var clamped = clamp(offset, 0.0, total_length)
	var idx = _find_distance_index(clamped)
	if idx <= 0:
		return _cached_global_points[0]

	var prev_dist = _cached_global_distances[idx - 1]
	var next_dist = _cached_global_distances[idx]
	var t := 0.0
	if next_dist > prev_dist:
		t = (clamped - prev_dist) / (next_dist - prev_dist)
	return _cached_global_points[idx - 1].lerp(_cached_global_points[idx], t)

func get_direction_at_offset(offset: float) -> Vector3:
	# Approximate direction by sampling two points close together in world space.
	var total_length = get_rail_length()
	if total_length <= 0.0:
		return Vector3.FORWARD

	var sample_dist = min(0.1, total_length * 0.01)
	if sample_dist <= 0.0:
		return Vector3.FORWARD

	var p1: Vector3
	var p2: Vector3
	if offset + sample_dist <= total_length:
		p1 = get_pos_at_offset(offset)
		p2 = get_pos_at_offset(offset + sample_dist)
	else:
		p1 = get_pos_at_offset(max(0.0, offset - sample_dist))
		p2 = get_pos_at_offset(offset)
	return p2 - p1

func get_rail_radius() -> float:
	return rail_radius

func get_rail_length() -> float:
	_ensure_baked_cache()
	if _cached_global_distances.is_empty():
		return 0.0
	return _cached_global_distances[_cached_global_distances.size() - 1]

func _ensure_baked_cache() -> void:
	if not curve:
		_cached_global_points = PackedVector3Array()
		_cached_global_distances = PackedFloat32Array()
		_cached_point_count = 0
		_cached_bake_interval = 0.0
		_cached_baked_length = 0.0
		_cached_transform = global_transform
		return

	var baked_points = curve.get_baked_points()
	var bake_interval = curve.bake_interval
	var baked_length = curve.get_baked_length()
	var needs_update = baked_points.size() != _cached_point_count \
		or _cached_transform != global_transform \
		or not is_equal_approx(bake_interval, _cached_bake_interval) \
		or not is_equal_approx(baked_length, _cached_baked_length)

	if not needs_update:
		return

	_cached_point_count = baked_points.size()
	_cached_bake_interval = bake_interval
	_cached_baked_length = baked_length
	_cached_transform = global_transform

	_cached_global_points = PackedVector3Array()
	_cached_global_distances = PackedFloat32Array()
	if baked_points.is_empty():
		return

	_cached_global_points.resize(baked_points.size())
	_cached_global_distances.resize(baked_points.size())
	_cached_global_points[0] = global_transform * baked_points[0]
	_cached_global_distances[0] = 0.0
	for i in range(1, baked_points.size()):
		_cached_global_points[i] = global_transform * baked_points[i]
		_cached_global_distances[i] = _cached_global_distances[i - 1] + _cached_global_points[i - 1].distance_to(_cached_global_points[i])

func _find_distance_index(distance: float) -> int:
	var count = _cached_global_distances.size()
	if count < 2:
		return 0

	var low = 1
	var high = count - 1
	while low <= high:
		var mid = (low + high) / 2
		if _cached_global_distances[mid] < distance:
			low = mid + 1
		else:
			high = mid - 1
	return low
	
