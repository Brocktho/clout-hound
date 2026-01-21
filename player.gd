extends CharacterBody3D

@export_group("Movement")
@export var max_speed: float = 10.0
@export var acceleration: float = 20.0 # Reaches max_speed in ~0.5s if 20
@export var friction: float = 50.0
@export var air_resistance: float = 1.0
@export var jump_velocity: float = 4.5
@export var diagonal_boost: float = 4.0
@export var jump_buffer_time: float = 0.15 # Time before landing that a jump press is still registered
@export var landing_grace_time: float = 0.1 # Time after landing where friction is reduced



@export_group("Slide")
@export var slide_friction: float = 0.5 # Very low friction
@export var slide_control: float = 0.02 # Heavily restricted movement input
@export var steering_weight: float = 4.0 # How quickly the board carves in standard movement
@export var slope_slide_gravity_modifier: float = 10.0
@export var slope_regular_gravity_modifier: float = 2.0

@export_group("Grind")
@export var grind_snap_distance: float = 0.5
@export var grind_min_speed: float = 2.0

@export_group("Camera Settings")
@export var mouse_sensitivity: float = 0.0005
@export var camera_height: float = 1.5 # Offset from the player's center
@export var camera_distance: float = 0.1 # Very slight backward offset to avoid clipping inside the head
@export var base_fov: float = 75.0
@export var max_fov_boost: float = 50.0
@export var speed_for_max_fov: float = 50.0

@export_group("Third Person Settings")
@export var third_person_distance: float = 4.0
@export var third_person_offset: Vector3 = Vector3(0.5, 0.5, 0) # Over-the-shoulder look

@export_group("Trick Settings")
@export var spin_increment_deg: float = 45.0 # Degrees per frame-ish, or radians
@export var flip_speed: float = 720.0 # Degrees per second for kickflip
@export var spin_boost_amount: float = 5.0 # Speed added per 180 flip
@export var lean_intensity_player: float = 0.05 # How much the player leans
@export var lean_intensity_board: float = 0.005 # How much the board tilts
@export var lean_speed: float = 8.0 # How fast the lean responds
@export var ragdoll_friction: float = 25.0
@export var reset_speed_threshold: float = 0.5

@export_group("Debug Items")
@export var stand_height: float = 1.0;
@export var slide_height: float = 0.5;
@export var stand_offset: float = 1.0;
@export var slide_offset: float = 0.5;

var is_third_person: bool = false
var is_sliding: bool = false
var camera_look_input: Vector2 = Vector2.ZERO

var is_grinding: bool = false
var current_rail: Node = null # Using Node to avoid class_name issues in some environments
var rail_offset: float = 0.0
var rail_speed: float = 0.0
var rail_direction: int = 1 # 1 or -1

var current_spin: float = 0.0 # Cumulative rotation in radians
var current_flip: float = 0.0 # Cumulative flip rotation
var current_board_lean: float = 0.0 # Tilt of board during turning or rotating
var last_spin_threshold: float = 0.0 # Tracks the last 180-degree mark rewarded
var is_ragdolling: bool = false
var ragdoll_rot_vel: Vector3 = Vector3.ZERO
var board_velocity: Vector3 = Vector3.ZERO
var initial_spawn_pos: Vector3

var jump_buffer_timer: float = 0.0
var landing_grace_timer: float = 0.0
var was_on_floor: bool = false


@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var board_mesh: MeshInstance3D = $Visual/Board
@onready var body_mesh: MeshInstance3D = $Visual/Body/Dog
@onready var visual : Node3D = $Visual
@onready var body_collision: CollisionShape3D = $BodyCollision
@onready var grind_sparks: GPUParticles3D = $GrindSparks
@onready var speed_lines: ColorRect = $SpeedLines

var outline_material: ShaderMaterial

@export_group("Rail Settings")
@export var rail_jump_force: float = 10.0
@export var rail_reacquisition_time: float = 0.5

var rail_cooldown_timer: float = 0.0
var last_rail_direction: Vector3 = Vector3.FORWARD
var smoothed_floor_normal: Vector3 = Vector3.UP
var started_spin : bool = false



# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	initial_spawn_pos = global_position
	# Initialize camera position relative to player
	update_camera_position()
	setup_outline()

func setup_outline() -> void:
	outline_material = ShaderMaterial.new()
	outline_material.shader = load("res://Assets/Shaders/outline.gdshader")
	outline_material.set_shader_parameter("outline_color", Color.GREEN)
	outline_material.set_shader_parameter("outline_width", 4)
	
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
		if is_third_person:
			# Rotate the player horizontally (yaw)
			rotate_y(-event.relative.x * mouse_sensitivity)
			
			# Rotate the camera vertically (pitch)
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	if event.is_action_pressed("toggle_camera"):
		toggle_camera_mode()

	if event.is_action_pressed("ui_cancel"):
		show_controls()

func show_controls() -> void:
	var controls_scene = load("res://Controls.tscn")
	if controls_scene:
		var controls_instance = controls_scene.instantiate()
		add_sibling(controls_instance) # Add to parent so it's not affected by player's transform
		
func toggle_camera_mode() -> void:
		is_third_person = !is_third_person
		update_camera_position()	
		
		
func update_camera_position() -> void:
		if is_third_person:
			# Move camera back for 3rd person
			spring_arm.position.y += 2.0
			spring_arm.spring_length = third_person_distance
			camera.position = third_person_offset
		else:
			spring_arm.position.y = camera_height
			spring_arm.spring_length = 0.0
			# Reset to 1st person
			camera.position = Vector3(0, 0, -camera_distance)	

func _physics_process(delta: float) -> void:

	if is_ragdolling:
		apply_ragdoll_physics(delta)
		return	
		
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
		elif is_on_floor():
			jump_buffer_timer = 0
			velocity.y = jump_velocity
			if !is_sliding:
				# Diagonal Momentum Exploit
				var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
				if abs(input_dir.x) > 0.5 and abs(input_dir.y) > 0.5:
					var current_hor_vel: Vector3 = Vector3(velocity.x, 0, velocity.z)
					var boost_vec: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
					velocity += boost_vec * diagonal_boost	

	# Landing detection for grace period
	if is_on_floor() and not was_on_floor:
		landing_grace_timer = landing_grace_time
	
	was_on_floor = is_on_floor()

	# Grinding logic is here, but honestly I feel like a good portion of it should be in the GrindRail script.
	# But thats what game jamming is all about. Sloppy code to get it out the door.
	if is_grinding:
		apply_grind_movement(delta)
		handle_trick_input() # Allow rotation while grinding
		update_outline_color()
		return
	else:
		if not is_on_floor():
			handle_trick_input()
		
		# Landing check
		if is_on_floor() and not is_grinding:
			# Only look for rails if not on cooldown
			if rail_cooldown_timer <= 0 and is_falling_on_rail():
				check_for_rails()	
			else:
				var success: bool = check_landing_alignment()	
				if !success: return
				
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
		input_dir -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		input_dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		input_dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		input_dir += transform.basis.x
	
	var direction: Vector3 = input_dir

	if is_sliding:
		apply_sliding_movement(direction, delta)
	else:
		apply_standard_movement(direction, delta)

	handle_dynamic_snapping()

	move_and_slide()
	
	update_speed_effects(delta)
	update_outline_color()

func update_outline_color() -> void:
	if not outline_material:
		return
		
	var target_color: Color = Color.GREEN
	
	if not is_on_floor() and started_spin:
		var remainder = fmod(abs(current_spin),PI)
		var flip_rem = fmod(abs(current_flip), TAU)
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
	camera.fov = lerp(camera.fov, target_fov, 5.0 * delta)
	
	# Speed Lines
	if speed_lines:
		var speed_threshold = max_speed * 1.5
		if current_speed > speed_threshold:
			speed_lines.visible = true
			var wind_ratio = clamp((current_speed - speed_threshold) / (speed_for_max_fov - speed_threshold), 0.0, 1.0)
			# We can animate the line density or alpha via shader parameters
			speed_lines.material.set_shader_parameter("line_color", Color(1.0, 1.0, 1.0, wind_ratio * 0.3))
		else:
			speed_lines.visible = false

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
	var curr_basis: Basis = visual.global_basis
	var target_basis: Basis = Basis()
	
	# Determine the "Forward" direction based on input
	var target_fwd: Vector3 = -transform.basis.z # Default to forward	
	
	if is_grinding and current_rail:
		target_fwd = rail_fwd_dir
	else:
		var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		if input_dir.length() > 0.1:
			# Map the 2D input to the player's 3D orientation
			var world_input := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			target_fwd = world_input
	
	# Calculate the new right and forward vectors based on the new Up
	target_basis.y = target_up
	target_basis.x = target_basis.y.cross(target_fwd).normalized()
	target_basis.z = target_basis.x.cross(target_basis.y).normalized()
	
	# Smoothly interpolate the rotation
	var lerp_speed: float = 15.0
	visual.global_basis = curr_basis.slerp(target_basis, lerp_speed * delta).orthonormalized()
	if !is_third_person:
		var camera_basis: Basis = camera.global_basis
		# Create a basis specifically for the camera where Forward is -target_fwd
		# This aligns the camera's -Z with the player's intended forward direction
		var cam_target: Basis = Basis()
		cam_target.y = target_up
		cam_target.x = cam_target.y.cross(-target_fwd).normalized()
		cam_target.z = cam_target.x.cross(cam_target.y).normalized()

		camera.global_basis = camera_basis.slerp(cam_target, lerp_speed * delta).orthonormalized()

	var input_x: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	
	# If we're sliding, we might want to invert or dampen the lean, 
	# but for standard movement, tilting into the turn feels best.
	var target_lean_player: float = -input_x * lean_intensity_player
	var target_lean_board: float = -input_x * lean_intensity_board

	# Apply lean to the body (heavier)
	body_mesh.rotation.z = lerp_angle(body_mesh.rotation.z, target_lean_player, lean_speed * delta)

	# Apply lean to the board (subtle)
	current_board_lean = lerp_angle(current_board_lean, target_lean_board, lean_speed * delta)
	board_mesh.rotation.z = current_board_lean + current_flip
	
	var target_height: float = slide_height if is_sliding else stand_height
	var target_y_pos: float = slide_offset if is_sliding else stand_offset # Adjust to keep feet on board

	body_mesh.scale.y = lerp(body_mesh.scale.y, target_height, 10.0 * delta)
	body_mesh.position.y = lerp(body_mesh.position.y, target_y_pos, 10.0 * delta)	
	
func handle_dynamic_snapping() -> void:
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
				if slope_dot < 0:
					# Scale down influence based on speed so we don't lose momentum instantly
					momentum_factor = clamp(max_speed / current_speed, 0.1, 1.0)
			
			var base_slide = slope_dir * gravity * steepness * delta * momentum_factor
			
			if is_sliding:
				base_slide *= slope_slide_gravity_modifier
			else:
				base_slide *= slope_regular_gravity_modifier
			
			velocity += base_slide


func handle_trick_input() -> void:
	var spin_input: float = 0.0
	if Input.is_action_just_pressed("spin_left"):
		spin_input += 1.0
	if Input.is_action_just_pressed("spin_right"):
		spin_input -= 1.0
	
	if spin_input != 0:
		started_spin = true
		var rotation_step: float = deg_to_rad(spin_increment_deg) * spin_input
		current_spin += rotation_step
		board_mesh.rotate_y(rotation_step)

		# Speed Boost Logic
		if abs(current_spin) >= last_spin_threshold + PI:
			apply_spin_boost()
			last_spin_threshold += PI

			# PREVENTION: Normalize to prevent precision loss over long grinds
			# If we've passed the threshold, we can subtract PI from both 
			# to keep the numbers small without affecting the logic.
			var wrap_sign = sign(current_spin)
			current_spin -= PI * wrap_sign
			last_spin_threshold -= PI 
		elif abs(current_spin) < last_spin_threshold:
			# If they reverse direction and drop below the last threshold,
			# we reset it so they can't "double dip" by oscillating.
			last_spin_threshold = floor(abs(current_spin) / PI) * PI
			
	if Input.is_action_pressed("kickflip"):
		started_spin = true
		current_flip += deg_to_rad(flip_speed) * get_physics_process_delta_time()
			
func apply_spin_boost() -> void:
	if is_grinding:
		# Boost the speed specifically on the rail path
		rail_speed += spin_boost_amount
		# Update velocity immediately so visual effects/physics stay in sync
		velocity = velocity.normalized() * rail_speed
	else:
		# Apply standard air boost
		var boost_dir = velocity.normalized()
		if boost_dir == Vector3.ZERO:
			boost_dir = -transform.basis.z
		velocity += boost_dir * spin_boost_amount
	
func check_landing_alignment() -> bool:
	# Check if rotation is a multiple of 180 degrees (PI radians)
	# We use a small epsilon (0.2) to be forgiving
	var normalized_spin: float = fmod(abs(current_spin), PI)
	var is_aligned: bool = normalized_spin < 0.2 or normalized_spin > PI - 0.2
	
	var normalized_flip: float = fmod(abs(current_flip), TAU)
	if normalized_flip > 0.2 and normalized_flip < TAU - 0.2:
		is_aligned = false
	
	started_spin = false
	last_spin_threshold = 0.0
	
	if not is_aligned and (current_spin != 0 or current_flip != 0):
		start_ragdoll()
		return false
	else:
		# Landed successfully: Snap board to nearest 180 and reset counter
		current_spin = 0.0
		current_flip = 0.0
		board_mesh.rotation.y = 0 # Or snap to PI if facing backward
		return true
		
func is_falling_on_rail() -> bool:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(board_mesh.global_position, board_mesh.global_position + Vector3.DOWN * grind_snap_distance)
	var result: Dictionary = space_state.intersect_ray(query)

	if result:
		var collider = result.collider
		var target = collider.get_parent() if collider.get_parent() is Path3D else collider
		return target is Path3D and target.has_method("get_closest_offset")
	return false

func start_ragdoll() -> void:
	is_ragdolling = true
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	
	# 1. Calculate how "bad" the landing was (0.0 to 1.0)
	# sin() of the spin is maxed at 90/270 degrees and 0 at 0/180
	var bail_severity = abs(sin(current_spin))
	
	# 2. Set rotational momentum based on severity and speed
	# We'll tumble on X and Z for a chaotic look
	ragdoll_rot_vel = Vector3(
		randf_range(-2.0, 2.0) * bail_severity,
		0,
		randf_range(-2.0, 2.0) * bail_severity
	)
	
	# Detach the board
	board_velocity = velocity * -0.4 # Make it go inverse to the player
	
	# Reparent to the world so it doesn't move with the player
	var world: Node = get_parent()
	var current_board_pos: Vector3 = board_mesh.global_position
	var current_board_rot: Vector3 = board_mesh.global_rotation
	
	board_mesh.get_parent().remove_child(board_mesh)
	world.add_child(board_mesh)
	
	board_mesh.global_position = current_board_pos
	board_mesh.global_rotation = current_board_rot	
	
	# 3. Apply the fling
	velocity.y = (horizontal_speed * 0.2) + 2.0
	
	print("Bailed with severity: ", bail_severity)

func apply_ragdoll_physics(delta: float) -> void:
	# Move with current momentum but apply heavy friction
	velocity.y -= gravity * delta
	
	board_velocity.y -= gravity * delta
	board_mesh.global_position += board_velocity * delta
	board_mesh.rotate_x(10.0 * delta) # Just make it spin wildly	
	
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

func reset_player() -> void:
	is_ragdolling = false
	current_spin = 0.0
	current_flip = 0.0
	if board_mesh.get_parent() != visual:
		board_mesh.get_parent().remove_child(board_mesh)
		visual.add_child(board_mesh)
		
	board_mesh.position = Vector3.ZERO # Reset to original local position
	board_mesh.rotation = Vector3.ZERO
	
	body_mesh.rotation = Vector3.ZERO
	body_collision.rotation = Vector3.ZERO
	velocity = Vector3.ZERO
	global_position = initial_spawn_pos # Or nearest checkpoint
	print("Resetting...")


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
	if is_on_floor():
		return

	# Search for nearby GrindRail objects
	# We use a downward raycast to detect a rail object.
	# The rail object should have a StaticBody3D child (or be one) that we hit.
	
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(board_mesh.global_position, board_mesh.global_position + Vector3.DOWN * grind_snap_distance)
	var result: Dictionary = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		var target = collider.get_parent() if collider.get_parent() is Path3D else collider
		if target is Path3D and target.has_method("get_closest_offset"):
			enter_rail(target)

func enter_rail(rail: Node) -> void:
	is_grinding = true
	current_rail = rail
	rail_offset = current_rail.get_closest_offset(global_position)
	
	# Determine speed and direction
	var rail_dir_vec = current_rail.get_direction_at_offset(rail_offset).normalized()
	var current_velocity_dir: Vector3 = velocity.normalized()
	
	rail_speed = velocity.length()
	if rail_speed < grind_min_speed:
		rail_speed = grind_min_speed
	
	if current_velocity_dir.dot(rail_dir_vec) > 0:
		rail_direction = 1
	else:
		rail_direction = -1
	
	# Initial snap
	global_position = current_rail.get_pos_at_offset(rail_offset)

func apply_grind_movement(delta: float) -> void:
	if not current_rail:
		exit_rail()
		return
		
	rail_offset += rail_speed * rail_direction * delta
	
	# Update sparks
	if grind_sparks:
		grind_sparks.emitting = true
		# Point sparks opposite to velocity
		if velocity.length() > 0.1:
			grind_sparks.look_at(global_position - velocity.normalized(), Vector3.UP)
		
		# Scale amount of sparks with speed (ratio is 0.0 to 1.0)
		var speed_factor = clamp(rail_speed / max_speed, 0.2, 1.0)
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
		velocity = last_rail_direction
		print(velocity)
		# Prevent clipping: Lift player slightly off the rail
		global_position += Vector3.UP * 2.5
		is_grinding = false
		current_rail = null
		rail_cooldown_timer = rail_reacquisition_time

func jump_exit_rail() -> void:
	if is_grinding:
		if grind_sparks:
			grind_sparks.emitting = false	
		# 1. Start with forward momentum
		var exit_velocity: Vector3 = last_rail_direction
		
		# 2. Add Jump Force (Upwards)
		exit_velocity += Vector3.UP * rail_jump_force
		
		# 3. Add Directional Control (Left/Right)
		var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var lateral_dir: Vector3 = (transform.basis * Vector3(input_dir.x, 0, 0)).normalized()
		exit_velocity += lateral_dir * rail_jump_force * 0.5
		
		velocity = exit_velocity
		
		# Set cooldown so we don't instantly snap back to the rail we just left
		rail_cooldown_timer = rail_reacquisition_time
		
		# Nudge player to ensure they clear the collision shape
		global_position += Vector3.UP * 0.2
		
		is_grinding = false
		current_rail = null
