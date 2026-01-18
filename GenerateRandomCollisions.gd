extends Node3D

@export var obstacle_count: int = 50
@export var spawn_area: float = 40.0

func _ready() -> void:
	spawn_obstacles()

func spawn_obstacles() -> void:
	for i in range(obstacle_count):
		var mesh_instance = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		
		# Give them random sizes so they look like a "test level"
		box_mesh.size = Vector3(randf_range(1, 3), randf_range(0.5, 4), randf_range(1, 3))
		mesh_instance.mesh = box_mesh
		
		# Position them randomly on the plane
		var random_pos = Vector3(
			randf_range(-spawn_area, spawn_area),
			box_mesh.size.y / 2.0, # Sit on top of the floor
			randf_range(-spawn_area, spawn_area)
		)
		mesh_instance.position = random_pos
		
		# Add a simple color so they aren't just white
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(randf(), randf(), randf())
		mesh_instance.material_override = material
		
		# Add collision so you can actually bump into them
		mesh_instance.create_trimesh_collision()
		
		add_child(mesh_instance)
