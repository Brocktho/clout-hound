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

func _ready() -> void:
	print_rich("[color=yellow]GrindRail: _ready called, Engine.is_editor_hint(): ", Engine.is_editor_hint(), "[/color]")

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
	return curve.get_closest_offset(to_local(world_pos))

func get_pos_at_offset(offset: float) -> Vector3:
	return to_global(curve.sample_baked(offset))

func get_direction_at_offset(offset: float) -> Vector3:
	# Approximate direction by sampling two points close together
	var p1 = curve.sample_baked(offset)
	var p2 = curve.sample_baked(offset + 0.1)
	return to_global(p2) - to_global(p1)
	
