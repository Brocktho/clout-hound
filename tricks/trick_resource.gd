extends Resource
class_name TrickResource

@export var display_name: String = ""

func process_input(_player: Player, _delta: float) -> void:
	pass

func check_completion(_player: Player, _delta: float) -> bool:
	push_error("TrickResource.check_completion must be overridden")
	return false

func grant_reward(_player: Player) -> void:
	push_error("TrickResource.grant_reward must be overridden")

func check_validity(_player: Player, _delta: float) -> float:
	return 0.0

func apply_updates(_player: Player, _delta: float) -> void:
	pass

func get_spin_radians() -> float:
	return 0.0

func get_flip_radians() -> float:
	return 0.0

func get_started_spin() -> bool:
	return false

func on_landing(_aligned: bool) -> void:
	pass

func reset_trick_state() -> void:
	pass
