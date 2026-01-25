extends TrickResource
class_name BoardSpinTrick

var current_spin: float = 0.0
var last_spin_threshold: float = 0.0
var started_spin: bool = false

func _init() -> void:
	display_name = "180"

func process_input(player: Player, _delta: float) -> void:
	var spin_input := 0.0
	if Input.is_action_just_pressed("spin_left"):
		spin_input += 1.0
	if Input.is_action_just_pressed("spin_right"):
		spin_input -= 1.0

	if spin_input != 0.0:
		started_spin = true
		var rotation_step := deg_to_rad(player.spin_increment_deg) * spin_input
		current_spin += rotation_step

func check_completion(_player: Player, _delta: float) -> bool:
	var completed := false
	if abs(current_spin) >= last_spin_threshold + PI:
		completed = true
		last_spin_threshold += PI

		# Keep counters small to avoid precision drift over long grinds.
		var wrap_sign = sign(current_spin)
		current_spin -= PI * wrap_sign
		last_spin_threshold -= PI
	elif abs(current_spin) < last_spin_threshold:
		# Reset threshold if direction reverses to prevent double-dipping.
		last_spin_threshold = floor(abs(current_spin) / PI) * PI

	return completed

func grant_reward(player: Player) -> void:
	var stale_multiplier := player.consume_trick_stale(self)
	_apply_spin_boost(player, stale_multiplier)

func _apply_spin_boost(player: Player, multiplier: float = 1.0) -> void:
	if player.is_grinding:
		player.rail_speed += player.spin_boost_amount * multiplier
		player.velocity = player.velocity.normalized() * player.rail_speed
	else:
		var boost_dir := player.velocity.normalized()
		if boost_dir == Vector3.ZERO:
			boost_dir = -player.transform.basis.z
		player.velocity += boost_dir * player.spin_boost_amount * multiplier
	player.start_trick_pose()

func apply_updates(player: Player, _delta: float) -> void:
	var rot := player.board_node.rotation
	rot.y = player.default_board_rotation.y + current_spin
	player.board_node.rotation = rot

func get_spin_radians() -> float:
	return current_spin

func get_started_spin() -> bool:
	return started_spin

func check_validity(_player: Player, _delta: float) -> float:
	if current_spin == 0.0:
		return 0.0
	var normalized_spin: float = fmod(abs(current_spin), PI)
	var aligned := normalized_spin < 0.2 or normalized_spin > PI - 0.2
	return 0.0 if aligned else 1.0

func on_landing(aligned: bool) -> void:
	if aligned:
		reset_trick_state()

func reset_trick_state() -> void:
	current_spin = 0.0
	last_spin_threshold = 0.0
	started_spin = false
