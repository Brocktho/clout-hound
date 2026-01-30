extends Node

signal kill_zone_triggered(player: Node)

var sfx_level: float = 1.0
var music_level: float = 1.0
var mouse_sensitivity: float = 0.0005
var mouse_sensitivity_slider: float = 0.0
var disable_grind_sfx: bool = false
var completion_popup_active: bool = false
var _music_players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Bus should already exist in default_bus_layout.tres
	# Just verify it exists, don't create dynamically
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus == -1:
		push_warning("SFX bus not found! Create it in Project Settings → Audio → Buses")
	if get_tree():
		get_tree().node_added.connect(_on_node_added)
	_apply_music_volume(music_level)

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
