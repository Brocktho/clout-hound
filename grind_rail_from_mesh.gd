@tool
extends MeshInstance3D
class_name GrindRailFromMesh

## Generates a Path3D by tracing a surface path and offsetting to the tube center.
## Works with imported meshes where vertex order is not ring-based.

enum PathMode { AUTO, OPEN, CLOSED }

@export var path_suffix: String = "Path3D"
@export var path_mode: PathMode = PathMode.AUTO
@export var point_spacing: float = 0.5
@export var max_points: int = 512
@export var raycast_max_distance: float = 0.0
@export var min_hit_distance: float = 0.01
@export var closed_edge_penalty: float = 10.0
@export var debug_logging: bool = false
@export var use_centerline_seed_y: bool = false
@export var centerline_seed_y: float = 0.0
@export var pipe_radius: float = 0.0

@export var generate_path_button: bool:
	set(value):
		if value:
			generate_path_from_mesh()
			generate_path_button = false

func generate_path_from_mesh() -> void:
	_generate_path_for_mesh_instance(self, {
		"path_suffix": path_suffix,
		"path_mode": path_mode,
		"point_spacing": point_spacing,
		"max_points": max_points,
		"raycast_max_distance": raycast_max_distance,
		"min_hit_distance": min_hit_distance,
		"closed_edge_penalty": closed_edge_penalty,
		"debug_logging": debug_logging,
		"use_centerline_seed_y": use_centerline_seed_y,
		"centerline_seed_y": centerline_seed_y,
		"pipe_radius": pipe_radius,
	})

static func generate_path_for_mesh_instance(mesh_instance: MeshInstance3D, options: Dictionary) -> void:
	var generator := GrindRailFromMesh.new()
	generator._generate_path_for_mesh_instance(mesh_instance, options)

func _generate_path_for_mesh_instance(mesh_instance: MeshInstance3D, options: Dictionary) -> void:
	if not mesh_instance or not mesh_instance.mesh:
		push_warning("GrindRailFromMesh: No mesh assigned.")
		return
	if not (mesh_instance.mesh is ArrayMesh):
		push_warning("GrindRailFromMesh: Mesh must be an ArrayMesh.")
		return
	if mesh_instance.mesh.get_surface_count() == 0:
		push_warning("GrindRailFromMesh: Mesh has no surfaces.")
		return

	var debug: bool = options.get("debug_logging", debug_logging)
	if debug:
		print("GrindRailFromMesh: Generating for ", mesh_instance.name, " surface_count=", mesh_instance.mesh.get_surface_count())

	options["mesh_global_transform"] = mesh_instance.global_transform

	var target_name: String = options.get("path_name", "")
	if target_name.is_empty():
		var suffix = options.get("path_suffix", path_suffix)
		target_name = mesh_instance.name + "_" + suffix
	var path = _find_or_create_path(mesh_instance, target_name)
	if not path:
		push_warning("GrindRailFromMesh: Could not create Path3D.")
		return

	var result = _build_centerline(mesh_instance.mesh, options)
	var points: PackedVector3Array = result.get("points", PackedVector3Array())
	var closed: bool = result.get("closed", false)
	if points.is_empty():
		push_warning("GrindRailFromMesh: No centerline points generated.")
		return

	var curve := Curve3D.new()
	for p in points:
		curve.add_point(p)

	if closed and curve.get_point_count() > 1:
		var first = curve.get_point_position(0)
		var last = curve.get_point_position(curve.get_point_count() - 1)
		if first.distance_to(last) < 0.001:
			curve.remove_point(curve.get_point_count() - 1)
		curve.closed = true

	path.curve = curve

func _find_or_create_path(mesh_instance: MeshInstance3D, target_name: String) -> Path3D:
	var parent = mesh_instance.get_parent()
	var path: Path3D = null
	if parent:
		var existing = parent.get_node_or_null(target_name)
		if existing and existing is Path3D:
			path = existing
		elif existing:
			existing.free()
	if not path:
		path = Path3D.new()
		path.name = target_name
		if parent:
			parent.add_child(path)
		else:
			mesh_instance.add_child(path)
		var rail_script = load("res://grind_rail.gd")
		if rail_script:
			path.set_script(rail_script)

	var root = get_tree().edited_scene_root if Engine.is_editor_hint() else mesh_instance
	if not root:
		root = mesh_instance
	path.owner = root

	path.global_transform = mesh_instance.global_transform
	return path

func _build_centerline(array_mesh: ArrayMesh, options: Dictionary) -> Dictionary:
	var point_spacing_val: float = options.get("point_spacing", 0.5)
	var max_points_val: int = options.get("max_points", 512)
	var raycast_max: float = options.get("raycast_max_distance", 0.0)
	var min_hit: float = options.get("min_hit_distance", 0.01)
	var penalty: float = options.get("closed_edge_penalty", 10.0)
	var mode: int = options.get("path_mode", PathMode.AUTO)
	var debug: bool = options.get("debug_logging", debug_logging)
	var use_seed: bool = options.get("use_centerline_seed_y", false)
	var seed_y: float = options.get("centerline_seed_y", 0.0)
	var pipe_radius_val: float = options.get("pipe_radius", 0.0)
	var mesh_transform: Transform3D = options.get("mesh_global_transform", Transform3D.IDENTITY)

	var mdt := MeshDataTool.new()
	if mdt.create_from_surface(array_mesh, 0) != OK:
		if debug:
			print("GrindRailFromMesh: MeshDataTool failed to read surface 0")
		return {"points": PackedVector3Array(), "closed": false}

	var triangles = _get_surface_triangles(array_mesh, 0)
	if triangles.is_empty():
		if debug:
			print("GrindRailFromMesh: No triangles found in surface 0")
		return {"points": PackedVector3Array(), "closed": false}

	if debug:
		print("GrindRailFromMesh: vertex_count=", mdt.get_vertex_count(), " edge_count=", mdt.get_edge_count(), " triangle_count=", triangles.size())

	var vertex_count = mdt.get_vertex_count()
	var adjacency: Array = []
	adjacency.resize(vertex_count)
	for i in range(vertex_count):
		adjacency[i] = {}

	var boundary_adjacency: Dictionary = {}
	for edge_idx in range(mdt.get_edge_count()):
		var a = mdt.get_edge_vertex(edge_idx, 0)
		var b = mdt.get_edge_vertex(edge_idx, 1)
		var dist = mdt.get_vertex(a).distance_to(mdt.get_vertex(b))
		adjacency[a][b] = dist
		adjacency[b][a] = dist

		var faces := mdt.get_edge_faces(edge_idx)
		if faces.size() < 2:
			if not boundary_adjacency.has(a):
				boundary_adjacency[a] = []
			if not boundary_adjacency.has(b):
				boundary_adjacency[b] = []
			boundary_adjacency[a].append(b)
			boundary_adjacency[b].append(a)

	var closed_mesh = boundary_adjacency.is_empty()
	if debug:
		print("GrindRailFromMesh: boundary_edge_vertices=", boundary_adjacency.size(), " closed_mesh=", closed_mesh, " mode=", mode)

	var allowed: Dictionary = {}
	var seed_idx = -1
	if use_seed:
		seed_idx = _find_seed_vertex(mdt, mesh_transform, seed_y)
		if seed_idx >= 0:
			allowed = _collect_component_vertices(adjacency, seed_idx)
		if debug:
			print("GrindRailFromMesh: seed_y=", seed_y, " seed_idx=", seed_idx, " component_vertices=", allowed.size())

	var path_vertices: Array = []
	if mode == PathMode.OPEN:
		closed_mesh = false

	if not closed_mesh:
		var loops = _collect_boundary_loops(boundary_adjacency)
		if debug:
			print("GrindRailFromMesh: boundary_loops=", loops.size())
		if loops.size() >= 2:
			var loop_a = loops[0]
			var loop_b = loops[1]
			if use_seed and allowed.size() > 0:
				var filtered = _filter_loops_by_component(loops, allowed)
				if filtered.size() >= 2:
					loop_a = filtered[0]
					loop_b = filtered[1]
			var start_idx = _nearest_vertex_to_centroid(mdt, loop_a)
			var end_idx = _nearest_vertex_to_centroid(mdt, loop_b)
			if debug:
				print("GrindRailFromMesh: open path start=", start_idx, " end=", end_idx)
			path_vertices = _shortest_path(adjacency, start_idx, end_idx, {}, allowed)
		else:
			if mode == PathMode.CLOSED:
				closed_mesh = true
			else:
				var endpoints = _graph_diameter_endpoints(adjacency, allowed)
				if debug:
					print("GrindRailFromMesh: fallback diameter endpoints=", endpoints[0], " ", endpoints[1])
				path_vertices = _shortest_path(adjacency, endpoints[0], endpoints[1], {}, allowed)
				closed_mesh = false

	if closed_mesh or mode == PathMode.CLOSED:
		var endpoints = _graph_diameter_endpoints(adjacency, allowed)
		var a_idx = endpoints[0]
		var b_idx = endpoints[1]
		if debug:
			print("GrindRailFromMesh: closed path endpoints=", a_idx, " ", b_idx)
		var path_a = _shortest_path(adjacency, a_idx, b_idx, {}, allowed)
		var penalty_edges: Dictionary = {}
		for i in range(path_a.size() - 1):
			penalty_edges[_edge_key(path_a[i], path_a[i + 1])] = penalty
		var path_b = _shortest_path(adjacency, a_idx, b_idx, penalty_edges, allowed)
		if debug:
			print("GrindRailFromMesh: path_a=", path_a.size(), " path_b=", path_b.size())
		if path_b.is_empty():
			path_vertices = path_a
		else:
			var reverse_b: Array = path_b.duplicate()
			reverse_b.reverse()
			path_vertices = path_a
			for i in range(1, reverse_b.size() - 1):
				path_vertices.append(reverse_b[i])

	var points: PackedVector3Array = []
	points.resize(0)
	if path_vertices.is_empty():
		if debug:
			print("GrindRailFromMesh: No path vertices after shortest path")
		return {"points": points, "closed": closed_mesh}

	var max_dist = raycast_max
	if max_dist <= 0.0:
		var aabb = array_mesh.get_aabb()
		max_dist = aabb.size.length() * 1.5
	if debug:
		print("GrindRailFromMesh: raycast_max_distance=", max_dist, " point_spacing=", point_spacing_val, " max_points=", max_points_val)

	var last_added := Vector3(INF, INF, INF)
	var raycast_failures = 0
	for idx in path_vertices:
		var surface_pos = mdt.get_vertex(idx)
		var normal = _get_vertex_normal(mdt, idx)
		if normal.length() < 0.001:
			if debug:
				print("GrindRailFromMesh: zero normal at vertex ", idx)
			continue
		normal = normal.normalized()
		var center = _compute_center_point(surface_pos, normal, triangles, max_dist, min_hit, pipe_radius_val, array_mesh.get_aabb())
		if debug and center == surface_pos:
			raycast_failures += 1
		if last_added.x == INF or center.distance_to(last_added) >= point_spacing_val:
			points.append(center)
			last_added = center
			if points.size() >= max_points_val:
				break

	if debug:
		print("GrindRailFromMesh: points_generated=", points.size(), " raycast_failures=", raycast_failures)
	return {"points": points, "closed": closed_mesh}

func _get_surface_triangles(array_mesh: ArrayMesh, surface_idx: int) -> Array:
	var arrays = array_mesh.surface_get_arrays(surface_idx)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var triangles: Array = []
	if indices.is_empty():
		for i in range(0, vertices.size(), 3):
			triangles.append([vertices[i], vertices[i + 1], vertices[i + 2]])
	else:
		for i in range(0, indices.size(), 3):
			triangles.append([vertices[indices[i]], vertices[indices[i + 1]], vertices[indices[i + 2]]])
	return triangles

func _collect_boundary_loops(boundary_adjacency: Dictionary) -> Array:
	var loops: Array = []
	var visited: Dictionary = {}
	for start_idx in boundary_adjacency.keys():
		if visited.has(start_idx):
			continue
		var loop: Array = []
		var stack: Array = [start_idx]
		visited[start_idx] = true
		while not stack.is_empty():
			var current = stack.pop_back()
			loop.append(current)
			for neighbor in boundary_adjacency[current]:
				if not visited.has(neighbor):
					visited[neighbor] = true
					stack.append(neighbor)
		loops.append(loop)
	return loops

func _nearest_vertex_to_centroid(mdt: MeshDataTool, loop_vertices: Array) -> int:
	var center := Vector3.ZERO
	for idx in loop_vertices:
		center += mdt.get_vertex(idx)
	center /= float(loop_vertices.size())

	var best_idx = loop_vertices[0]
	var best_dist = INF
	for idx in loop_vertices:
		var dist = center.distance_to(mdt.get_vertex(idx))
		if dist < best_dist:
			best_dist = dist
			best_idx = idx
	return best_idx

#func _graph_diameter_endpoints(adjacency: Array) -> PackedInt32Array:
#	var first = _farthest_vertex(adjacency, 0, {})
#	var second = _farthest_vertex(adjacency, first, {})
#	return PackedInt32Array([first, second])

func _graph_diameter_endpoints(adjacency: Array, allowed: Dictionary) -> PackedInt32Array:
	var first = _farthest_vertex(adjacency, 0, allowed)
	var second = _farthest_vertex(adjacency, first, allowed)
	return PackedInt32Array([first, second])

func _farthest_vertex(adjacency: Array, start_idx: int, allowed: Dictionary) -> int:
	var result = _dijkstra(adjacency, start_idx, {}, allowed)
	var distances: PackedFloat32Array = result["distances"]
	var farthest = start_idx
	var best = -INF
	for i in range(distances.size()):
		if allowed.size() > 0 and not allowed.has(i):
			continue
		if distances[i] > best and distances[i] < INF * 0.5:
			best = distances[i]
			farthest = i
	return farthest

func _shortest_path(adjacency: Array, start_idx: int, end_idx: int, penalties: Dictionary, allowed: Dictionary) -> Array:
	var result = _dijkstra(adjacency, start_idx, penalties, allowed)
	var prev: PackedInt32Array = result["previous"]
	var path: Array = []
	var current = end_idx
	while current != -1:
		path.append(current)
		if current == start_idx:
			break
		current = prev[current]
	path.reverse()
	if path.is_empty() or path[0] != start_idx:
		return []
	return path

func _dijkstra(adjacency: Array, start_idx: int, penalties: Dictionary, allowed: Dictionary) -> Dictionary:
	var n = adjacency.size()
	var distances := PackedFloat32Array()
	distances.resize(n)
	var previous := PackedInt32Array()
	previous.resize(n)
	var visited := PackedByteArray()
	visited.resize(n)

	for i in range(n):
		distances[i] = INF
		previous[i] = -1
		visited[i] = 0
		if allowed.size() > 0 and not allowed.has(i):
			visited[i] = 1
	distances[start_idx] = 0.0

	for _i in range(n):
		var u = -1
		var best = INF
		for j in range(n):
			if visited[j] == 0 and distances[j] < best:
				best = distances[j]
				u = j
		if u == -1:
			break
		visited[u] = 1
		for v in adjacency[u].keys():
			if allowed.size() > 0 and not allowed.has(v):
				continue
			var weight = adjacency[u][v]
			var key = _edge_key(u, v)
			if penalties.has(key):
				weight *= penalties[key]
			var alt = distances[u] + weight
			if alt < distances[v]:
				distances[v] = alt
				previous[v] = u

	return {"distances": distances, "previous": previous}

func _edge_key(a: int, b: int) -> String:
	if a < b:
		return str(a) + ":" + str(b)
	return str(b) + ":" + str(a)

func _get_vertex_normal(mdt: MeshDataTool, idx: int) -> Vector3:
	var normal = mdt.get_vertex_normal(idx)
	if normal.length() > 0.001:
		return normal

	var faces = mdt.get_vertex_faces(idx)
	var accumulated := Vector3.ZERO
	for face_idx in faces:
		accumulated += mdt.get_face_normal(face_idx)
	if accumulated.length() > 0.001:
		return accumulated.normalized()
	return Vector3.ZERO

func _compute_center_point(surface_pos: Vector3, normal: Vector3, triangles: Array, max_dist: float, min_hit: float, pipe_radius_val: float, aabb: AABB) -> Vector3:
	if pipe_radius_val > 0.0:
		var inward = surface_pos - normal * pipe_radius_val
		var outward = surface_pos + normal * pipe_radius_val
		var center_guess = aabb.position + aabb.size * 0.5
		if inward.distance_to(center_guess) <= outward.distance_to(center_guess):
			return inward
		return outward

	var eps = 0.001
	var hit_forward = _segment_hit(surface_pos + normal * eps, surface_pos + normal * max_dist, triangles, min_hit)
	var hit_backward = _segment_hit(surface_pos - normal * eps, surface_pos - normal * max_dist, triangles, min_hit)

	if hit_forward == null and hit_backward == null:
		return surface_pos

	if hit_forward != null and hit_backward != null:
		var dist_forward = surface_pos.distance_to(hit_forward)
		var dist_backward = surface_pos.distance_to(hit_backward)
		var hit_loc = hit_forward if dist_forward > dist_backward else hit_backward
		return (surface_pos + hit_loc) * 0.5

	var hit = hit_forward if hit_forward != null else hit_backward
	return (surface_pos + hit) * 0.5

func _find_seed_vertex(mdt: MeshDataTool, mesh_transform: Transform3D, seed_y: float) -> int:
	var best_idx = -1
	var best_delta = INF
	for i in range(mdt.get_vertex_count()):
		var global_v = mesh_transform * mdt.get_vertex(i)
		var delta = abs(global_v.y - seed_y)
		if delta < best_delta:
			best_delta = delta
			best_idx = i
	return best_idx

func _collect_component_vertices(adjacency: Array, start_idx: int) -> Dictionary:
	var allowed: Dictionary = {}
	if start_idx < 0:
		return allowed
	var stack: Array = [start_idx]
	allowed[start_idx] = true
	while not stack.is_empty():
		var current = stack.pop_back()
		for neighbor in adjacency[current].keys():
			if not allowed.has(neighbor):
				allowed[neighbor] = true
				stack.append(neighbor)
	return allowed

func _filter_loops_by_component(loops: Array, allowed: Dictionary) -> Array:
	var filtered: Array = []
	for loop in loops:
		for idx in loop:
			if allowed.has(idx):
				filtered.append(loop)
				break
	return filtered

func _segment_hit(from: Vector3, to: Vector3, triangles: Array, min_hit: float) -> Variant:
	var best_dist = INF
	var best_hit = null
	for tri in triangles:
		var hit = Geometry3D.segment_intersects_triangle(from, to, tri[0], tri[1], tri[2])
		if hit != null:
			var dist = from.distance_to(hit)
			if dist > min_hit and dist < best_dist:
				best_dist = dist
				best_hit = hit
	return best_hit
