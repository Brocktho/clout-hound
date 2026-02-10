@tool
extends Node3D

enum AxisDirection { X, Z }

const PLATFORM_NODE_NAME := "GeneratedGymPlatform"
const GRID_NODE_NAME := "GymGridOverlay"

@export_category("Gym Generator")
@export_range(0.05, 2.0, 0.01) var cube_size := 0.25
@export_range(1, 256, 1) var grid_width := 48
@export_range(1, 256, 1) var grid_depth := 48

@export_category("Gap Section")
@export var enable_gap_section := true
@export_range(1, 16, 1) var max_gap_size := 4
@export_range(1, 64, 1) var gap_section_width := 4
@export_range(1, 256, 1) var gap_section_length := 24
@export var gap_section_origin := Vector2i(4, 4)
@export var gap_direction := AxisDirection.Z
@export_range(0, 8, 1) var gap_spacing := 1

@export_category("Stairs Section")
@export var enable_stairs_section := true
@export_range(1, 12, 1) var max_step_height := 4
@export_range(1, 8, 1) var stairs_step_run := 2
@export_range(1, 64, 1) var stairs_section_width := 4
@export_range(1, 256, 1) var stairs_section_length := 24
@export var stairs_section_origin := Vector2i(4, 32)
@export var stairs_direction := AxisDirection.Z

@export_category("Grid Overlay")
@export var show_grid_overlay := true
@export var grid_line_color := Color(0.15, 0.85, 0.9, 0.35)
@export_range(0.0, 0.5, 0.01) var grid_height_offset := 0.01
@export var clear_before_generate := true
@export_tool_button("Generate Platform") var generate_button = _generate_platform


func _generate_platform() -> void:
	if clear_before_generate:
		_clear_platform()

	var occupancy := _build_occupancy_grid()
	var heights := _build_height_grid()

	var platform_root := Node3D.new()
	platform_root.name = PLATFORM_NODE_NAME
	add_child(platform_root)
	platform_root.owner = _get_scene_owner()

	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(cube_size, cube_size, cube_size)
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(cube_size, cube_size, cube_size)

	for x in range(grid_width):
		for z in range(grid_depth):
			if not occupancy[x][z]:
				continue
			var height_units : int = heights[x][z]
			var block := _create_block(box_mesh, box_shape)
			block.position = Vector3(
				(x + 0.5) * cube_size,
				(height_units + 0.5) * cube_size,
				(z + 0.5) * cube_size
			)
			platform_root.add_child(block)
			_set_owner_recursive(block, _get_scene_owner())

	if show_grid_overlay:
		var grid_overlay := _create_grid_overlay()
		platform_root.add_child(grid_overlay)
		grid_overlay.owner = _get_scene_owner()


func _clear_platform() -> void:
	var existing := get_node_or_null(PLATFORM_NODE_NAME)
	if existing:
		existing.queue_free()


func _create_block(box_mesh: BoxMesh, box_shape: BoxShape3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = box_mesh
	body.add_child(mesh_instance)

	var collider := CollisionShape3D.new()
	collider.shape = box_shape
	body.add_child(collider)
	return body


func _get_scene_owner() -> Node:
	var scene_owner := get_owner()
	return scene_owner if scene_owner else self


func _set_owner_recursive(node: Node, owner: Node) -> void:
	node.owner = owner
	for child in node.get_children():
		_set_owner_recursive(child, owner)


func _build_occupancy_grid() -> Array:
	var occupancy := []
	occupancy.resize(grid_width)
	for x in range(grid_width):
		occupancy[x] = []
		occupancy[x].resize(grid_depth)
		for z in range(grid_depth):
			occupancy[x][z] = true

	if enable_gap_section:
		_apply_gap_section(occupancy)

	return occupancy


func _build_height_grid() -> Array:
	var heights := []
	heights.resize(grid_width)
	for x in range(grid_width):
		heights[x] = []
		heights[x].resize(grid_depth)
		for z in range(grid_depth):
			heights[x][z] = 0

	if not enable_stairs_section or max_step_height <= 0:
		return heights

	_apply_stairs_section(heights)

	return heights


func _apply_gap_section(occupancy: Array) -> void:
	var origin_x : int = clamp(gap_section_origin.x, 0, grid_width - 1)
	var origin_z : int = clamp(gap_section_origin.y, 0, grid_depth - 1)
	var section_width : int = max(1, gap_section_width)
	var section_length : int = max(1, gap_section_length)
	var cursor := 0

	var step_index := 1
	while cursor < section_length:
		var gap_width : int = min(section_width, _gap_width_for_index(step_index))
		var gap_length : int= min(section_length - cursor, _gap_length_for_index(step_index))
		if gap_width <= 0 or gap_length <= 0:
			break
		var gap_start := cursor
		var gap_end : int = min(cursor + gap_length, section_length)
		cursor = gap_end + gap_spacing
		step_index += 1

		for w in range(gap_width):
			for l in range(gap_start, gap_end):
				var x := origin_x
				var z := origin_z
				if gap_direction == AxisDirection.X:
					x = origin_x + l
					z = origin_z + w
				else:
					x = origin_x + w
					z = origin_z + l
				if x < 0 or x >= grid_width or z < 0 or z >= grid_depth:
					continue
				occupancy[x][z] = false


func _apply_stairs_section(heights: Array) -> void:
	var origin_x : int = clamp(stairs_section_origin.x, 0, grid_width - 1)
	var origin_z : int = clamp(stairs_section_origin.y, 0, grid_depth - 1)
	var width : int = max(1, stairs_section_width)
	var length : int = max(1, stairs_section_length)
	var cursor := 0

	for step_height in range(1, max_step_height + 1):
		if cursor >= length:
			break
		var step_start := cursor
		var step_end : int = min(cursor + stairs_step_run, length)
		cursor = step_end

		for w in range(width):
			for l in range(step_start, step_end):
				var x := origin_x
				var z := origin_z
				if stairs_direction == AxisDirection.X:
					x = origin_x + l
					z = origin_z + w
				else:
					x = origin_x + w
					z = origin_z + l
				if x < 0 or x >= grid_width or z < 0 or z >= grid_depth:
					continue
				heights[x][z] = max(heights[x][z], step_height)


func _gap_width_for_index(index: int) -> int:
	return _gap_size_for_index(index).x


func _gap_length_for_index(index: int) -> int:
	return _gap_size_for_index(index).y


func _gap_size_for_index(index: int) -> Vector2i:
	var step_index : int = max(1, index)
	var length := int(ceil((sqrt(8.0 * step_index + 1.0) - 1.0) / 2.0))
	var base : int = int(length * (length - 1) / 2)
	var width := step_index - base
	return Vector2i(min(max_gap_size, width), min(max_gap_size, length))


func _create_grid_overlay() -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	st.set_color(grid_line_color)

	var y := grid_height_offset
	for x in range(grid_width + 1):
		var world_x := x * cube_size
		st.add_vertex(Vector3(world_x, y, 0.0))
		st.add_vertex(Vector3(world_x, y, grid_depth * cube_size))

	for z in range(grid_depth + 1):
		var world_z := z * cube_size
		st.add_vertex(Vector3(0.0, y, world_z))
		st.add_vertex(Vector3(grid_width * cube_size, y, world_z))

	st.index()
	st.commit(mesh)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = GRID_NODE_NAME
	mesh_instance.mesh = mesh
	mesh_instance.visible = show_grid_overlay
	return mesh_instance
