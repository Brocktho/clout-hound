extends CharacterBody3D
class_name Player


@export_group("Movement")
@export var max_speed: float = 10.0
@export var acceleration: float = 20.0 # Reaches max_speed in ~0.5s if 20
@export var friction: float = 50.0
@export var air_resistance: float = 1.0
@export var jump_velocity: float = 5.0
@export var diagonal_boost: float = 2.0
@export var jump_buffer_time: float = 0.15 # Time before landing that a jump press is still registered
@export var landing_grace_time: float = 0.1 # Time after landing where friction is reduced



@export_group("Slide")
@export var slide_friction: float = 0.5 # Very low friction
@export var slide_control: float = 0.05 # Heavily restricted movement input
@export var steering_weight: float = 4.0 # How quickly the board carves in standard movement
@export var slope_slide_gravity_modifier: float = 10.0
@export var slope_regular_gravity_modifier: float = 2.0
@export var slide_visual_z_scale: float = 0.5
@export var slide_collider_height_ratio: float = 0.5

@export_group("Grind")
@export var grind_snap_distance: float = 1.0
@export var grind_min_speed: float = 2.0
@export var grind_cast_radius_multiplier: float = 1.0

@export_group("Camera Settings")
@export var mouse_sensitivity: float = 0.0005
@export var camera_height: float = 0.5 # Offset from the player's center
@export var camera_distance: float = 0.1 # Very slight backward offset to avoid clipping inside the head
@export var base_fov: float = 75.0
@export var max_fov_boost: float = 50.0
@export var speed_for_max_fov: float = 50.0
@export var camera_follow_speed: float = 12.0
@export var camera_vertical_speed: float = 6.0

@export_group("Third Person Settings")
@export var third_person_distance: float = 4.0
@export var third_person_offset: Vector3 = Vector3(0.5, 0.5, 0) # Over-the-shoulder look

@export_group("Trick Settings")
@export var spin_increment_deg: float = 90.0 # Degrees per frame-ish, or radians
@export var flip_speed: float = 720.0 # Degrees per second for kickflip
@export var spin_boost_amount: float = 2.5 # Speed added per 180 spin
@export var lean_intensity_player: float = 0.05 # How much the player leans
@export var lean_intensity_board: float = 0.005 # How much the board tilts
@export var lean_speed: float = 8.0 # How fast the lean responds
@export var ragdoll_friction: float = 25.0
@export var reset_speed_threshold: float = 0.5
@export var trick_resources: Array[TrickResource] = []
@export var trick_stale_factor: float = 0.3

@export var ragdoll_bail_sfx: Array[AudioStream] = [
	preload("res://Assets/Audio/SFX/Bail_0.wav"),
	preload("res://Assets/Audio/SFX/Bail_1.wav"),
	preload("res://Assets/Audio/SFX/Bail_2.wav"),
	preload("res://Assets/Audio/SFX/Bail_3.wav"),
	preload("res://Assets/Audio/SFX/Bail_4.wav"),
	preload("res://Assets/Audio/SFX/Bail_5.wav"),
	preload("res://Assets/Audio/SFX/Bail_6.wav"),
	preload("res://Assets/Audio/SFX/Bail_7.wav"),
	preload("res://Assets/Audio/SFX/Bail_8.wav"),
	preload("res://Assets/Audio/SFX/Bail_9.wav"),
	preload("res://Assets/Audio/SFX/Bail_10.wav"),
	preload("res://Assets/Audio/SFX/Bail_11.wav")
]
@export var jump_sfx: Array[AudioStream] = [
	preload("res://Assets/Audio/SFX/Jump_0.wav"),
	preload("res://Assets/Audio/SFX/Jump_1.wav"),
	preload("res://Assets/Audio/SFX/Jump_2.wav"),
	preload("res://Assets/Audio/SFX/Jump_3.wav"),
	preload("res://Assets/Audio/SFX/Jump_4.wav"),
	preload("res://Assets/Audio/SFX/Jump_5.wav")
]
@export var landing_sfx: Array[AudioStream] = [
	preload("res://Assets/Audio/SFX/Landing_0.wav"),
	preload("res://Assets/Audio/SFX/Landing_1.wav"),
	preload("res://Assets/Audio/SFX/Landing_2.wav"),
	preload("res://Assets/Audio/SFX/Landing_3.wav"),
	preload("res://Assets/Audio/SFX/Landing_4.wav"),
	preload("res://Assets/Audio/SFX/Landing_5.wav")
]
@export var land_rail_sfx: Array[AudioStream] = [
	preload("res://Assets/Audio/SFX/Land_Rail_0.wav"),
	preload("res://Assets/Audio/SFX/Land_Rail_1.wav"),
	preload("res://Assets/Audio/SFX/Land_Rail_2.wav"),
	preload("res://Assets/Audio/SFX/Land_Rail_3.wav"),
	preload("res://Assets/Audio/SFX/Land_Rail_4.wav"),
	preload("res://Assets/Audio/SFX/Land_Rail_5.wav")
]
@export var airborne_sfx: AudioStream = preload("res://Assets/Audio/SFX/Airborne.wav")
@export var moving_sfx: Array[AudioStream] = [
	preload("res://Assets/Audio/SFX/Moving_0.wav"),
	preload("res://Assets/Audio/SFX/Moving_1.wav"),
	preload("res://Assets/Audio/SFX/Moving_2.wav"),
]
@export var grind_sfx: Array[AudioStream] = [
	preload("res://Assets/Audio/SFX/grind_0.wav"),
	preload("res://Assets/Audio/SFX/grind_1.wav"),
	preload("res://Assets/Audio/SFX/grind_2.wav"),
	preload("res://Assets/Audio/SFX/grind_3.wav"),
	preload("res://Assets/Audio/SFX/grind_4.wav"),
	preload("res://Assets/Audio/SFX/grind_5.wav"),
	preload("res://Assets/Audio/SFX/grind_6.wav"),
	preload("res://Assets/Audio/SFX/grind_7.wav"),
	preload("res://Assets/Audio/SFX/grind_8.wav"),
	preload("res://Assets/Audio/SFX/grind_9.wav"),
	preload("res://Assets/Audio/SFX/grind_10.wav"),
	preload("res://Assets/Audio/SFX/grind_11.wav")
]

@export_group("Slow Mo")
@export var slowmo_time_scale: float = 0.1
@export var slowmo_max_time: float = 1.5
@export var slowmo_recharge_rate: float = 0.25
@export var slowmo_ui_fade_speed: float = 6.0
@export var slowmo_ui_inset_ratio: float = 0.03
@export var slowmo_fov_zoom: float = 10.0
@export var slowmo_wave_fade_speed: float = 6.0

@export_group("Debug Items")
@export var stand_height: float = 1.0;
@export var slide_height: float = 0.5;
@export var stand_offset: float = 1.0;
@export var slide_offset: float = 0.5;
@export var grind_visual_offset: float = 0.0

# Add the overlay variable
var live_overlay: LiveOverlay

var is_third_person: bool = true
var is_sliding: bool = false
var camera_look_input: Vector2 = Vector2.ZERO

var is_grinding: bool = false
var current_rail: Node = null # Using Node to avoid class_name issues in some environments
var rail_offset: float = 0.0
var rail_speed: float = 0.0
var rail_direction: int = 1 # 1 or -1

var current_board_lean: float = 0.0 # Tilt of board during turning or rotating
var is_ragdolling: bool = false
var ragdoll_rot_vel: Vector3 = Vector3.ZERO
var board_velocity: Vector3 = Vector3.ZERO
var initial_spawn_pos: Vector3

var jump_buffer_timer: float = 0.0
var landing_grace_timer: float = 0.0
var was_on_floor: bool = false
var pending_landing_sfx: bool = false
var pending_rail_landing: bool = false
var grind_sfx_play_id: int = 0
var was_sliding: bool = false
var slowmo_time_left: float = 0.0
var slowmo_active: bool = false
var slowmo_last_ticks: int = 0
var slowmo_last_ratio: float = 1.0
var slowmo_wave_alpha: float = 0.0

var _was_mouse_captured: bool = true
var _camera_pivot_pos: Vector3 = Vector3.ZERO

@onready var camera: Camera3D = get_parent().get_node("SpringArm3D/Camera3D")
@onready var spring_arm: SpringArm3D = get_parent().get_node("SpringArm3D")
@onready var board_node: Node3D = $Visual/BoardVisual
@onready var board_mesh: MeshInstance3D = $Visual/BoardVisual/Board
@onready var board_physics: RigidBody3D = $BoardPhysics
@onready var board_physics_shape: CollisionShape3D = $BoardPhysics/CollisionShape3D
@onready var body_mesh: MeshInstance3D = $Visual/Body
@onready var visual : Node3D = $Visual
@onready var body_collision: CollisionShape3D = $BodyCollision
@onready var grind_sparks: GPUParticles3D = $GrindSparks
@onready var speed_lines: ColorRect = $SpeedLines
@onready var slowmo_waves: ColorRect = $SlowMoWaves
@onready var slowmo_container: Control = $HUD/SlowMoContainer
@onready var slowmo_left: ColorRect = $HUD/SlowMoContainer/SlowMoLeft
@onready var slowmo_right: ColorRect = $HUD/SlowMoContainer/SlowMoRight
@onready var slowmo_base: ColorRect = $HUD/SlowMoContainer/SlowMoBase
@onready var slowmo_left_sparks: GPUParticles2D = $HUD/SlowMoContainer/SlowMoLeftSparks
@onready var slowmo_right_sparks: GPUParticles2D = $HUD/SlowMoContainer/SlowMoRightSparks
@onready var ragdoll_sfx_player: AudioStreamPlayer3D = $RagdollSfx
@onready var jump_sfx_player: AudioStreamPlayer3D = $JumpSfx
@onready var landing_sfx_player: AudioStreamPlayer3D = $LandingSfx
@onready var airborne_sfx_player: AudioStreamPlayer3D = $AirborneSfx
@onready var moving_sfx_player: AudioStreamPlayer3D = $MovingSfx
@onready var grind_sfx_player: AudioStreamPlayer3D = $GrindSfx

var outline_material: ShaderMaterial
var trick_outline_material: ShaderMaterial

const GRIND_SFX_END_TRIM: float = 0.1
const GRIND_SFX_NEXT_START: float = 0.1
const MOVING_SFX_MIN_SPEED: float = 0.5
const MOVING_SFX_SLIDE_PITCH_MIN: float = 0.8
const MOVING_SFX_SLIDE_PITCH_MAX: float = 0.9

@export_group("Rail Settings")
@export var rail_jump_force: float = 10.0
@export var rail_reacquisition_time: float = 0.25

var rail_cooldown_timer: float = 0.0
var last_rail_direction: Vector3 = Vector3.FORWARD
var smoothed_floor_normal: Vector3 = Vector3.UP
var default_body_rotation: Vector3 = Vector3.ZERO
var default_board_rotation: Vector3 = Vector3.ZERO
var default_body_scale: Vector3 = Vector3.ONE
var default_camera_basis: Basis = Basis.IDENTITY
var default_visual_pos: Vector3 = Vector3.ZERO
var default_visual_scale: Vector3 = Vector3.ONE
var default_collider_y: float = 0.0
var default_collider_height: float = 1.0
var visual_override_active: bool = false
var visual_override_basis: Basis = Basis.IDENTITY
var last_trick_id: String = ""
var trick_stale_count: int = 0


@export_group("Animation Settings")
@export var fps: float = 6.0
@export var idle_frames : Array[Mesh] = []
@export var walk_frames : Array[Mesh] = []
@export var trick_frames : Array[Mesh] = []

enum AnimState { IDLE, WALK }
var state: AnimState = AnimState.IDLE

var _frame_index: int = 0
var _time_accum: float = 0.0
var trick_pose_active: bool = false
var trick_pose_end_us: int = 0
var trick_rng: RandomNumberGenerator = RandomNumberGenerator.new()





# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	add_to_group("player")
	
	# Instantiate our new Overlay
	live_overlay = load("live_overlay.gd").new()
	add_child(live_overlay)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_was_mouse_captured = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	mouse_sensitivity = Global.mouse_sensitivity
	initial_spawn_pos = global_position
	default_body_rotation = body_mesh.rotation
	default_board_rotation = board_node.rotation
	default_camera_basis = camera.global_basis
	default_body_scale = body_mesh.scale
	default_visual_pos = visual.position
	default_visual_scale = visual.scale
	default_collider_y = body_collision.position.y
	
	var capsule := body_collision.shape as CapsuleShape3D
	if capsule:
		default_collider_height = capsule.height
	
	slowmo_time_left = slowmo_max_time
	slowmo_last_ticks = Time.get_ticks_usec()
	trick_rng.randomize()
	_deactivate_board_physics()
	if board_physics:
		add_collision_exception_with(board_physics)
		board_physics.add_collision_exception_with(self)
	visual_override_active = false
	visual_override_basis = Basis.IDENTITY
	last_trick_id = ""
	trick_stale_count = 0
	_reset_trick_staleness()
	if trick_resources.is_empty():
		trick_resources = [
			BoardSpinTrick.new(),
			KickflipTrick.new(),
			ForwardBackBoostTrick.new()
		]
	if not grind_sfx_player.finished.is_connected(_on_grind_sfx_finished):
		grind_sfx_player.finished.connect(_on_grind_sfx_finished)
	if not moving_sfx_player.finished.is_connected(_on_moving_sfx_finished):
		moving_sfx_player.finished.connect(_on_moving_sfx_finished)
	_apply_grind_sfx_setting()
	
	_set_state(AnimState.IDLE)
	
	var default_mesh = preload("res://Assets/models/Dog_Default.res")
	
	if(idle_frames.size() == 0): 
		idle_frames = [
			default_mesh,
			preload("res://Assets/models/Dog_Idle_1.res"),
			default_mesh,
			preload("res://Assets/models/Dog_Idle_2.res")
		]
		
	if(walk_frames.size() == 0): 
		walk_frames = [
			preload("res://Assets/models/Dog_Walk_1.res"),
			preload("res://Assets/models/Dog_Walk_2.res"),
			preload("res://Assets/models/Dog_Walk_3.res")
		]
		
	if(trick_frames.size() == 0):
		trick_frames = [
			preload("res://Assets/models/Dog_Trick_1.res"),
			preload("res://Assets/models/Dog_Trick_2.res"),
			preload("res://Assets/models/Dog_Trick_3.res"),
			preload("res://Assets/models/Dog_Trick_4.res")
		]
		
	# Initialize camera position relative to player
	update_camera_position()
	_init_camera_pivot()
	setup_outline()

func _init_camera_pivot() -> void:
	# Decouple camera pivot from player to avoid one-frame snaps on landing.
	spring_arm.top_level = true
	_camera_pivot_pos = spring_arm.global_position

func _get_movement_basis() -> Basis:
	if spring_arm:
		return Basis(Vector3.UP, spring_arm.global_rotation.y)
	return global_basis

func get_horizontal_boost_dir() -> Vector3:
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	if flat.length() < 0.001:
		var basis := _get_movement_basis()
		flat = Vector3(-basis.z.x, 0.0, -basis.z.z)
	return flat.normalized()

func _exit_tree() -> void:
	if Engine.time_scale != 1.0:
		Engine.time_scale = 1.0
	_reset_state_for_exit()

func _reset_state_for_exit() -> void:
	# Ensure we don't carry ragdoll/animation state across scene changes.
	reset_player()
	_deactivate_board_physics()
	is_sliding = false
	is_grinding = false
	current_rail = null
	rail_offset = 0.0
	rail_speed = 0.0
	rail_direction = 1
	rail_cooldown_timer = 0.0
	current_board_lean = 0.0
	for trick in trick_resources:
		if trick:
			trick.reset_trick_state()
	is_ragdolling = false
	ragdoll_rot_vel = Vector3.ZERO
	board_velocity = Vector3.ZERO
	trick_pose_active = false
	trick_pose_end_us = 0
	_time_accum = 0.0
	_frame_index = 0
	jump_buffer_timer = 0.0
	landing_grace_timer = 0.0
	was_on_floor = false
	slowmo_time_left = slowmo_max_time
	slowmo_active = false
	slowmo_last_ticks = Time.get_ticks_usec()
	slowmo_last_ratio = 1.0
	slowmo_wave_alpha = 0.0
	visual_override_active = false
	visual_override_basis = Basis.IDENTITY
	last_trick_id = ""
	trick_stale_count = 0
	visual.position = default_visual_pos
	visual.scale = default_visual_scale
	body_mesh.rotation = default_body_rotation
	body_mesh.scale = default_body_scale
	
func _set_state(new_state: AnimState) -> void:
	if new_state == state:
		return

	state = new_state
	_frame_index = 0
	_time_accum = 0.0

	var frames := _get_active_frames()
	_apply_frame(frames)	
	
func _get_active_frames() -> Array[Mesh]:
	if state == AnimState.IDLE:
		return idle_frames
	if state == AnimState.WALK:
		return walk_frames
		
	return idle_frames	
	
	
	
func _apply_frame(frames: Array[Mesh]) -> void:
	
	if is_ragdolling:
		return
		
	if frames.is_empty():
		return
	_frame_index = clampi(_frame_index, 0, frames.size() - 1)
	body_mesh.mesh = frames[_frame_index]
	body_mesh.scale = default_body_scale
	
func setup_outline() -> void:
	outline_material = ShaderMaterial.new()
	outline_material.shader = load("res://Assets/Shaders/outline.gdshader")
	outline_material.set_shader_parameter("outline_color", Color.GREEN)
	outline_material.set_shader_parameter("outline_width", 4)
	trick_outline_material = ShaderMaterial.new()
	trick_outline_material.shader = outline_material.shader
	trick_outline_material.set_shader_parameter("outline_color", Color.GOLD)
	trick_outline_material.set_shader_parameter("outline_width", 4)
	
	# Add as a second pass to the board mesh's material
	var material = board_mesh.get_active_material(0)
	if not material:
		# If no material exists, create a simple StandardMaterial3D to hold the next_pass
		material = StandardMaterial3D.new()
		board_mesh.set_surface_override_material(0, material)
	else:
		# If the material is shared, we should probably duplicate it to avoid affecting other objects
		# but for a player board it's likely unique or fine to modify.
		# However, next_pass modification on a shared material will affect all instances.
		# To be safe, we use a unique material.
		board_mesh.set_surface_override_material(0, material.duplicate())
		material = board_mesh.get_active_material(0)
		
	material.next_pass = outline_material

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Rotate the player horizontally (yaw)
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate the camera vertically (pitch)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	if event.is_action_pressed("toggle_camera"):
		toggle_camera_mode()

	if event.is_action_pressed("toggle_overlay"):
		if live_overlay:
			live_overlay.visible = !live_overlay.visible

	if event.is_action_pressed("ui_cancel"):
		show_settings(false)

func _is_settings_open() -> bool:
	var scene := get_tree().current_scene
	if not scene:
		return false
	return scene.has_node("Settings")

func show_settings(show_pointer_lock_hint: bool) -> void:
	if _is_settings_open():
		return
	var settings_scene = load("res://Settings.tscn")
	if settings_scene:
		var settings_instance = settings_scene.instantiate()
		if settings_instance and settings_instance.has_method("set"):
			for item in settings_instance.get_property_list():
				if item.name == "show_pointer_lock_hint":
					settings_instance.set("show_pointer_lock_hint", show_pointer_lock_hint)
					break
		add_sibling(settings_instance) # Add to parent so it's not affected by player's transform
	
# First person camera is no longer a valid option :)		
func toggle_camera_mode() -> void:
		#is_third_person = !is_third_person
		update_camera_position()	
		
		
func update_camera_position() -> void:
		if is_third_person:
			# Move camera back for 3rd person
			spring_arm.spring_length = third_person_distance
			camera.position = third_person_offset
		else:
			spring_arm.spring_length = 0.0
			# Reset to 1st person
			camera.position = Vector3(0, 0, -camera_distance)	
			
func _process(delta: float) -> void:
	var is_captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if _was_mouse_captured and not is_captured and not _is_settings_open():
		show_settings(true)
	_was_mouse_captured = is_captured

	if trick_pose_active:
		if Time.get_ticks_usec() < trick_pose_end_us:
			_update_slowmo_ui(delta)
			return
		trick_pose_active = false
		_time_accum = 0.0
		_set_body_outline(false)

	# 1) Decide which animation should be active based on input
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var wants_walk := input_dir.length() > 0.1

	_set_state(AnimState.WALK if wants_walk && !is_grinding && !is_sliding else AnimState.IDLE)

	# 2) Advance frame timer and update the mesh at ~12 FPS
	var frames := _get_active_frames()
	if frames.is_empty():
		return

	_time_accum += delta
	var frame_time := 1.0 / maxf(fps, 0.001)

	# Advance as many frames as needed (handles low FPS without slowing animation time)
	while _time_accum >= frame_time:
		_time_accum -= frame_time
		_frame_index = (_frame_index + 1) % frames.size()

	_apply_frame(frames)
	_update_slowmo_ui(delta)

func _physics_process(delta: float) -> void:
	_update_slowmo(delta)

	if is_ragdolling:
		apply_ragdoll_physics(delta)
		return	
		
	_update_camera_pivot(delta)
	update_visual_alignment(delta)	

	if rail_cooldown_timer > 0:
		rail_cooldown_timer -= delta

	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	if landing_grace_timer > 0:
		landing_grace_timer -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	if jump_buffer_timer > 0:
		if is_grinding:
			jump_buffer_timer = 0
			jump_exit_rail()
			velocity.y = jump_velocity
			_play_jump_sfx()
			_start_airborne_sfx()
		elif is_on_floor():
			jump_buffer_timer = 0
			velocity.y = jump_velocity
			_play_jump_sfx()
			_start_airborne_sfx()
			if !is_sliding:
				# Diagonal Momentum Exploit
				var input_dir_exploit: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
				if abs(input_dir_exploit.x) > 0.5 and abs(input_dir_exploit.y) > 0.5:
					var boost_vec: Vector3 = (_get_movement_basis() * Vector3(input_dir_exploit.x, 0, input_dir_exploit.y)).normalized()
					velocity += boost_vec * diagonal_boost	

	# Landing detection for grace period
	if is_on_floor() and not was_on_floor:
		landing_grace_timer = landing_grace_time
		pending_landing_sfx = true
		pending_rail_landing = _is_rail_landing_surface()
		_stop_airborne_sfx()
	
	was_on_floor = is_on_floor()

	# Grinding logic is here, but honestly I feel like a good portion of it should be in the GrindRail script.
	# But thats what game jamming is all about. Sloppy code to get it out the door.
	if is_grinding:
		apply_grind_movement(delta)
		handle_trick_input(delta) # Allow rotation while grinding
		update_outline_color()
		return
	else:
		if not is_on_floor():
			handle_trick_input(delta)
		
		# Landing check
		if is_on_floor() and not is_grinding:
			# During rail cooldown, skip alignment checks entirely.
			if rail_cooldown_timer <= 0 and is_falling_on_rail():
				check_for_rails()
			elif rail_cooldown_timer <= 0:
				var success: bool = check_landing_alignment()
				if !success: return
	
	if pending_landing_sfx and not is_ragdolling:
		_play_landing_sfx(pending_rail_landing)
		pending_landing_sfx = false
		pending_rail_landing = false
				
	if rail_cooldown_timer <= 0:
		check_for_rails()	

	# Add the gravity.
	if not is_on_floor() or is_sliding:
		velocity.y -= gravity * delta

	# Handle Slide input
	if Input.is_action_pressed("slide"):
		is_sliding = true
	else:
		is_sliding = false

	var input_dir: Vector3 = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir -= _get_movement_basis().z
	if Input.is_action_pressed("move_backward"):
		input_dir += _get_movement_basis().z
	if Input.is_action_pressed("move_left"):
		input_dir -= _get_movement_basis().x
	if Input.is_action_pressed("move_right"):
		input_dir += _get_movement_basis().x
	
	var direction: Vector3 = input_dir

	if is_sliding:
		apply_sliding_movement(direction, delta)
	else:
		apply_standard_movement(direction, delta)

	handle_dynamic_snapping()

	move_and_slide()
	_update_movement_sfx()
	update_speed_effects(delta)
	update_outline_color()

func _update_camera_pivot(delta: float) -> void:
	if not spring_arm:
		return
	var target := global_position + Vector3(0.0, camera_height, 0.0)
	if is_third_person:
		target.y += 2.0
	# Keep camera yaw aligned with player while pivot position is smoothed.
	spring_arm.global_rotation = Vector3(0.0, global_rotation.y + PI, 0.0)
	var alpha_h := 1.0 - exp(-camera_follow_speed * delta)
	var alpha_v := 1.0 - exp(-camera_vertical_speed * delta)
	_camera_pivot_pos.x = lerp(_camera_pivot_pos.x, target.x, alpha_h)
	_camera_pivot_pos.z = lerp(_camera_pivot_pos.z, target.z, alpha_h)
	_camera_pivot_pos.y = lerp(_camera_pivot_pos.y, target.y, alpha_v)
	spring_arm.global_position = _camera_pivot_pos

func update_outline_color() -> void:
	if not outline_material:
		return
		
	var target_color: Color = Color.GREEN
	
	if not is_on_floor() and _has_started_spin():
		var total_spin := _get_total_spin_radians()
		var total_flip := _get_total_flip_radians()
		var remainder = fmod(abs(total_spin), PI)
		var flip_rem = fmod(abs(total_flip), TAU)
		if (remainder < 0.1 or remainder > PI - 0.1) and (flip_rem < 0.1 or flip_rem > TAU - 0.1): 
			target_color = Color.GOLD
		else:
			target_color = Color.DARK_GRAY
	
	outline_material.set_shader_parameter("outline_color", target_color)

func update_speed_effects(delta: float) -> void:
	var current_speed = velocity.length()
	var speed_ratio = 0.0;
	if(current_speed > max_speed):
		speed_ratio = clamp(current_speed / speed_for_max_fov, 0.0, 1.0)
	
	# FOV Zoom
	var target_fov = base_fov + (max_fov_boost * speed_ratio)
	if slowmo_active:
		target_fov -= slowmo_fov_zoom
	camera.fov = lerp(camera.fov, target_fov, 5.0 * delta)
	
	# Speed Lines
	if speed_lines:
		if slowmo_active:
			speed_lines.visible = false
		else:
			var speed_threshold = max_speed * 1.5
			if current_speed > speed_threshold:
				speed_lines.visible = true
				var wind_ratio = clamp((current_speed - speed_threshold) / (speed_for_max_fov - speed_threshold), 0.0, 1.0)
				# We can animate the line density or alpha via shader parameters
				speed_lines.material.set_shader_parameter("line_color", Color(1.0, 1.0, 1.0, wind_ratio * 0.3))
			else:
				speed_lines.visible = false

	if slowmo_waves:
		var target_alpha := 1.0 if slowmo_active else 0.0
		slowmo_wave_alpha = move_toward(slowmo_wave_alpha, target_alpha, slowmo_wave_fade_speed * delta)
		slowmo_waves.visible = slowmo_wave_alpha > 0.001
		slowmo_waves.modulate = Color(1.0, 1.0, 1.0, slowmo_wave_alpha)

func update_visual_alignment(delta: float) -> void:
	var target_up: Vector3 = Vector3.UP
	var rail_fwd_dir: Vector3 = Vector3.ZERO
	
	if is_grinding and current_rail:
		# Get the rail's forward direction
		var rail_fwd = current_rail.get_direction_at_offset(rail_offset).normalized()
		rail_fwd_dir = rail_fwd * rail_direction
		# Use the world UP to find a consistent 'right' vector for the rail
		var rail_right = rail_fwd.cross(Vector3.UP).normalized()
		# Re-calculate 'up' based on the rail's forward and right
		target_up = rail_right.cross(rail_fwd).normalized()
	elif is_on_floor():
		var raw_normal = get_floor_normal()
		# Smooth the normal to prevent "spasms" on bumpy terrain
		smoothed_floor_normal = smoothed_floor_normal.lerp(raw_normal, 10.0 * delta).normalized()
		target_up = smoothed_floor_normal
	else:
		smoothed_floor_normal = smoothed_floor_normal.lerp(Vector3.UP, 2.0 * delta).normalized()
		target_up = smoothed_floor_normal	
	
	# Create a basis that points 'up' towards the surface normal 
	# but keeps our forward direction as much as possible
	var curr_basis: Basis = visual.global_transform.basis.orthonormalized()
	var target_basis: Basis = Basis()
	
	# Determine the "Forward" direction based on input
	var target_fwd: Vector3 = -_get_movement_basis().z # Default to forward	
	
	if is_grinding and current_rail:
		target_fwd = rail_fwd_dir
	else:
		var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		if input_dir.length() > 0.1:
			# Map the 2D input to the player's 3D orientation
			var world_input := (_get_movement_basis() * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			target_fwd = world_input
	
	# Calculate the new right and forward vectors based on the new Up
	if target_up.length() < 0.001:
		target_up = Vector3.UP
	if target_fwd.length() < 0.001:
		target_fwd = -_get_movement_basis().z
	target_basis.y = target_up
	var right := target_basis.y.cross(target_fwd)
	if right.length() < 0.001:
		var fallback_fwd := Vector3.FORWARD
		if abs(fallback_fwd.dot(target_basis.y)) > 0.9:
			fallback_fwd = Vector3.RIGHT
		right = target_basis.y.cross(fallback_fwd)
	target_basis.x = right.normalized()
	target_basis.z = target_basis.x.cross(target_basis.y).normalized()
	
	# Smoothly interpolate the rotation
	var lerp_speed: float = 15.0
	var new_basis := curr_basis.slerp(target_basis.orthonormalized(), lerp_speed * delta).orthonormalized()
	if visual_override_active:
		var base_basis := target_basis.orthonormalized()
		new_basis = (base_basis * visual_override_basis).orthonormalized()

	var target_visual_global_pos: Vector3 = global_position + (global_basis * default_visual_pos)
	if is_grinding and current_rail:
		var rail_radius: float = 0.0
		if current_rail.has_method("get_rail_radius"):
			rail_radius = current_rail.get_rail_radius()
		target_visual_global_pos = global_position + (target_up * (rail_radius + grind_visual_offset))
	visual.global_transform = Transform3D(new_basis, target_visual_global_pos)
#	if !is_third_person:
#		var camera_basis: Basis = camera.global_basis
#		# Create a basis specifically for the camera where Forward is -target_fwd
#		# This aligns the camera's -Z with the player's intended forward direction
#		var cam_target: Basis = Basis()
#		cam_target.y = target_up
#		cam_target.x = cam_target.y.cross(-target_fwd).normalized()
#		cam_target.z = cam_target.x.cross(cam_target.y).normalized()
#
#		camera.global_basis = camera_basis.slerp(cam_target, lerp_speed * delta).orthonormalized()

	var input_x: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	
	# If we're sliding, we might want to invert or dampen the lean, 
	# but for standard movement, tilting into the turn feels best.
	var target_lean_player: float = -input_x * lean_intensity_player
	var target_lean_board: float = -input_x * lean_intensity_board

	# Apply lean to the body (heavier)
	body_mesh.rotation.z = lerp_angle(body_mesh.rotation.z, target_lean_player, lean_speed * delta)

	# Apply lean to the board (subtle)
	current_board_lean = lerp_angle(current_board_lean, target_lean_board, lean_speed * delta)
	board_node.rotation.z = current_board_lean + _get_total_flip_radians()

	var target_visual_scale := default_visual_scale
	if is_sliding:
		target_visual_scale.y *= slide_visual_z_scale
	visual.scale = visual.scale.lerp(target_visual_scale, 10.0 * delta)

	var capsule := body_collision.shape as CapsuleShape3D
	if capsule:
		var target_height := default_collider_height
		var target_collider_y := default_collider_y
		if is_sliding:
			target_height = default_collider_height * slide_collider_height_ratio
			var height_delta := default_collider_height - target_height
			target_collider_y = default_collider_y - (height_delta * 0.5)
		capsule.height = lerp(capsule.height, target_height, 10.0 * delta)
		body_collision.position.y = lerp(body_collision.position.y, target_collider_y, 10.0 * delta)
	
	#var target_height: float = slide_height if is_sliding else stand_height
	#var target_y_pos: float = slide_offset if is_sliding else stand_offset # Adjust to keep feet on board

	#body_mesh.scale.y = lerp(body_mesh.scale.y, target_height, 10.0 * delta)
	#body_mesh.position.y = lerp(body_mesh.position.y, target_y_pos, 10.0 * delta)	
	
func handle_dynamic_snapping() -> void:
	if not is_on_floor():
		floor_snap_length = 0.0
		return
	var current_speed: float = velocity.length()
	
	# Default snapping to keep us grounded
	floor_snap_length = clamp(current_speed * 0.1, 0.1, 2.0)
	
	if is_on_floor():
		var floor_normal: Vector3 = get_floor_normal()
		var velocity_dot_normal: float = velocity.dot(floor_normal)
		
		# If we're moving fast and the floor normal is opposing our movement
		if velocity_dot_normal < 0.0 and current_speed > max_speed:
			# "Cheat" by projecting the velocity onto the plane of the ramp.
			# This ensures we are moving 'up' the ramp's angle exactly, 
			# so when we leave the edge, we have the correct vertical momentum.
			var plane_velocity: Vector3 = velocity.slide(floor_normal).normalized()
			velocity = plane_velocity * current_speed
			
			floor_snap_length = clamp(current_speed * 0.1, 0.2, 0.9)


	
func apply_slope_gravity(delta: float) -> void:
	if is_on_floor():
		var floor_normal: Vector3 = get_floor_normal()
		if floor_normal != Vector3.UP:
			var slope_dir: Vector3 = Vector3(0, -1, 0).slide(floor_normal).normalized()
			var steepness: float = 1.0 - floor_normal.dot(Vector3.UP)
			
			var momentum_factor: float = 1.0
			var current_speed: float = velocity.length()
			
			if current_speed > max_speed:
				# Dot product: 1.0 if moving with the slope (down), -1.0 if moving against (up)
				var slope_dot: float = velocity.normalized().dot(slope_dir)
				
				# If we are moving against the slope's pull (climbing)
				if slope_dot < 10:
					# Scale down infl-6ence based on speed so we don't lose momentum instantly
					momentum_factor = clamp(max_speed / current_speed, 0.1, 1.0)
			
			var base_slide = slope_dir * gravity * steepness * delta * momentum_factor
			
			if is_sliding:
				base_slide *= slope_slide_gravity_modifier
			else:
				base_slide *= slope_regular_gravity_modifier
			
			velocity += base_slide


func handle_trick_input(_delta: float) -> void:
	for trick in trick_resources:
		if trick:
			trick.process_input(self, _delta)

	for trick in trick_resources:
		if trick and trick.check_completion(self, _delta):
			trick.grant_reward(self)

	for trick in trick_resources:
		if trick:
			trick.apply_updates(self, _delta)

func _get_total_spin_radians() -> float:
	var total := 0.0
	for trick in trick_resources:
		if trick:
			total += trick.get_spin_radians()
	return total

func _get_total_flip_radians() -> float:
	var total := 0.0
	for trick in trick_resources:
		if trick:
			total += trick.get_flip_radians()
	return total

func _has_started_spin() -> bool:
	for trick in trick_resources:
		if trick and trick.get_started_spin():
			return true
	return false

func set_visual_override_basis(basis: Basis) -> void:
	visual_override_active = true
	visual_override_basis = basis

func clear_visual_override() -> void:
	visual_override_active = false
	visual_override_basis = Basis.IDENTITY

func consume_trick_stale(trick: TrickResource) -> float:
	var trick_id := trick.display_name
	if trick_id == last_trick_id:
		trick_stale_count += 1
	else:
		last_trick_id = trick_id
		trick_stale_count = 0
	if trick_stale_count >= 6:
		return 0.0
	return pow(trick_stale_factor, trick_stale_count)

func _reset_trick_staleness() -> void:
	last_trick_id = ""
	trick_stale_count = 0
			
func apply_spin_boost(multiplier: float = 1.0) -> void:
	if is_grinding:
		# Boost the speed specifically on the rail path
		rail_speed += spin_boost_amount * multiplier
		# Update velocity immediately so visual effects/physics stay in sync
		velocity = velocity.normalized() * rail_speed
	else:
		# Apply standard air boost
		var boost_dir := get_horizontal_boost_dir()
		velocity += boost_dir * spin_boost_amount * multiplier
	start_trick_pose()

func start_trick_pose() -> void:
	if is_ragdolling or trick_frames.is_empty():
		return
	
	# TRIGGER OVERLAY for generic tricks
	if live_overlay:
		live_overlay.trigger_trick_reaction()
		
	trick_pose_active = true
	trick_pose_end_us = Time.get_ticks_usec() + 500_000
	var frame_index := trick_rng.randi_range(0, trick_frames.size() - 1)
	body_mesh.mesh = trick_frames[frame_index]
	body_mesh.scale = default_body_scale
	_set_body_outline(true)

func _set_body_outline(active: bool) -> void:
	if not trick_outline_material:
		return
	var mesh := body_mesh.mesh
	var surface_count := mesh.get_surface_count() if mesh else 1
	for surface_idx in range(surface_count):
		var material = body_mesh.get_surface_override_material(surface_idx)
		if not material:
			material = body_mesh.get_active_material(surface_idx)
			material = material.duplicate() if material else StandardMaterial3D.new()
			body_mesh.set_surface_override_material(surface_idx, material)
		if active:
			material.next_pass = trick_outline_material
		else:
			material.next_pass = null
	
func check_landing_alignment() -> bool:
	# Check if rotation is a multiple of 180 degrees (PI radians)
	# We use a small epsilon (0.2) to be forgiving
	var total_spin := _get_total_spin_radians()
	var total_flip := _get_total_flip_radians()
	var normalized_spin: float = fmod(abs(total_spin), PI)
	var is_aligned: bool = normalized_spin < 0.2 or normalized_spin > PI - 0.2

	var normalized_flip: float = fmod(abs(total_flip), TAU)
	if normalized_flip > 0.2 and normalized_flip < TAU - 0.2:
		is_aligned = false

	var bail_severity := 0.0
	for trick in trick_resources:
		if trick:
			bail_severity += trick.check_validity(self, 0.0)
	bail_severity = clamp(bail_severity, 0.0, 1.0)

	if not is_aligned or bail_severity > 0.0:
		for trick in trick_resources:
			if trick:
				trick.on_landing(false)
		_reset_trick_staleness()
		start_ragdoll(bail_severity)
		return false
	else:
		for trick in trick_resources:
			if trick:
				trick.on_landing(true)
		_reset_trick_staleness()
		# Landed successfully: Snap board to nearest 180 and reset counter
		board_node.rotation.y = default_board_rotation.y # Or snap to PI if facing backward
		return true
		
func is_falling_on_rail() -> bool:
	return is_sliding and _find_rail_from_sphere_cast(board_node.global_position) != null

func start_ragdoll(bail_severity: float = 1.0) -> void:
	if is_ragdolling:
		return
	# TRIGGER OVERLAY for bails
	if live_overlay:
		live_overlay.trigger_bail_reaction()
		
	is_ragdolling = true
	_prepare_ragdoll_pose()
	pending_landing_sfx = false
	pending_rail_landing = false
	_stop_grind_sfx()
	_stop_airborne_sfx()
	_stop_moving_sfx()
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	_play_ragdoll_bail_sfx()
	
	# 1. Calculate how "bad" the landing was (0.0 to 1.0)
	bail_severity = clamp(bail_severity, 0.0, 1.0)
	
	# 2. Set rotational momentum based on severity and speed
	# We'll tumble on X and Z for a chaotic look
	ragdoll_rot_vel = Vector3(
		randf_range(-2.0, 2.0) * bail_severity,
		0,
		randf_range(-2.0, 2.0) * bail_severity
	)
	
	# Detach the board
	var kick_dir := -velocity.normalized()
	if kick_dir == Vector3.ZERO:
		kick_dir = global_basis.z
	board_velocity = kick_dir * maxf(velocity.length(), 1.0) * 2.0 + Vector3.UP * 2.5

	# Reparent to physics body so it can collide while detached.
	var board_transform := _get_board_drop_transform(board_node.global_transform)
	var board_spin := Vector3(
		trick_rng.randf_range(-0.6, 0.6),
		trick_rng.randf_range(-0.4, 0.4),
		trick_rng.randf_range(-0.6, 0.6)
	)
	_activate_board_physics(board_transform, board_velocity, board_spin)
	if board_node.get_parent() != board_physics:
		board_node.get_parent().remove_child(board_node)
		board_physics.add_child(board_node)
	board_node.transform = Transform3D.IDENTITY
	
	# 3. Apply the fling
	velocity.y = (horizontal_speed * 0.2) + 2.0

func _prepare_ragdoll_pose() -> void:
	var facing_yaw := global_basis.get_euler().y
	clear_visual_override()
	body_mesh.rotation = default_body_rotation
	board_node.rotation = default_board_rotation
	body_collision.rotation = Vector3.ZERO
	visual.global_basis = Basis(Vector3.UP, facing_yaw)
	global_position += Vector3.UP * 0.2

func _activate_board_physics(board_transform: Transform3D, initial_velocity: Vector3, angular_velocity: Vector3) -> void:
	if not board_physics:
		return
	add_collision_exception_with(board_physics)
	board_physics.add_collision_exception_with(self)
	var world: Node = get_parent()
	if board_physics.get_parent() != world:
		board_physics.get_parent().remove_child(board_physics)
		world.add_child(board_physics)
	board_physics.global_transform = board_transform
	board_physics.linear_velocity = Vector3.ZERO
	board_physics.angular_velocity = Vector3.ZERO
	board_physics.freeze = false
	board_physics.sleeping = false
	if board_physics_shape:
		board_physics_shape.disabled = false
	board_physics.apply_central_impulse(initial_velocity)
	board_physics.apply_torque_impulse(angular_velocity)

func _deactivate_board_physics() -> void:
	if not board_physics:
		return
	board_physics.freeze = true
	board_physics.sleeping = true
	board_physics.linear_velocity = Vector3.ZERO
	board_physics.angular_velocity = Vector3.ZERO
	if board_physics_shape:
		board_physics_shape.disabled = true
	if board_physics.get_parent() != self:
		board_physics.get_parent().remove_child(board_physics)
		add_child(board_physics)
	board_physics.transform = Transform3D.IDENTITY

func _get_board_drop_transform(original: Transform3D) -> Transform3D:
	var start := original.origin + Vector3.UP * 1.0
	var end := original.origin + Vector3.DOWN * 4.0
	var query := PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [self, board_physics, board_node]
	var space_state := get_world_3d().direct_space_state
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return original
	var hit_pos: Vector3 = result["position"]
	var hit_normal: Vector3 = result["normal"].normalized()
	var forward := original.basis.z.slide(hit_normal).normalized()
	if forward.length() < 0.01:
		forward = Vector3.FORWARD
	var new_basis: Basis = Basis.looking_at(forward, hit_normal)
	var offset := hit_normal * 0.4
	return Transform3D(new_basis, hit_pos + offset)

func _play_ragdoll_bail_sfx() -> void:
	if ragdoll_bail_sfx.is_empty():
		return
	var clip_index := trick_rng.randi_range(0, ragdoll_bail_sfx.size() - 1)
	_play_sfx_with_variation(ragdoll_sfx_player, ragdoll_bail_sfx[clip_index], 0.93, 1.02, -2.0, 0.5)

func _play_jump_sfx() -> void:
	if jump_sfx.is_empty():
		return
	var clip_index := trick_rng.randi_range(0, jump_sfx.size() - 1)
	_play_sfx_with_variation(jump_sfx_player, jump_sfx[clip_index], 0.97, 1.05, -1.5, 0.5)

func _play_landing_sfx(use_rail: bool) -> void:
	var clips := land_rail_sfx if use_rail else landing_sfx
	if clips.is_empty():
		return
	var clip_index := trick_rng.randi_range(0, clips.size() - 1)
	_play_sfx_with_variation(landing_sfx_player, clips[clip_index], 0.95, 1.03, -1.5, 0.5)

func _start_grind_sfx() -> void:
	if Global.disable_grind_sfx:
		return
	if grind_sfx.is_empty():
		return
	_play_grind_sfx_once(0.0)

func _stop_grind_sfx() -> void:
	if grind_sfx_player.playing:
		grind_sfx_player.stop()
	grind_sfx_player.stream = null
	grind_sfx_play_id += 1

func _start_airborne_sfx() -> void:
	if not airborne_sfx:
		return
	if airborne_sfx_player.playing:
		return
	var stream := airborne_sfx
	if stream is AudioStreamWAV:
		var wav := (stream as AudioStreamWAV).duplicate()
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
		stream = wav
	_play_sfx_with_variation(airborne_sfx_player, stream, 0.98, 1.02, -10.0, -6.0)

func _stop_airborne_sfx() -> void:
	if airborne_sfx_player.playing:
		airborne_sfx_player.stop()
	airborne_sfx_player.stream = null

func _start_moving_sfx() -> void:
	if moving_sfx.is_empty():
		return
	if moving_sfx_player.playing:
		return
	_play_moving_sfx_once()

func _stop_moving_sfx() -> void:
	if moving_sfx_player.playing:
		moving_sfx_player.stop()
	moving_sfx_player.stream = null

func _play_moving_sfx_once(pitch_min: float = 0.98, pitch_max: float = 1.02) -> void:
	if moving_sfx.is_empty():
		return
	var clip_index := trick_rng.randi_range(0, moving_sfx.size() - 1)
	var stream := moving_sfx[clip_index]
	_play_sfx_with_variation(moving_sfx_player, stream, pitch_min, pitch_max, -3.0, 0.0)

func _play_grind_sfx_once(start_offset: float) -> void:
	if grind_sfx.is_empty():
		return
	grind_sfx_play_id += 1
	var play_id := grind_sfx_play_id
	var clip_index := trick_rng.randi_range(0, grind_sfx.size() - 1)
	var stream := grind_sfx[clip_index]
	_play_sfx_with_variation(grind_sfx_player, stream, 0.98, 1.02, -36.0, -18.0, start_offset)
	var clip_length := stream.get_length()
	var play_duration := maxf(0.0, clip_length - GRIND_SFX_END_TRIM - start_offset)
	_schedule_grind_sfx_stop(play_id, play_duration)

func _on_grind_sfx_finished() -> void:
	_handle_grind_sfx_end()

func _on_moving_sfx_finished() -> void:
	if _should_play_moving_sfx():
		_play_moving_sfx_once()

func _apply_grind_sfx_setting() -> void:
	if not grind_sfx_player:
		return
	if Global.disable_grind_sfx:
		grind_sfx_player.stop()
		grind_sfx_player.volume_db = -80.0
	else:
		grind_sfx_player.volume_db = 0.0

func _handle_grind_sfx_end() -> void:
	if is_grinding:
		_play_grind_sfx_once(GRIND_SFX_NEXT_START)

func _update_movement_sfx() -> void:
	if is_ragdolling:
		_stop_airborne_sfx()
		_stop_moving_sfx()
		_was_sliding_state_update()
		return
	if _should_play_airborne_sfx():
		_stop_moving_sfx()
		_start_airborne_sfx()
	else:
		_stop_airborne_sfx()
		if _should_play_moving_sfx():
			_start_moving_sfx()
			if is_sliding and not was_sliding:
				_stop_moving_sfx()
				_play_moving_sfx_once(MOVING_SFX_SLIDE_PITCH_MIN, MOVING_SFX_SLIDE_PITCH_MAX)
		else:
			_stop_moving_sfx()
	_was_sliding_state_update()

func _was_sliding_state_update() -> void:
	was_sliding = is_sliding

func _should_play_airborne_sfx() -> bool:
	return not is_on_floor() and not is_grinding

func _should_play_moving_sfx() -> bool:
	if is_grinding or not is_on_floor():
		return false
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	return horizontal_speed > MOVING_SFX_MIN_SPEED

func _schedule_grind_sfx_stop(play_id: int, duration: float) -> void:
	if duration <= 0.0:
		return
	await get_tree().create_timer(duration).timeout
	if play_id != grind_sfx_play_id:
		return
	if not is_grinding or not grind_sfx_player.playing:
		return
	grind_sfx_player.stop()
	_handle_grind_sfx_end()

func _play_sfx_with_variation(
	player: AudioStreamPlayer3D,
	stream: AudioStream,
	pitch_min: float,
	pitch_max: float,
	vol_min_db: float,
	vol_max_db: float,
	start_pos: float = 0.0
) -> void:
	player.stream = stream
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.volume_db = randf_range(vol_min_db, vol_max_db)
	player.play(start_pos)

func _is_rail_landing_surface() -> bool:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var from_pos := global_position + Vector3.UP * 0.1
	var to_pos := from_pos + Vector3.DOWN * 1.5
	var query := PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	query.exclude = [self]
	var result: Dictionary = space_state.intersect_ray(query)
	if result.is_empty() or not result.has("collider"):
		return false
	var collider: Node = result["collider"] as Node
	if collider is Node:
		var parent := collider.get_parent()
		if parent and String(parent.name).begins_with("GR"):
			return true
		if String(collider.name).begins_with("GR"):
			return true
	return false
	

func apply_ragdoll_physics(delta: float) -> void:
	# Move with current momentum but apply heavy friction
	velocity.y -= gravity * delta
	
	if not _is_board_physics_active():
		board_velocity.y -= gravity * delta
		board_node.global_position += board_velocity * delta
		board_node.rotate_x(10.0 * delta) # Just make it spin wildly	
	
	# 1. Apply rotational momentum while in the air
	if not is_on_floor():
		body_mesh.rotate_x(ragdoll_rot_vel.x * delta)
		body_mesh.rotate_z(ragdoll_rot_vel.z * delta)
		# Match collision to visual
		body_collision.rotation = body_mesh.rotation
	
	var horizontal_vel: Vector2 = Vector2(velocity.x, velocity.z)
	# Only apply heavy friction if we are grinding against the floor
	# Otherwise, no friction to preserve the fling
	var current_friction: float = ragdoll_friction if is_on_floor() else 0.0
	
	if current_friction > 0:
		horizontal_vel = horizontal_vel.move_toward(Vector2.ZERO, current_friction * delta)
	
	velocity.x = horizontal_vel.x
	velocity.z = horizontal_vel.y

	move_and_slide()
	# Reset if we've come to a stop
	if is_on_floor() and velocity.length() < reset_speed_threshold:
		reset_player()

func _is_board_physics_active() -> bool:
	return board_physics and not board_physics.freeze and board_physics_shape and not board_physics_shape.disabled
	
	

func reset_player() -> void:
	is_ragdolling = false
	pending_landing_sfx = false
	pending_rail_landing = false
	_stop_grind_sfx()
	_stop_airborne_sfx()
	_stop_moving_sfx()
	for trick in trick_resources:
		if trick:
			trick.reset_trick_state()
	if board_node.get_parent() != visual:
		board_node.get_parent().remove_child(board_node)
		visual.add_child(board_node)
		
	board_node.position = Vector3.ZERO # Reset to original local position
	board_node.rotation = default_board_rotation
	_deactivate_board_physics()
	
	body_mesh.rotation = default_body_rotation
	body_collision.rotation = Vector3.ZERO
	velocity = Vector3.ZERO
	global_position = initial_spawn_pos # Or nearest checkpoint


func apply_standard_movement(direction: Vector3, delta: float) -> void:

	apply_slope_gravity(delta)
	
	if direction:
		var horizontal_vel: Vector2 = Vector2(velocity.x, velocity.z)
		var current_speed: float = horizontal_vel.length()
		
		var target_velocity: Vector3 = direction * max_speed
		var target_vel_2d: Vector2 = Vector2(target_velocity.x, target_velocity.z)
		
		var current_acceleration: float = acceleration
		
		# While airborne, we don't want to lose speed magnitude if we're already above max_speed
		if not is_on_floor():
			if current_speed > max_speed:
				# If we are airborne and moving fast, we don't want to drag the speed down to max_speed.
				# We adjust target_vel_2d length to match current_speed if airborne and fast.
				# This allows steering without losing momentum.
				target_vel_2d = target_vel_2d.normalized() * current_speed
		
		# Check if we are on the ground and trying to pivot/turn sharply
		if is_on_floor():
			var floor_normal: Vector3 = get_floor_normal()
			# dot product: 1 if same direction, 0 if perpendicular, -1 if opposite
			var movement_dot: float = horizontal_vel.normalized().dot(target_vel_2d.normalized())
			
			# If dot < 0.2 (perpendicular or opposing), we apply a massive acceleration boost
			if movement_dot < 0.0:
				current_acceleration *= 2.0 # Snappy pivot factor
			
			# SLOPE MOMENTUM LOGIC:
			# If we are moving fast (near or above max_speed)
			if current_speed > max_speed * 0.9:
				var slope_dir: Vector3 = Vector3(0, -1, 0).slide(floor_normal).normalized()
				var slope_dot: float = direction.dot(slope_dir)

				# If we are pushing in the direction of the downward slope
				if slope_dot > 0.2:
					# Increase max speed target to allow building momentum
					var slope_steepness: float = 1.0 - floor_normal.dot(Vector3.UP)
					var boost_factor: float = 1.0 + (slope_steepness * 2.0)
					target_vel_2d = target_vel_2d * boost_factor
		
		horizontal_vel = horizontal_vel.move_toward(target_vel_2d, current_acceleration * delta)
	
		# Apply grace period to preserve momentum even with input
		if landing_grace_timer > 0:
			var speed_before: float = Vector2(velocity.x, velocity.z).length()
			if speed_before > target_vel_2d.length():
				# If we are in grace period and moving faster than target speed, 
				# use air resistance instead of standard acceleration to slow down.
				var momentum_preserved_vel = Vector2(velocity.x, velocity.z).move_toward(target_vel_2d, air_resistance * delta)
				# Only apply if it actually preserves more speed (which it should since air_resistance < acceleration)
				if momentum_preserved_vel.length() > horizontal_vel.length():
					horizontal_vel = momentum_preserved_vel

		velocity.x = horizontal_vel.x
		velocity.z = horizontal_vel.y
	else:
		# Apply friction when no input
		var horizontal_vel: Vector2 = Vector2(velocity.x, velocity.z)
		
		# Choose between ground friction and air resistance
		var friction_to_apply: float = friction if is_on_floor() else 0.0
		
		# Skip/reduce friction during landing grace period
		if landing_grace_timer > 0:
			friction_to_apply = 0.0 # No friction during grace period
		
		if friction_to_apply > 0:
			horizontal_vel = horizontal_vel.move_toward(Vector2.ZERO, friction_to_apply * delta)
		velocity.x = horizontal_vel.x
		velocity.z = horizontal_vel.y


func apply_sliding_movement(direction: Vector3, delta: float) -> void:
	# If we are on a slope, gravity on the Y axis should be redirected 
	# into X/Z velocity to accelerate us downwards
	apply_slope_gravity(delta)

	var horizontal_vel: Vector2 = Vector2(velocity.x, velocity.z)
	var speed: float = horizontal_vel.length()
	
	if speed > 0.1:
		var current_dir: Vector2 = horizontal_vel.normalized()
		
		if direction.length() > 0.1:
			var target_dir: Vector2 = Vector2(direction.x, direction.z).normalized()
			# We "rotate" the current heading towards the input direction.
			# slide_control now acts as the 'steering weight'. 
			# (Multiplied by 10 to keep your 0.1 export feeling responsive)
			current_dir = current_dir.lerp(target_dir, slide_control * delta * 10.0).normalized()
		
		# Whittle down the speed magnitude by friction
		speed = move_toward(speed, 0.0, slide_friction * delta)
		
		var final_vel: Vector2 = current_dir * speed
		velocity.x = final_vel.x
		velocity.z = final_vel.y
	else:
		# If nearly stopped, just come to a full halt
		velocity.x = move_toward(velocity.x, 0, slide_friction * delta)
		velocity.z = move_toward(velocity.z, 0, slide_friction * delta)


func check_for_rails() -> void:
	# Only try to grind if we are falling onto it or moving fast enough
	if is_on_floor() or not is_sliding:
		return

	# Search for nearby GrindRail objects
	# We use a downward raycast to detect a rail object.
	# The rail object should have a StaticBody3D child (or be one) that we hit.
	
	var target := _find_rail_from_sphere_cast(board_node.global_position)
	if target:
		enter_rail(target)

func enter_rail(rail: Node) -> void:
	is_grinding = true
	if not is_ragdolling:
		_play_landing_sfx(true)
	_stop_airborne_sfx()
	_stop_moving_sfx()
	_start_grind_sfx()
	# TRIGGER OVERLAY for grind start
	if live_overlay:
		live_overlay.trigger_grind_reaction()
		# Don't collide with the rail we are riding
	rail.add_collision_exception_with(self) 

	current_rail = rail
	rail_offset = current_rail.get_closest_offset(global_position)
	
	# Determine speed and direction
	var rail_dir_vec = current_rail.get_direction_at_offset(rail_offset).normalized()
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var has_input: bool = input_dir.length() > 0.1
	var input_world_dir: Vector3 = Vector3.ZERO
	if has_input:
		input_world_dir = (_get_movement_basis() * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_velocity_dir: Vector3 = velocity.normalized()
	
	rail_speed = velocity.length()
	if rail_speed < grind_min_speed:
		rail_speed = grind_min_speed
	
	if has_input:
		rail_direction = 1 if input_world_dir.dot(rail_dir_vec) > 0 else -1
	elif current_velocity_dir.dot(rail_dir_vec) > 0:
		rail_direction = 1
	else:
		rail_direction = -1
	
	# Initial snap
	global_position = current_rail.get_pos_at_offset(rail_offset)

func _find_parent_sibling_path3d(parent: Node) -> Path3D:
	if not parent:
		return null
	var grandparent = parent.get_parent()
	if not grandparent:
		return null
	var expected_name = parent.name + "_Path3D"
	for sibling in grandparent.get_children():
		if sibling is Path3D and sibling.name == expected_name:
			return sibling
	for sibling in grandparent.get_children():
		if sibling is Path3D:
			return sibling
	return null

func _find_rail_from_sphere_cast(origin: Vector3) -> Path3D:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = max(0.1, grind_snap_distance * grind_cast_radius_multiplier)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), origin)
	query.motion = Vector3.DOWN * grind_snap_distance
	query.exclude = [self]
	var results := space_state.intersect_shape(query, 8)
	for hit in results:
		var collider = hit.collider
		var target: Path3D = null
		if collider is Path3D:
			var parent = collider.get_parent()
			if parent and parent.name.begins_with("GR"):
				target = collider
		elif collider.get_parent() and collider.get_parent().name.begins_with("GR"):
			target = _find_parent_sibling_path3d(collider.get_parent())
		if target and target.has_method("get_closest_offset"):
			return target
	return null

func apply_grind_movement(delta: float) -> void:
    if live_overlay:
        live_overlay.process_grind_tick(delta)

    # Safety check
    if not current_rail or not (current_rail is Path3D):
        exit_rail()
        return
		
	rail_offset += rail_speed * rail_direction * delta
	
	# Update sparks
	if grind_sparks:
		grind_sparks.emitting = true
		# Point sparks opposite to velocity
		if velocity.length() > 0.1:
			grind_sparks.look_at(global_position - velocity.normalized(), Vector3.UP)
		
		# Scale amount of sparks with speed; max at 2x max_speed, few below max_speed.
		var speed_ratio = clamp(rail_speed / (max_speed * 4.0), 0.0, 1.0)
		var speed_factor = clamp(pow(speed_ratio, 2.0), 0.05, 1.0)
		grind_sparks.amount_ratio = speed_factor	
	
	# Check if we've reached the end of the rail
	var rail_length = current_rail.curve.get_baked_length()
	
	if rail_offset < 0 or rail_offset > rail_length:
		# If the path is closed (looped), wrap the offset instead of exiting
		if current_rail.curve.is_closed():
			rail_offset = fposmod(rail_offset, rail_length)
		else:
			exit_rail()
			return
	
	
	var next_pos = current_rail.get_pos_at_offset(rail_offset)
	var move_vec = next_pos - global_position
	
	# Set velocity so move_and_slide works if we want to use it, 
	# but for "locking in", we can just set position.
	# To maintain momentum on exit, we need to keep velocity updated.
	velocity = move_vec / delta
	last_rail_direction = velocity	
	global_position = next_pos
	# move_and_slide() # Optional if we want to detect collisions while grinding

func exit_rail() -> void:
	if is_grinding:
		if grind_sparks:
			grind_sparks.emitting = false	
		_stop_grind_sfx()
		velocity = last_rail_direction
		# Prevent clipping: Lift player slightly off the rail
		global_position += Vector3.UP * 1.5
		is_grinding = false
		current_rail = null
		rail_cooldown_timer = rail_reacquisition_time

func jump_exit_rail() -> void:
	if is_grinding:
		if grind_sparks:
			grind_sparks.emitting = false	
		_stop_grind_sfx()
		# 1. Start with forward momentum
		var exit_velocity: Vector3 = last_rail_direction
		
		# 2. Add Jump Force (Upwards)
		exit_velocity += Vector3.UP * rail_jump_force
		
		# 3. Add Directional Control (Left/Right)
		var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var lateral_dir: Vector3 = (_get_movement_basis() * Vector3(input_dir.x, 0, 0)).normalized()
		exit_velocity += lateral_dir * rail_jump_force * 0.5
		
		velocity = exit_velocity
		
		# Set cooldown so we don't instantly snap back to the rail we just left
		rail_cooldown_timer = rail_reacquisition_time
		
		# Nudge player to ensure they clear the collision shape
		global_position += Vector3.UP * 0.5
		
		is_grinding = false
		current_rail = null

func _update_slowmo(delta: float) -> void:
	var now_ticks = Time.get_ticks_usec()
	var real_delta = float(now_ticks - slowmo_last_ticks) / 1000000.0
	slowmo_last_ticks = now_ticks
	if real_delta < 0.0 or real_delta > 0.5:
		real_delta = delta

	if Input.is_action_just_pressed("slow_mo"):
		if slowmo_active:
			slowmo_active = false
		elif slowmo_time_left > 0.0:
			slowmo_active = true

	if slowmo_active:
		slowmo_time_left = max(slowmo_time_left - real_delta, 0.0)
		if slowmo_time_left <= 0.0:
			slowmo_active = false
	else:
		slowmo_time_left = min(slowmo_time_left + (slowmo_recharge_rate * real_delta), slowmo_max_time)

	var target_scale = slowmo_time_scale if slowmo_active else 1.0
	if Engine.time_scale != target_scale:
		Engine.time_scale = target_scale

func _update_slowmo_ui(delta: float) -> void:
	if not slowmo_container:
		return
	var viewport_size = get_viewport().get_visible_rect().size
	var inset = round(viewport_size.x * clamp(slowmo_ui_inset_ratio, 0.0, 0.2))
	slowmo_container.offset_left = inset
	slowmo_container.offset_right = -inset
	var max_time = max(slowmo_max_time, 0.001)
	var ratio : float = clamp(slowmo_time_left / max_time, 0.0, 1.0)
	var is_draining := ratio < (slowmo_last_ratio - 0.0005)
	slowmo_last_ratio = ratio
	var total_width = slowmo_container.size.x
	var bar_width = (total_width * 0.5) * ratio
	var has_bar := ratio > 0.0005
	if not has_bar:
		bar_width = 0.0
	var bar_height = slowmo_container.size.y

	if slowmo_base:
		slowmo_base.size = slowmo_container.size

	if slowmo_left:
		slowmo_left.size = Vector2(bar_width, bar_height)
		slowmo_left.position = Vector2((total_width * 0.5) - bar_width, 0.0)
		slowmo_left.visible = has_bar

	if slowmo_right:
		slowmo_right.size = Vector2(bar_width, bar_height)
		slowmo_right.position = Vector2(total_width * 0.5, 0.0)
		slowmo_right.visible = has_bar

	var empty_color = Color(0.4, 0.4, 0.4, 0.35)
	var ready_color = Color(0.9, 0.95, 1.0, 0.85)
	var bar_color = empty_color.lerp(ready_color, ratio)
	if slowmo_left:
		slowmo_left.color = bar_color
	if slowmo_right:
		slowmo_right.color = bar_color

	var is_recharging := slowmo_time_left < (slowmo_max_time - 0.001)
	var show_ui := slowmo_active or is_recharging
	var target_alpha := 1.0 if show_ui else 0.0
	var current_alpha := slowmo_container.modulate.a
	var new_alpha := move_toward(current_alpha, target_alpha, slowmo_ui_fade_speed * delta)
	slowmo_container.modulate = Color(1.0, 1.0, 1.0, new_alpha)

	var center_x = total_width * 0.5
	var spark_speed_scale = 1.0
	if Engine.time_scale > 0.01:
		spark_speed_scale = 1.0 / Engine.time_scale
	if slowmo_left_sparks:
		slowmo_left_sparks.position = Vector2(center_x - bar_width, bar_height * 0.5)
		slowmo_left_sparks.speed_scale = spark_speed_scale
		slowmo_left_sparks.emitting = slowmo_active and is_draining and ratio > 0.02
	if slowmo_right_sparks:
		slowmo_right_sparks.position = Vector2(center_x + bar_width, bar_height * 0.5)
		slowmo_right_sparks.speed_scale = spark_speed_scale
		slowmo_right_sparks.emitting = slowmo_active and is_draining and ratio > 0.02
