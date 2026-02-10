@tool
extends EditorPlugin

enum ToolMode { NONE, PAINT_MATERIAL, PLACE_LABEL, DELETE_MESH, PLACE_MESH, PLACE_SLOPE }

const RAY_LENGTH := 5000.0
const GRID_SIZE := 0.5
const DRAG_SCREEN_THRESHOLD := 8.0
const DRAG_AXIS_DOMINANCE := 1.3
const DRAG_RETARGET_THRESHOLD := 60.0
const PREVIEW_NODE_NAME := "GymSlopePreview"

var _dock: VBoxContainer
var _left_action_picker: OptionButton
var _right_action_picker: OptionButton
var _material_picker: EditorResourcePicker
var _mesh_picker: EditorResourcePicker
var _place_material_picker: EditorResourcePicker
var _slope_angle: SpinBox
var _place_offset_x: SpinBox
var _place_offset_y: SpinBox
var _place_offset_z: SpinBox
var _label_text: LineEdit
var _label_size: SpinBox
var _label_color: ColorPickerButton
var _label_height_offset: SpinBox

var _dragging := false
var _drag_button := 0
var _drag_locked_y := 0.0
var _drag_last_cell := Vector3i.ZERO
var _drag_start_screen := Vector2.ZERO
var _drag_anchor_screen := Vector2.ZERO
var _slope_rotation := 0


func _enter_tree() -> void:
	_build_dock()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)
	print("Gym Tools: plugin loaded.")
	if has_method("set_input_event_forwarding_always_enabled"):
		set_input_event_forwarding_always_enabled()


func _exit_tree() -> void:
	if _dock:
		remove_control_from_docks(_dock)
		_dock.free()


func _build_dock() -> void:
	_dock = VBoxContainer.new()
	_dock.name = "Gym Tools"

	var title := Label.new()
	title.text = "Gym Tools"
	_dock.add_child(title)

	var left_label := Label.new()
	left_label.text = "Left Click Action"
	_dock.add_child(left_label)

	_left_action_picker = OptionButton.new()
	_left_action_picker.add_item("None", ToolMode.NONE)
	_left_action_picker.add_item("Paint Material", ToolMode.PAINT_MATERIAL)
	_left_action_picker.add_item("Place Label", ToolMode.PLACE_LABEL)
	_left_action_picker.add_item("Delete Mesh", ToolMode.DELETE_MESH)
	_left_action_picker.add_item("Place Mesh", ToolMode.PLACE_MESH)
	_left_action_picker.add_item("Place Slope", ToolMode.PLACE_SLOPE)
	_left_action_picker.selected = 1
	_dock.add_child(_left_action_picker)

	var right_label := Label.new()
	right_label.text = "Right Click Action"
	_dock.add_child(right_label)

	_right_action_picker = OptionButton.new()
	_right_action_picker.add_item("None", ToolMode.NONE)
	_right_action_picker.add_item("Paint Material", ToolMode.PAINT_MATERIAL)
	_right_action_picker.add_item("Place Label", ToolMode.PLACE_LABEL)
	_right_action_picker.add_item("Delete Mesh", ToolMode.DELETE_MESH)
	_right_action_picker.add_item("Place Mesh", ToolMode.PLACE_MESH)
	_right_action_picker.add_item("Place Slope", ToolMode.PLACE_SLOPE)
	_right_action_picker.selected = 2
	_dock.add_child(_right_action_picker)

	var material_label := Label.new()
	material_label.text = "Material"
	_dock.add_child(material_label)

	_material_picker = EditorResourcePicker.new()
	_material_picker.base_type = "Material"
	_material_picker.editable = true
	_dock.add_child(_material_picker)

	var mesh_label := Label.new()
	mesh_label.text = "Place Mesh (PackedScene)"
	_dock.add_child(mesh_label)

	_mesh_picker = EditorResourcePicker.new()
	_mesh_picker.base_type = "PackedScene"
	_mesh_picker.editable = true
	_dock.add_child(_mesh_picker)

	var place_material_label := Label.new()
	place_material_label.text = "Place Mesh Material"
	_dock.add_child(place_material_label)

	_place_material_picker = EditorResourcePicker.new()
	_place_material_picker.base_type = "Material"
	_place_material_picker.editable = true
	_dock.add_child(_place_material_picker)

	var slope_label := Label.new()
	slope_label.text = "Slope Angle"
	_dock.add_child(slope_label)

	_slope_angle = SpinBox.new()
	_slope_angle.min_value = 5.0
	_slope_angle.max_value = 85.0
	_slope_angle.step = 0.5
	_slope_angle.value = 30.0
	_slope_angle.suffix = " deg"
	_dock.add_child(_slope_angle)

	var offset_label := Label.new()
	offset_label.text = "Place Mesh Grid Offset"
	_dock.add_child(offset_label)

	var offset_row := HBoxContainer.new()
	_dock.add_child(offset_row)

	_place_offset_x = SpinBox.new()
	_place_offset_x.min_value = -10.0
	_place_offset_x.max_value = 10.0
	_place_offset_x.step = 0.01
	_place_offset_x.value = 0
	_place_offset_x.suffix = " x"
	offset_row.add_child(_place_offset_x)

	_place_offset_y = SpinBox.new()
	_place_offset_y.min_value = -10.0
	_place_offset_y.max_value = 10.0
	_place_offset_y.step = 0.01
	_place_offset_y.value = 0
	_place_offset_y.suffix = " y"
	offset_row.add_child(_place_offset_y)

	_place_offset_z = SpinBox.new()
	_place_offset_z.min_value = -10.0
	_place_offset_z.max_value = 10.0
	_place_offset_z.step = 0.01
	_place_offset_z.value = 0
	_place_offset_z.suffix = " z"
	offset_row.add_child(_place_offset_z)

	var label_title := Label.new()
	label_title.text = "Label Settings"
	_dock.add_child(label_title)

	_label_text = LineEdit.new() 
	_label_text.placeholder_text = "Label text"
	_label_text.text = "TODO"
	_dock.add_child(_label_text)

	_label_size = SpinBox.new()
	_label_size.min_value = 4
	_label_size.max_value = 256
	_label_size.step = 1
	_label_size.value = 48
	_label_size.suffix = " px"
	_dock.add_child(_label_size)

	_label_color = ColorPickerButton.new()
	_label_color.color = Color(0.95, 0.95, 0.95, 1.0)
	_dock.add_child(_label_color)

	_label_height_offset = SpinBox.new()
	_label_height_offset.min_value = 0.0
	_label_height_offset.max_value = 0.5
	_label_height_offset.step = 0.01
	_label_height_offset.value = 0.02
	_label_height_offset.suffix = " m"
	_dock.add_child(_label_height_offset)


func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
	if camera == null:
		print("Gym Tools: camera not found.")
		return EditorPlugin.AFTER_GUI_INPUT_PASS

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R and _is_slope_mode_active():
			_slope_rotation = (_slope_rotation + 1) % 4
			print("Gym Tools: slope rotation %d." % _slope_rotation)
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		if _try_handle_left_action_keybind(event):
			return EditorPlugin.AFTER_GUI_INPUT_STOP

	if event is InputEventMouseButton and event.pressed:
		if event.button_index != MOUSE_BUTTON_LEFT and event.button_index != MOUSE_BUTTON_RIGHT:
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		var action := _action_for_button(event)
		if action == ToolMode.PAINT_MATERIAL:
			print("Gym Tools: paint material started.")
			if _try_paint_material(camera, event.position):
				return EditorPlugin.AFTER_GUI_INPUT_STOP
		elif action == ToolMode.PLACE_LABEL:
			print("Gym Tools: place label started.")
			if _try_place_label(camera, event.position):
				return EditorPlugin.AFTER_GUI_INPUT_STOP
		elif action == ToolMode.DELETE_MESH:
			print("Gym Tools: delete mesh started.")
			if _try_delete_mesh(camera, event.position):
				return EditorPlugin.AFTER_GUI_INPUT_STOP
		elif action == ToolMode.PLACE_MESH:
			print("Gym Tools: place mesh started.")
			if _begin_place_mesh_drag(camera, event):
				return EditorPlugin.AFTER_GUI_INPUT_STOP
		elif action == ToolMode.PLACE_SLOPE:
			print("Gym Tools: place slope started.")
			if _try_place_slope(camera, event.position):
				return EditorPlugin.AFTER_GUI_INPUT_STOP

	if event is InputEventMouseButton and not event.pressed:
		if _dragging and event.button_index == _drag_button:
			_dragging = false
			_drag_button = 0
			return EditorPlugin.AFTER_GUI_INPUT_PASS

	if event is InputEventMouseMotion:
		if _dragging:
			if _continue_place_mesh_drag(camera, event.position):
				return EditorPlugin.AFTER_GUI_INPUT_STOP
		if _is_slope_mode_active():
			_update_slope_preview(camera, event.position)
		else:
			_clear_slope_preview()

	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _try_paint_material(camera: Camera3D, screen_pos: Vector2) -> bool:
	var material := _material_picker.edited_resource
	if material == null:
		print("Gym Tools: paint material skipped (no material selected).")
		return false

	var hit := _raycast_from_camera(camera, screen_pos)
	if hit.is_empty():
		print("Gym Tools: paint material skipped (no hit).")
		return false

	var target := _find_mesh_target(hit.get("collider"))
	if target == null:
		print("Gym Tools: paint material skipped (no MeshInstance3D found).")
		return false

	if target is MeshInstance3D:
		var undo_redo := get_undo_redo()
		undo_redo.create_action("Paint Material")
		var mesh := target.mesh
		if mesh:
			var surface_count := mesh.get_surface_count()
			for surface_index in range(surface_count):
				var previous := target.get_surface_override_material(surface_index)
				undo_redo.add_do_method(
					target,
					"set_surface_override_material",
					surface_index,
					material
				)
				undo_redo.add_undo_method(
					target,
					"set_surface_override_material",
					surface_index,
					previous
				)
		else:
			var previous_override := target.material_override
			undo_redo.add_do_method(target, "set", "material_override", material)
			undo_redo.add_undo_method(target, "set", "material_override", previous_override)
		undo_redo.commit_action()
		print("Gym Tools: painted material on %s." % target.name)
		return true

	return false


func _try_place_label(camera: Camera3D, screen_pos: Vector2) -> bool:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		print("Gym Tools: place label skipped (no edited scene root).")
		return false

	var hit := _raycast_from_camera(camera, screen_pos)
	var label := Label3D.new()
	label.text = _label_text.text.strip_edges()
	if label.text.is_empty():
		label.text = "Label"
	label.font_size = int(_label_size.value)
	label.modulate = _label_color.color
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	if hit.is_empty():
		var fallback_pos := camera.global_transform.origin + camera.global_transform.basis.z * -3.0
		label.position = fallback_pos
		label.basis = camera.global_transform.basis
		print("Gym Tools: place label fallback (no hit).")
	else:
		label.position = hit.position + hit.normal * float(_label_height_offset.value)
		label.basis = _basis_from_normal(hit.normal)

	var undo_redo := get_undo_redo()
	undo_redo.create_action("Place Label")
	undo_redo.add_do_method(root, "add_child", label)
	undo_redo.add_do_method(label, "set_owner", root)
	undo_redo.add_undo_method(root, "remove_child", label)
	undo_redo.commit_action()
	print("Gym Tools: placed label '%s'." % label.text)
	return true


func _try_delete_mesh(camera: Camera3D, screen_pos: Vector2) -> bool:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		print("Gym Tools: delete mesh skipped (no edited scene root).")
		return false

	var hit := _raycast_from_camera(camera, screen_pos)
	if hit.is_empty():
		print("Gym Tools: delete mesh skipped (no hit).")
		return false

	var body := _find_static_body(hit.get("collider"))
	if body == null:
		print("Gym Tools: delete mesh skipped (no StaticBody3D found).")
		return false

	var parent := body.get_parent()
	if parent == null:
		print("Gym Tools: delete mesh skipped (no parent).")
		return false

	var parent_index := body.get_index()
	var previous_owner := body.owner

	var undo_redo := get_undo_redo()
	undo_redo.create_action("Delete StaticBody3D")
	undo_redo.add_do_method(parent, "remove_child", body)
	undo_redo.add_do_method(body, "set_owner", null)
	undo_redo.add_undo_method(parent, "add_child", body)
	undo_redo.add_undo_method(parent, "move_child", body, parent_index)
	undo_redo.add_undo_method(body, "set_owner", previous_owner)
	undo_redo.commit_action()
	print("Gym Tools: deleted %s." % body.name)
	return true


func _begin_place_mesh_drag(camera: Camera3D, event: InputEventMouseButton) -> bool:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		print("Gym Tools: place mesh skipped (no edited scene root).")
		return false

	var place_pos := _compute_place_position(camera, event.position, null)
	if place_pos == null:
		print("Gym Tools: place mesh skipped (no hit).")
		return false

	var snapped_pos := place_pos as Vector3
	var cell_key := _grid_cell_key(snapped_pos)
	if _is_cell_occupied(root, cell_key):
		print("Gym Tools: place mesh skipped (cell occupied).")
		return false

	_dragging = true
	_drag_button = event.button_index
	_drag_locked_y = snapped_pos.y
	_drag_last_cell = cell_key
	_drag_start_screen = event.position
	_drag_anchor_screen = _screen_for_position(camera, snapped_pos)
	return _place_mesh_at(root, snapped_pos, cell_key)


func _continue_place_mesh_drag(camera: Camera3D, screen_pos: Vector2) -> bool:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		return false

	_drag_anchor_screen = _screen_for_position(camera, _cell_center(_drag_last_cell))
	if screen_pos.distance_to(_drag_anchor_screen) > DRAG_RETARGET_THRESHOLD:
		var retarget_pos := _compute_place_position(camera, screen_pos, _drag_locked_y)
		if retarget_pos != null:
			var snapped_pos := retarget_pos as Vector3
			var cell_key := _grid_cell_key(snapped_pos)
			_drag_last_cell = cell_key
			_drag_anchor_screen = _screen_for_position(camera, snapped_pos)
		return false
	var delta := screen_pos - _drag_anchor_screen
	if delta.length() < DRAG_SCREEN_THRESHOLD:
		return false

	var world_dir := camera.global_transform.basis.x * delta.x
	world_dir += camera.global_transform.basis.y * -delta.y
	world_dir.y = 0.0
	if world_dir.length() < 0.001:
		return false
	world_dir = world_dir.normalized()

	var abs_x := abs(world_dir.x)
	var abs_z := abs(world_dir.z)
	if abs_x < abs_z * DRAG_AXIS_DOMINANCE and abs_z < abs_x * DRAG_AXIS_DOMINANCE:
		return false

	var step := 0
	var delta_cell := Vector3i.ZERO
	if abs_x >= abs_z:
		step = 1 if world_dir.x >= 0.0 else -1
		delta_cell = Vector3i(step, 0, 0)
	else:
		step = 1 if world_dir.z >= 0.0 else -1
		delta_cell = Vector3i(0, 0, step)

	var target_cell := _drag_last_cell + delta_cell
	target_cell.y = _drag_last_cell.y
	if _is_cell_occupied(root, target_cell):
		_drag_start_screen = screen_pos
		return false

	var target_pos := _cell_center(target_cell)
	target_pos.y = _drag_locked_y
	_drag_last_cell = target_cell
	_drag_start_screen = screen_pos
	_drag_anchor_screen = _screen_for_position(camera, target_pos)
	return _place_mesh_at(root, target_pos, target_cell)


func _place_mesh_at(root: Node, place_pos: Vector3, cell_key: Vector3i) -> bool:
	var instance := _instantiate_placeable()
	if instance == null:
		print("Gym Tools: place mesh skipped (no mesh selected).")
		return false

	instance = _prepare_placeable(instance)
	_apply_place_material(instance)
	if instance is Node3D:
		instance.position = place_pos

	var undo_redo := get_undo_redo()
	undo_redo.create_action("Place Mesh")
	undo_redo.add_do_method(root, "add_child", instance)
	undo_redo.add_do_method(self, "_set_owner_recursive", instance, root)
	undo_redo.add_do_method(instance, "add_to_group", "gym_tools_placeable")
	undo_redo.add_do_method(instance, "set_meta", "gym_tools_grid_cell", cell_key)
	undo_redo.add_undo_method(root, "remove_child", instance)
	undo_redo.add_undo_method(instance, "remove_from_group", "gym_tools_placeable")
	undo_redo.add_undo_method(instance, "remove_meta", "gym_tools_grid_cell")
	undo_redo.commit_action()
	print("Gym Tools: placed mesh %s." % instance.name)
	return true


func _try_place_slope(camera: Camera3D, screen_pos: Vector2) -> bool:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		print("Gym Tools: place slope skipped (no edited scene root).")
		return false

	var place_pos := _compute_place_position(camera, screen_pos, null)
	if place_pos == null:
		print("Gym Tools: place slope skipped (no hit).")
		return false

	var anchor_cell := _grid_cell_key(place_pos as Vector3)
	var length_cells := _slope_length_cells()
	var cells := _slope_cells_from(anchor_cell, length_cells)
	if _are_cells_occupied(root, cells):
		print("Gym Tools: place slope skipped (cell occupied).")
		return false

	var slope := _build_slope(length_cells)
	if slope is Node3D:
		slope.position = _slope_placement_center(anchor_cell, length_cells)
		slope.rotation.y = _slope_rotation_yaw()

	_apply_place_material(slope)

	var undo_redo := get_undo_redo()
	undo_redo.create_action("Place Slope")
	undo_redo.add_do_method(root, "add_child", slope)
	undo_redo.add_do_method(self, "_set_owner_recursive", slope, root)
	undo_redo.add_do_method(slope, "add_to_group", "gym_tools_placeable")
	undo_redo.add_do_method(slope, "set_meta", "gym_tools_grid_cells", cells)
	undo_redo.add_undo_method(root, "remove_child", slope)
	undo_redo.add_undo_method(slope, "remove_from_group", "gym_tools_placeable")
	undo_redo.add_undo_method(slope, "remove_meta", "gym_tools_grid_cells")
	undo_redo.commit_action()
	print("Gym Tools: placed slope %s." % slope.name)
	return true


func _raycast_from_camera(camera: Camera3D, screen_pos: Vector2) -> Dictionary:
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var to := from + dir * RAY_LENGTH
	var space_state := camera.get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.new()
	params.from = from
	params.to = to
	params.collide_with_areas = true
	params.collide_with_bodies = true
	return space_state.intersect_ray(params)


func _find_mesh_target(node: Object) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	if node is Node:
		for child in node.get_children():
			if child is MeshInstance3D:
				return child
	return null


func _instantiate_placeable() -> Node:
	var packed := _mesh_picker.edited_resource
	if packed and packed is PackedScene:
		return packed.instantiate()
	return _build_default_block()


func _build_default_block() -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "PlacedBlock"

	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(GRID_SIZE, GRID_SIZE, GRID_SIZE)
	mesh_instance.mesh = box_mesh
	body.add_child(mesh_instance)

	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(GRID_SIZE, GRID_SIZE, GRID_SIZE)
	collider.shape = shape
	body.add_child(collider)
	return body


func _apply_place_material(node: Node) -> void:
	var material := _place_material_picker.edited_resource
	if material == null:
		return
	_apply_material_recursive(node, material)


func _apply_material_recursive(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		var mesh : Mesh = node.mesh
		if mesh is Mesh:
			var surface_count := mesh.get_surface_count()
			for surface_index in range(surface_count):
				node.set_surface_override_material(surface_index, material)
		else:
			node.material_override = material
	for child in node.get_children():
		_apply_material_recursive(child, material)


func _build_slope(length_cells: int) -> StaticBody3D:
	var length := float(length_cells) * GRID_SIZE
	var height := GRID_SIZE
	var width := GRID_SIZE
	var ramp_length := _slope_ramp_length()
	var mesh := _build_slope_mesh(min(ramp_length, length), width, height)

	var body := StaticBody3D.new()
	body.name = "PlacedSlope"

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	body.add_child(mesh_instance)

	var shape := ConvexPolygonShape3D.new()
	shape.set_points(mesh.get_faces())
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

	var remainder := length - ramp_length
	if remainder > 0.001:
		var filler_mesh := BoxMesh.new()
		filler_mesh.size = Vector3(width, height, remainder)
		var filler_instance := MeshInstance3D.new()
		filler_instance.mesh = filler_mesh
		filler_instance.position = Vector3(0.0, 0.0, ramp_length * 0.5 + remainder * 0.5)
		body.add_child(filler_instance)

		var filler_shape := BoxShape3D.new()
		filler_shape.size = Vector3(width, height, remainder)
		var filler_collider := CollisionShape3D.new()
		filler_collider.shape = filler_shape
		filler_collider.position = filler_instance.position
		body.add_child(filler_collider)

	return body


func _build_slope_mesh(length: float, width: float, height: float) -> ArrayMesh:
	var w := width * 0.5
	var h := height * 0.5
	var l := length * 0.5

	var a := Vector3(-w, -h, -l)
	var b := Vector3(w, -h, -l)
	var c := Vector3(-w, -h, l)
	var d := Vector3(w, -h, l)
	var e := Vector3(-w, h, l)
	var f := Vector3(w, h, l)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Bottom
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(d)
	st.add_vertex(a)
	st.add_vertex(d)
	st.add_vertex(c)

	# Slope
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(f)
	st.add_vertex(a)
	st.add_vertex(f)
	st.add_vertex(e)

	# Front
	st.add_vertex(c)
	st.add_vertex(d)
	st.add_vertex(f)
	st.add_vertex(c)
	st.add_vertex(f)
	st.add_vertex(e)

	# Right
	st.add_vertex(b)
	st.add_vertex(d)
	st.add_vertex(f)

	# Left
	st.add_vertex(a)
	st.add_vertex(e)
	st.add_vertex(c)

	st.generate_normals()
	var mesh := ArrayMesh.new()
	st.commit(mesh)
	return mesh


func _prepare_placeable(node: Node) -> Node:
	if _has_collision(node):
		return node

	var mesh := _find_mesh_target(node)
	if mesh == null:
		return node

	var body := StaticBody3D.new()
	body.name = "%s_Body" % mesh.name
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(GRID_SIZE, GRID_SIZE, GRID_SIZE)
	collider.shape = shape
	body.add_child(collider)

	if mesh.get_parent() == null:
		body.add_child(mesh)
		return body

	var parent := mesh.get_parent()
	parent.add_child(body)
	parent.remove_child(mesh)
	body.add_child(mesh)
	return node


func _has_collision(node: Node) -> bool:
	if node is CollisionShape3D or node is CollisionObject3D:
		return true
	for child in node.get_children():
		if _has_collision(child):
			return true
	return false


func _set_owner_recursive(node: Node, owner: Node) -> void:
	node.owner = owner
	for child in node.get_children():
		_set_owner_recursive(child, owner)


func _find_static_body(node: Object) -> StaticBody3D:
	if node is StaticBody3D:
		return node
	if node is Node:
		var current := node
		while current:
			if current is StaticBody3D:
				return current
			current = current.get_parent()
	return null


func _basis_from_normal(normal: Vector3) -> Basis:
	var up := normal.normalized()
	var forward := Vector3.FORWARD
	if abs(up.dot(forward)) > 0.95:
		forward = Vector3.RIGHT
	var right := forward.cross(up).normalized()
	var back := up.cross(right).normalized()
	return Basis(right, up, back)


func _snap_to_grid(position: Vector3, grid_size: float) -> Vector3:
	return position.snapped(Vector3(grid_size, grid_size, grid_size))


func _snap_to_grid_with_offset(position: Vector3, grid_size: float, offset: Vector3) -> Vector3:
	return (position - offset).snapped(Vector3(grid_size, grid_size, grid_size)) + offset


func _grid_cell_key(position: Vector3) -> Vector3i:
	var offset := _grid_offset()
	var snapped := _snap_to_grid_with_offset(position, GRID_SIZE, offset)
	return Vector3i(
		int(round((snapped.x - offset.x) / GRID_SIZE)),
		int(round((snapped.y - offset.y) / GRID_SIZE)),
		int(round((snapped.z - offset.z) / GRID_SIZE))
	)


func _compute_place_position(camera: Camera3D, screen_pos: Vector2, locked_y: Variant) -> Variant:
	var hit := _raycast_from_camera(camera, screen_pos)
	if hit.is_empty():
		return null

	var place_pos : Vector3 = hit.position + hit.normal * (GRID_SIZE * 0.5)
	place_pos = _snap_to_grid_with_offset(place_pos, GRID_SIZE, _grid_offset())

	if locked_y != null:
		place_pos.y = float(locked_y)

	return place_pos


func _cell_center(cell_key: Vector3i) -> Vector3:
	var offset := _grid_offset()
	return offset + Vector3(cell_key.x, cell_key.y, cell_key.z) * GRID_SIZE


func _is_cell_occupied(root: Node, cell_key: Vector3i) -> bool:
	var nodes := root.get_tree().get_nodes_in_group("gym_tools_placeable")
	for node in nodes:
		if node is Node3D:
			if node.has_meta("gym_tools_grid_cells"):
				var cells := node.get_meta("gym_tools_grid_cells")
				for cell in cells:
					if cell == cell_key:
						return true
			else:
				var existing_key := Vector3i.ZERO
				if node.has_meta("gym_tools_grid_cell"):
					existing_key = node.get_meta("gym_tools_grid_cell")
				else:
					existing_key = _grid_cell_key(node.global_position)
				if existing_key == cell_key:
					return true
	return false


func _are_cells_occupied(root: Node, cells: Array) -> bool:
	for cell in cells:
		if _is_cell_occupied(root, cell):
			return true
	return false


func _grid_offset() -> Vector3:
	return Vector3(
		_place_offset_x.value,
		_place_offset_y.value,
		_place_offset_z.value
	)


func _screen_for_position(camera: Camera3D, position: Vector3) -> Vector2:
	return camera.unproject_position(position)


func _slope_ramp_length() -> float:
	var angle := deg_to_rad(_slope_angle.value)
	var height := GRID_SIZE
	var length :float = height / max(0.01, tan(angle))
	return max(0.01, length)


func _slope_length_cells() -> int:
	return int(ceil(_slope_ramp_length() / GRID_SIZE))


func _slope_direction() -> Vector3:
	match _slope_rotation:
		1:
			return Vector3.RIGHT
		2:
			return Vector3.BACK
		3:
			return Vector3.LEFT
		_:
			return Vector3.FORWARD


func _slope_rotation_yaw() -> float:
	return _slope_rotation * (PI * 0.5)


func _slope_cells_from(anchor_cell: Vector3i, length_cells: int) -> Array:
	var cells := []
	cells.resize(length_cells)
	var dir := _slope_direction()
	var step := Vector3i(int(dir.x), 0, int(dir.z))
	for i in range(length_cells):
		cells[i] = anchor_cell + step * i
	return cells


func _slope_placement_center(anchor_cell: Vector3i, length_cells: int) -> Vector3:
	var anchor_center := _cell_center(anchor_cell)
	var total_length := float(length_cells) * GRID_SIZE
	var offset := _slope_direction() * (total_length * 0.5 - GRID_SIZE * 0.5)
	return anchor_center + offset


func _is_slope_mode_active() -> bool:
	return _left_action_picker.get_selected_id() == ToolMode.PLACE_SLOPE \
		or _right_action_picker.get_selected_id() == ToolMode.PLACE_SLOPE


func _update_slope_preview(camera: Camera3D, screen_pos: Vector2) -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		return

	var place_pos := _compute_place_position(camera, screen_pos, null)
	if place_pos == null:
		return

	var anchor_cell := _grid_cell_key(place_pos as Vector3)
	var length_cells := _slope_length_cells()
	var preview := _ensure_slope_preview(root, length_cells)
	preview.position = _slope_placement_center(anchor_cell, length_cells)
	preview.rotation.y = _slope_rotation_yaw()


func _ensure_slope_preview(root: Node, length_cells: int) -> Node3D:
	var existing := root.get_node_or_null(PREVIEW_NODE_NAME)
	if existing and existing is Node3D:
		var meta_cells := existing.get_meta("gym_tools_slope_cells", -1)
		if meta_cells == length_cells:
			return existing
		existing.queue_free()

	var preview := _build_slope(length_cells)
	preview.name = PREVIEW_NODE_NAME
	preview.set_meta("gym_tools_slope_cells", length_cells)
	preview.set_meta("gym_tools_preview", true)
	preview.visible = true
	preview.owner = null
	if preview is StaticBody3D:
		preview.collision_layer = 0
		preview.collision_mask = 0
	_apply_preview_material(preview)
	root.add_child(preview)
	return preview


func _clear_slope_preview() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		return
	var existing := root.get_node_or_null(PREVIEW_NODE_NAME)
	if existing:
		existing.queue_free()


func _apply_preview_material(node: Node) -> void:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.2, 0.8, 1.0, 0.35)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_apply_material_recursive(node, material)


func _action_for_button(event: InputEventMouseButton) -> int:
	if event.button_index == MOUSE_BUTTON_RIGHT:
		return _right_action_picker.get_selected_id()
	return _left_action_picker.get_selected_id()


func _try_handle_left_action_keybind(event: InputEventKey) -> bool:
	match event.keycode:
		KEY_1:
			_left_action_picker.select(_left_action_picker.get_item_index(ToolMode.PAINT_MATERIAL))
		KEY_2:
			_left_action_picker.select(_left_action_picker.get_item_index(ToolMode.PLACE_LABEL))
		KEY_3:
			_left_action_picker.select(_left_action_picker.get_item_index(ToolMode.DELETE_MESH))
		KEY_4:
			_left_action_picker.select(_left_action_picker.get_item_index(ToolMode.PLACE_MESH))
		KEY_5:
			_left_action_picker.select(_left_action_picker.get_item_index(ToolMode.PLACE_SLOPE))
		KEY_0:
			_left_action_picker.select(_left_action_picker.get_item_index(ToolMode.NONE))
		_:
			return false
	print("Gym Tools: left action set via hotkey.")
	return true
