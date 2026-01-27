extends TrickResource
class_name KickflipTrick

var current_flip: float = 0.0
var last_flip_threshold: float = 0.0
var started_spin: bool = false

func _init() -> void:
	display_name = "Kickflip"

func process_input(player: Player, _delta: float) -> void:
	if Input.is_action_just_pressed("kickflip"):
		started_spin = true
		current_flip += deg_to_rad(player.spin_increment_deg)

func check_completion(_player: Player, _delta: float) -> bool:
	var completed := false
	if abs(current_flip) >= last_flip_threshold + TAU:
		completed = true
		last_flip_threshold += TAU

		var wrap_sign : float = sign(current_flip)
		current_flip -= TAU * wrap_sign
		last_flip_threshold -= TAU
	elif abs(current_flip) < last_flip_threshold:
		last_flip_threshold = floor(abs(current_flip) / TAU) * TAU

	return completed

func grant_reward(player: Player) -> void:
	var stale_multiplier := player.consume_trick_stale(self)
	_apply_spin_boost(player, 2.0 * stale_multiplier)

func _apply_spin_boost(player: Player, multiplier: float = 1.0) -> void:
	if player.is_grinding:
		player.rail_speed += player.spin_boost_amount * multiplier
		player.velocity = player.velocity.normalized() * player.rail_speed
	else:
		var boost_dir := player.get_horizontal_boost_dir()
		player.velocity += boost_dir * player.spin_boost_amount * multiplier
	player.start_trick_pose()

func get_flip_radians() -> float:
	return current_flip

func get_started_spin() -> bool:
	return started_spin

func check_validity(_player: Player, _delta: float) -> float:
	if current_flip == 0.0:
		return 0.0
	var normalized_flip: float = fmod(abs(current_flip), TAU)
	var aligned := normalized_flip < 0.2 or normalized_flip > TAU - 0.2
	return 0.0 if aligned else 1.0

func on_landing(aligned: bool) -> void:
	if aligned:
		reset_trick_state()

func reset_trick_state() -> void:
	current_flip = 0.0
	last_flip_threshold = 0.0
	started_spin = false
