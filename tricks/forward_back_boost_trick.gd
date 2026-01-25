extends BufferedTrickResource
class_name ForwardBackBoostTrick

const PATTERN: Array[String] = [
	"move_forward",
	"move_backward",
	"move_forward",
	"move_backward"
]

@export var backflip_speed_deg: float = 720.0
@export var backflip_direction: float = -1.0

var _backflip_active: bool = false
var _backflip_radians: float = 0.0

func _init() -> void:
	display_name = "Forward Back Boost"
	watched_actions = ["move_forward", "move_backward"]

func check_completion(_player: Player, _delta: float) -> bool:
	return matches_pattern(PATTERN, true)

func grant_reward(player: Player) -> void:
	var stale_multiplier := player.consume_trick_stale(self)
	if player.is_grinding:
		player.jump_exit_rail()
		player.velocity.y += player.rail_jump_force * stale_multiplier
	else:
		var target_jump := player.jump_velocity * (1 * stale_multiplier + stale_multiplier)
		if player.velocity.y < target_jump:
			player.velocity.y = target_jump
	_backflip_active = true
	_backflip_radians = 0.0
	player.start_trick_pose()

func apply_updates(player: Player, delta: float) -> void:
	if _backflip_active:
		_backflip_radians += deg_to_rad(backflip_speed_deg) * delta
		if _backflip_radians >= TAU:
			_backflip_radians = TAU
			_backflip_active = false
	if _backflip_active:
		var angle := _backflip_radians * backflip_direction
		player.set_visual_override_basis(Basis(Vector3.RIGHT, angle))
	else:
		player.clear_visual_override()

func check_validity(player: Player, _delta: float) -> float:
	if _backflip_active and _backflip_radians < TAU:
		player.clear_visual_override()
		return 1.0
	return 0.0

func reset_trick_state() -> void:
	_backflip_active = false
	_backflip_radians = 0.0
