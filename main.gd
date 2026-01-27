extends Node3D

@export var play_scene: PackedScene
@export var settings_scene: PackedScene

@onready var play_button: Button = $UI/MainMenu/VBoxContainer/PlayButton
@onready var settings_button: Button = $UI/MainMenu/VBoxContainer/SettingsButton
@onready var controls_button: Button = $UI/MainMenu/VBoxContainer/ControlsButton
@onready var ui_change_sfx: AudioStreamPlayer = $UIChangeSfx
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var scene_host: Node3D = $SceneHost
@onready var menu_root: Control = $UI/MainMenu
@onready var background_floaters: Node3D = $BackgroundFloaters
@onready var main_camera: Camera3D = $Camera3D
@onready var starfield_sphere: MeshInstance3D = $StarfieldSphere
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var menu_environment: Environment = world_environment.environment if world_environment else null
@onready var directional_light: DirectionalLight3D = $DirectionalLight3D

@export var floater_min_interval: float = 6.0
@export var floater_max_interval: float = 12.0
@export var floater_min_duration: float = 14.0
@export var floater_max_duration: float = 22.0
@export var floater_min_height: float = 0.2
@export var floater_max_height: float = 2.0
@export var floater_vertical_drift: float = 1.0
@export var floater_min_z: float = -5.0
@export var floater_max_z: float = -2.0
@export var floater_min_scale: float = 0.6
@export var floater_max_scale: float = 1.1

var _rng := RandomNumberGenerator.new()
var _floater_toggle := false
var _dog_mesh: Mesh = preload("res://Assets/models/Dog_Default.res")
var _board_mesh: Mesh = preload("res://Assets/models/Board.res")
var _floaters: Array[MeshInstance3D] = []
var _return_focus_path: NodePath = NodePath("")
var _active_scene: Node
var _floaters_enabled: bool = true

func _ready():
	# Load scenes if not set in editor (though usually set via editor)
	if not play_scene: play_scene = load("res://grinding1.tscn")
	if not settings_scene: settings_scene = load("res://Settings.tscn")
	# Ensure mouse is visible for the menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	play_button.focus_mode = Control.FOCUS_ALL
	settings_button.focus_mode = Control.FOCUS_ALL
	controls_button.focus_mode = Control.FOCUS_ALL
	play_button.grab_focus()
	_register_ui_change(play_button)
	_register_ui_change(settings_button)
	_register_ui_change(controls_button)
	_rng.randomize()
	_start_floater_loop()
	_set_menu_visible(true)
	_prepare_music()
	if music_player:
		Global.register_music_player(music_player)
		music_player.process_mode = Node.PROCESS_MODE_ALWAYS
		music_player.stream_paused = false
		if not music_player.playing:
			music_player.play()

func _process(_delta: float) -> void:
	if menu_root and menu_root.visible and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_floaters()

func _input(event: InputEvent) -> void:
	if menu_root and menu_root.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()

func _on_play_button_pressed():
	if not play_scene or not scene_host:
		return
	if _active_scene and is_instance_valid(_active_scene):
		return
	var instance := play_scene.instantiate()
	scene_host.add_child(instance)
	_active_scene = instance
	_set_menu_visible(false)
	if not _active_scene.tree_exited.is_connected(_on_active_scene_exited):
		_active_scene.tree_exited.connect(_on_active_scene_exited)

func _on_settings_button_pressed():
	var focused := get_viewport().gui_get_focus_owner()
	if focused:
		_return_focus_path = focused.get_path()
	var settings_instance = settings_scene.instantiate()
	add_child(settings_instance)
	settings_instance.tree_exited.connect(_on_settings_closed)

func _on_controls_button_pressed() -> void:
	if not settings_scene:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused:
		_return_focus_path = focused.get_path()
	var settings_instance = settings_scene.instantiate()
	settings_instance.show_pointer_lock_hint = true
	if settings_instance.has_method("set_initial_tab"):
		settings_instance.set_initial_tab(&"Controls")
	add_child(settings_instance)
	settings_instance.tree_exited.connect(_on_settings_closed)

func return_to_menu() -> void:
	if _active_scene and is_instance_valid(_active_scene):
		_active_scene.queue_free()
		_active_scene = null
	_set_menu_visible(true)
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func is_game_active() -> bool:
	return _active_scene != null and is_instance_valid(_active_scene)

func _on_active_scene_exited() -> void:
	_active_scene = null
	_set_menu_visible(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false

func _on_settings_closed() -> void:
	if not is_inside_tree():
		_return_focus_path = NodePath("")
		return
	if _return_focus_path == NodePath(""):
		return
	var root := get_tree().root
	var target := root.get_node_or_null(_return_focus_path) as Control if root else null
	if target:
		target.grab_focus()
	_return_focus_path = NodePath("")

func _register_ui_change(control: Control) -> void:
	if not control:
		return
	control.focus_entered.connect(_on_ui_change)
	control.mouse_entered.connect(_on_hover_focus.bind(control))
	if control is BaseButton:
		control.pressed.connect(_on_ui_change)

func _on_ui_change() -> void:
	if not is_inside_tree():
		return
	if ui_change_sfx and ui_change_sfx.is_inside_tree():
		ui_change_sfx.pitch_scale = _rng.randf_range(0.94, 1.06)
		ui_change_sfx.play()

func _on_hover_focus(control: Control) -> void:
	if not control or not control.visible:
		return
	if control.focus_mode == Control.FOCUS_NONE:
		return
	control.grab_focus()
	_on_ui_change()

func _set_menu_visible(new_visible: bool) -> void:
	if menu_root:
		menu_root.visible = new_visible
	if new_visible:
		play_button.grab_focus()
	_floaters_enabled = new_visible
	if background_floaters:
		background_floaters.visible = new_visible
	if starfield_sphere:
		starfield_sphere.visible = new_visible
	if world_environment:
		world_environment.environment = menu_environment if new_visible else null
	if directional_light:
		directional_light.visible = new_visible
	if not new_visible:
		for floater in _floaters:
			if is_instance_valid(floater):
				floater.queue_free()
		_floaters.clear()

func _prepare_music() -> void:
	if not music_player:
		return
	if not music_player.finished.is_connected(_on_music_finished):
		music_player.finished.connect(_on_music_finished)

func _on_music_finished() -> void:
	if music_player and music_player.is_inside_tree():
		music_player.play()

func _start_floater_loop() -> void:
	call_deferred("_spawn_floater_loop")

func _spawn_floater_loop() -> void:
	await get_tree().create_timer(_rng.randf_range(floater_min_interval, floater_max_interval)).timeout
	if not _floaters_enabled:
		_spawn_floater_loop()
		return
	if _floaters.size() < 2:
		_spawn_floater()
	_spawn_floater_loop()

func _spawn_floater() -> void:
	if not background_floaters:
		return
	var mesh := _board_mesh
	_floater_toggle = !_floater_toggle
	if _floater_toggle:
		mesh = _dog_mesh
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	var scale_value := _rng.randf_range(floater_min_scale, floater_max_scale)
	mesh_instance.scale = Vector3.ONE * scale_value
	var height := _rng.randf_range(floater_min_height, floater_max_height)
	var depth := _rng.randf_range(floater_min_z, floater_max_z)
	var mid_pos := Vector3(main_camera.global_position.x, height, depth)
	var start_pos := mid_pos
	var end_pos := mid_pos
	if main_camera:
		var viewport_size := get_viewport().get_visible_rect().size
		var margin := 0.0
		var screen_pos := Vector2(
			_rng.randf_range(margin, viewport_size.x - margin),
			_rng.randf_range(margin, viewport_size.y - margin)
		)
		var depth_dist: float = abs(depth - main_camera.global_position.z)
		mid_pos = main_camera.project_position(screen_pos, depth_dist)
		var offscreen_margin := 140.0
		var start_screen := _random_offscreen_screen_point(viewport_size, offscreen_margin)
		var dir := (screen_pos - start_screen).normalized()
		if dir.length() < 0.001:
			dir = Vector2.RIGHT
		var exit_dist : float = max(viewport_size.x, viewport_size.y) + offscreen_margin * 2.0
		var end_screen := screen_pos + dir * exit_dist
		start_pos = main_camera.project_position(start_screen, depth_dist)
		end_pos = main_camera.project_position(end_screen, depth_dist)
		start_pos.y += _rng.randf_range(-floater_vertical_drift, floater_vertical_drift)
		end_pos.y += _rng.randf_range(-floater_vertical_drift, floater_vertical_drift)
	else:
		start_pos = mid_pos + Vector3(0, _rng.randf_range(-floater_vertical_drift, floater_vertical_drift), 0)
		end_pos = mid_pos + Vector3(0, _rng.randf_range(-floater_vertical_drift, floater_vertical_drift), 0)
	mesh_instance.position = start_pos
	mesh_instance.rotation = Vector3(
		_rng.randf_range(-0.3, 0.3),
		_rng.randf_range(0.0, TAU),
		_rng.randf_range(-0.3, 0.3)
	)
	background_floaters.add_child(mesh_instance)
	mesh_instance.set_meta("entered", false)
	mesh_instance.set_meta("finished", false)
	_floaters.append(mesh_instance)

	var travel_time := _rng.randf_range(floater_min_duration, floater_max_duration)
	var end_rot := mesh_instance.rotation + Vector3(
		_rng.randf_range(-0.7, 0.7),
		_rng.randf_range(0.6, 1.6),
		_rng.randf_range(-0.7, 0.7)
	)

	var tween := create_tween()
	tween.tween_property(mesh_instance, "position", end_pos, travel_time).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(mesh_instance, "rotation", end_rot, travel_time).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	var mesh_ref : WeakRef = weakref(mesh_instance)
	tween.finished.connect(func():
		var mesh_refed := mesh_ref.get_ref() as MeshInstance3D
		if mesh_refed:
			mesh_refed.set_meta("finished", true)
	)

func _random_offscreen_screen_point(viewport_size: Vector2, margin: float) -> Vector2:
	var side := _rng.randi_range(0, 3)
	if side == 0:
		return Vector2(_rng.randf_range(-margin, viewport_size.x + margin), -margin)
	if side == 1:
		return Vector2(_rng.randf_range(-margin, viewport_size.x + margin), viewport_size.y + margin)
	if side == 2:
		return Vector2(-margin, _rng.randf_range(-margin, viewport_size.y + margin))
	return Vector2(viewport_size.x + margin, _rng.randf_range(-margin, viewport_size.y + margin))

func _update_floaters() -> void:
	if not _floaters_enabled:
		return
	if not main_camera:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var margin := 120.0
	for i in range(_floaters.size() - 1, -1, -1):
		var floater := _floaters[i]
		if not is_instance_valid(floater):
			_floaters.remove_at(i)
			continue
		if main_camera.is_position_behind(floater.global_position):
			continue
		var screen := main_camera.unproject_position(floater.global_position)
		var on_screen := screen.x >= -margin and screen.x <= viewport_size.x + margin and screen.y >= -margin and screen.y <= viewport_size.y + margin
		if on_screen:
			floater.set_meta("entered", true)
		var entered := bool(floater.get_meta("entered", false))
		var finished := bool(floater.get_meta("finished", false))
		if (entered and not on_screen) or (finished and not on_screen):
			floater.queue_free()
			_floaters.remove_at(i)
