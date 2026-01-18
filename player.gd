extends CharacterBody3D

@export_group("Movement")
@export var max_speed: float = 10.0
@export var acceleration: float = 20.0 # Reaches max_speed in ~0.5s if 20
@export var friction: float = 50.0
@export var air_resistance: float = 2.0
@export var jump_velocity: float = 4.5


@export_group("Slide")
@export var slide_friction: float = 0.5 # Very low friction
@export var slide_control: float = 0.1 # Heavily restricted movement input
@export var slope_slide_gravity_modifier: float = 10.0

@export_group("Grind")
@export var grind_snap_distance: float = 0.5
@export var grind_min_speed: float = 2.0

@export_group("Camera Settings")
@export var mouse_sensitivity: float = 0.002
@export var camera_height: float = 0.7 # Offset from the player's center
@export var camera_distance: float = 0.1 # Very slight backward offset to avoid clipping inside the head

var is_sliding: bool = false
var camera_look_input: Vector2 = Vector2.ZERO

var is_grinding: bool = false
var current_rail: Node = null # Using Node to avoid class_name issues in some environments
var rail_offset: float = 0.0
var rail_speed: float = 0.0
var rail_direction: int = 1 # 1 or -1


@onready var camera: Camera3D = $Camera3D

@export_group("Rail Settings")
@export var rail_jump_force: float = 10.0
@export var rail_reacquisition_time: float = 0.5

var rail_cooldown_timer: float = 0.0
var last_rail_direction: Vector3 = Vector3.FORWARD



# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Initialize camera position relative to player
	camera.position = Vector3(0, camera_height, -camera_distance)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Rotate the player horizontally (yaw)
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Rotate the camera vertically (pitch)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta: float) -> void:

	if rail_cooldown_timer > 0:
		rail_cooldown_timer -= delta

	if Input.is_action_just_pressed("jump"):
		if is_grinding:
			jump_exit_rail()
			velocity.y = jump_velocity
		elif is_on_floor():
			velocity.y = jump_velocity

	# Grinding logic is here, but honestly I feel like a good portion of it should be in the GrindRail script.
	# But thats what game jamming is all about. Sloppy code to get it out the door.
	if is_grinding:
		apply_grind_movement(delta)
		return
	else:
		# Only look for rails if not on cooldown
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
	
	
func handle_dynamic_snapping() -> void:
	var current_speed: float = velocity.length()
	
	# Default snapping to keep us grounded
	floor_snap_length = clamp(current_speed * 0.1, 0.1, 2.0)
	
	if is_on_floor():
		var floor_normal: Vector3 = get_floor_normal()
		var velocity_dot_normal = velocity.dot(floor_normal)
		
		# If we're moving fast and the floor normal is opposing our movement
		if velocity_dot_normal < 0.0 and current_speed > max_speed:
			# "Cheat" by projecting the velocity onto the plane of the ramp.
			# This ensures we are moving 'up' the ramp's angle exactly, 
			# so when we leave the edge, we have the correct vertical momentum.
			var plane_velocity = velocity.slide(floor_normal).normalized()
			velocity = plane_velocity * current_speed
			
			floor_snap_length = 0.0


	
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
			
			velocity += base_slide


func apply_standard_movement(direction: Vector3, delta: float) -> void:

	apply_slope_gravity(delta)
	
	if direction:
		var target_velocity: Vector3 = direction * max_speed
		var horizontal_vel: Vector2 = Vector2(velocity.x, velocity.z)
		var target_vel_2d: Vector2 = Vector2(target_velocity.x, target_velocity.z)
		
		var current_acceleration: float = acceleration
		
		# Check if we are on the ground and trying to pivot/turn sharply
		if is_on_floor():
			# dot product: 1 if same direction, 0 if perpendicular, -1 if opposite
			var movement_dot: float = horizontal_vel.normalized().dot(target_vel_2d.normalized())
			
			# If dot < 0.2 (perpendicular or opposing), we apply a massive acceleration boost
			if movement_dot < 0.2:
				current_acceleration *= 5.0 # Snappy pivot factor
		
		horizontal_vel = horizontal_vel.move_toward(target_vel_2d, current_acceleration * delta)
		
		velocity.x = horizontal_vel.x
		velocity.z = horizontal_vel.y
	else:
		# Apply friction when no input
		var horizontal_vel: Vector2 = Vector2(velocity.x, velocity.z)
		
		# Choose between ground friction and air resistance
		var friction_to_apply: float = friction if is_on_floor() else air_resistance
		
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
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * grind_snap_distance)
	var result = space_state.intersect_ray(query)
	
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
	var current_velocity_dir = velocity.normalized()
	
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
	
	# Check if we've reached the end of the rail
	if rail_offset < 0 or rail_offset > current_rail.curve.get_baked_length():
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
		velocity = last_rail_direction
		print(velocity)
		# Prevent clipping: Lift player slightly off the rail
		global_position += Vector3.UP * 2.5
		is_grinding = false
		current_rail = null
		rail_cooldown_timer = rail_reacquisition_time

func jump_exit_rail() -> void:
	if is_grinding:
		
		# 1. Start with forward momentum
		var exit_velocity = last_rail_direction
		
		# 2. Add Jump Force (Upwards)
		exit_velocity += Vector3.UP * rail_jump_force
		
		# 3. Add Directional Control (Left/Right)
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var lateral_dir = (transform.basis * Vector3(input_dir.x, 0, 0)).normalized()
		exit_velocity += lateral_dir * rail_jump_force * 0.5
		
		velocity = exit_velocity
		
		# Set cooldown so we don't instantly snap back to the rail we just left
		rail_cooldown_timer = rail_reacquisition_time
		
		# Nudge player to ensure they clear the collision shape
		global_position += Vector3.UP * 0.2
		
		is_grinding = false
		current_rail = null	
