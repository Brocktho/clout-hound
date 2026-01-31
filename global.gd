extends Node

# this most certainly is used in the player script
@warning_ignore("unused_signal")
signal kill_zone_triggered(player: Node)
signal _level_completed(level_info: LevelInformation, elapsed_seconds: float)
signal level_record_achieved(record_type: StringName)

var sfx_level: float = 1.0
var music_level: float = 1.0
var mouse_sensitivity: float = 0.0005
var mouse_sensitivity_slider: float = 0.0
var disable_grind_sfx: bool = false
var completion_popup_active: bool = false
var current_level_info: LevelInformation = null
var level_start_ticks_msec: int = 0
var current_hype_score: float = 0.0
var _music_players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Bus should already exist in default_bus_layout.tres
	# Just verify it exists, don't create dynamically
	if get_tree():
		get_tree().node_added.connect(_on_node_added)
	if not _level_completed.is_connected(_on_level_completed):
		_level_completed.connect(_on_level_completed)
	_apply_music_volume(music_level)

func set_current_level(level_info: LevelInformation) -> void:
	current_level_info = level_info

func start_level_timer() -> void:
	level_start_ticks_msec = Time.get_ticks_msec()
	current_hype_score = 0.0

func set_current_hype_score(score: float) -> void:
	current_hype_score = score

func get_level_elapsed_seconds() -> float:
	if level_start_ticks_msec <= 0:
		return 0.0
	return float(Time.get_ticks_msec() - level_start_ticks_msec) / 1000.0

func emit_level_completed(level_info: LevelInformation = null) -> void:
	var resolved_info := level_info if level_info else current_level_info
	var elapsed_seconds := get_level_elapsed_seconds()
	_level_completed.emit(resolved_info, elapsed_seconds)

func _on_level_completed(level_info: LevelInformation, elapsed_seconds: float) -> void:
	if level_info:
		level_info.completed = true
		var new_high_score := false
		var new_fastest_time := false
		var score_value := int(current_hype_score)
		if score_value >= 0 and (level_info.high_score < 0 or score_value > level_info.high_score):
			level_info.high_score = score_value
			new_high_score = true
		if elapsed_seconds > 0.0 and (level_info.fastest_completion_seconds < 0.0 or elapsed_seconds < level_info.fastest_completion_seconds):
			level_info.fastest_completion_seconds = elapsed_seconds
			new_fastest_time = true
		if new_fastest_time:
			level_record_achieved.emit(&"fastest_time")
		if new_high_score:
			level_record_achieved.emit(&"high_score")

func set_music_level(value: float) -> void:
	music_level = clamp(value, 0.0, 2.0)
	_apply_music_volume(music_level)

func set_mouse_sensitivity_slider(value: float) -> void:
	mouse_sensitivity_slider = clamp(value, 0.0, 0.5)
	mouse_sensitivity = _map_sensitivity(mouse_sensitivity_slider)
	_apply_mouse_sensitivity()

func _map_sensitivity(value: float) -> float:
	var base := 0.0005
	var max_value := 0.5
	var slider_max := 0.5
	if value <= 0.0:
		return base
	var t : float = clamp(value / slider_max, 0.0, 1.0)
	return base * pow(max_value / base, t)

func _apply_mouse_sensitivity() -> void:
	if not get_tree():
		return
	for node in get_tree().get_nodes_in_group("player"):
		if node and _has_property(node, "mouse_sensitivity"):
			node.set("mouse_sensitivity", mouse_sensitivity)

func _has_property(obj: Object, property_name: String) -> bool:
	for item in obj.get_property_list():
		if item.name == property_name:
			return true
	return false

func _apply_music_volume(value: float) -> void:
	var db := -80.0 if value <= 0.001 else linear_to_db(value)
	for player in _music_players:
		if is_instance_valid(player):
			player.volume_db = db
		else:
			_music_players.erase(player)
	if not get_tree():
		return
	for node in get_tree().get_nodes_in_group("music"):
		var player := node as AudioStreamPlayer
		if player:
			player.volume_db = db

func _on_node_added(node: Node) -> void:
	if node and node.is_in_group("music") and node is AudioStreamPlayer:
		var player := node as AudioStreamPlayer
		player.volume_db = -80.0 if music_level <= 0.001 else linear_to_db(music_level)

func register_music_player(player: AudioStreamPlayer) -> void:
	if not player:
		return
	if _music_players.has(player):
		return
	_music_players.append(player)
	player.volume_db = -80.0 if music_level <= 0.001 else linear_to_db(music_level)
