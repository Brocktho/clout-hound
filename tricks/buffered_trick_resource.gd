extends TrickResource
class_name BufferedTrickResource

@export var buffer_window_seconds: float = 0.4
@export var max_buffer_size: int = 10
@export var watched_actions: Array[String] = []

var _input_buffer: Array[Dictionary] = []

func process_input(_player: Player, _delta: float) -> void:
	var now := _now_seconds()
	for action in watched_actions:
		if Input.is_action_just_pressed(action):
			_input_buffer.append({"action": action, "time": now})
	_prune_buffer(now)

func matches_pattern(pattern: Array[String], consume: bool = false) -> bool:
	if pattern.is_empty():
		return false
	var now := _now_seconds()
	_prune_buffer(now)
	if _input_buffer.size() < pattern.size():
		return false
	var start_index := _input_buffer.size() - pattern.size()
	for idx in pattern.size():
		if _input_buffer[start_index + idx]["action"] != pattern[idx]:
			return false
	if consume:
		_input_buffer = _input_buffer.slice(0, start_index)
	return true

func get_buffered_actions() -> Array[String]:
	var actions: Array[String] = []
	for entry in _input_buffer:
		actions.append(entry["action"])
	return actions

func reset_trick_state() -> void:
	_input_buffer.clear()

func _prune_buffer(now: float) -> void:
	var cutoff := now - buffer_window_seconds
	var pruned: Array[Dictionary] = []
	for entry in _input_buffer:
		if entry["time"] >= cutoff:
			pruned.append(entry)
	_input_buffer = pruned
	if _input_buffer.size() > max_buffer_size:
		_input_buffer = _input_buffer.slice(_input_buffer.size() - max_buffer_size)

func _now_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0
