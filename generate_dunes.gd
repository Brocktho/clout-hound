@tool
extends Node3D

@export var size: Vector2 = Vector2(200, 200)
@export var subdivisions: int = 150
@export var height_scale: float = 4.0
@export var noise_frequency: float = 0.01
@export var noise_seed: int = 0
@export var noise_type: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_PERLIN
@export var fractal_type: FastNoiseLite.FractalType = FastNoiseLite.FRACTAL_FBM
@export var fractal_octaves: int = 5
@export var color: Color = Color(0.95, 0.85, 0.5) # Sand color
@export var texture: Texture2D = preload("res://GridTexture.tres")
@export var uv_scale: Vector3 = Vector3(0.1, 0.1, 0.1)

@export var generate_now: bool = false:
	set(value):
		generate_dunes()

func _ready() -> void:
	if not Engine.is_editor_hint():
		generate_dunes()

func generate_dunes() -> void:
	# Clean up previous generation
	for child in get_children():
		if child.name == "GeneratedDunesMesh":
			child.free() # Use free() in tool script to avoid accumulation before next frame
	
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = size
	plane_mesh.subdivide_depth = subdivisions
	plane_mesh.subdivide_width = subdivisions
	
	var noise = FastNoiseLite.new()
	noise.seed = noise_seed if noise_seed != 0 else randi()
	noise.frequency = noise_frequency # Adjust for smoothness
	noise.noise_type = noise_type
	noise.fractal_type = fractal_type
	noise.fractal_octaves = fractal_octaves
	
	var st = SurfaceTool.new()
	st.create_from(plane_mesh, 0)
	
	var array_mesh = st.commit()
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(array_mesh, 0)
	
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i)
		# Use X and Z for noise to get Y
		var noise_val = noise.get_noise_2d(vertex.x, vertex.z)
		vertex.y = noise_val * height_scale
		mdt.set_vertex(i, vertex)
	
	array_mesh.clear_surfaces()
	mdt.commit_to_surface(array_mesh)
	
	# Recalculate normals for smooth shading
	var st_final = SurfaceTool.new()
	st_final.create_from(array_mesh, 0)
	st_final.generate_normals()
	array_mesh = st_final.commit()
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "GeneratedDunesMesh"
	mesh_instance.mesh = array_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	if texture:
		material.albedo_texture = texture
		material.uv1_triplanar = true
		material.uv1_scale = uv_scale
	material.roughness = 1.0 # Less shiny for sand
	mesh_instance.material_override = material
	
	add_child(mesh_instance)
	if Engine.is_editor_hint() and get_tree():
		var root = get_tree().edited_scene_root
		if root:
			mesh_instance.owner = root
	
	# Create collision
	mesh_instance.create_trimesh_collision()
	# The collision child also needs owner if we want it to persist
	if Engine.is_editor_hint() and get_tree():
		var root = get_tree().edited_scene_root
		if root:
			for child in mesh_instance.get_children():
				child.owner = root
				for grandchild in child.get_children():
					grandchild.owner = root


