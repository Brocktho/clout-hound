extends Node3D

const SHOVE_IT_NAME: String = "Shove-it"
const KICKFLIP_NAME: String = "Kickflip"
const COMPLETION_POPUP_SCENE: PackedScene = preload("res://CompletionPopup.tscn")

var _shove_it_done: bool = false
var _kickflip_done: bool = false
var _level_completed: bool = false
var _waiting_for_player: bool = false

func _ready() -> void:
	var player := _find_player()
	if player:
		player.trick_completed.connect(_on_trick_completed)
	else:
		_waiting_for_player = true
		get_tree().node_added.connect(_on_node_added)

func _find_player() -> Player:
	var tree := get_tree()
	if not tree:
		return null
	var players := tree.get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Player

func _on_node_added(node: Node) -> void:
	if not _waiting_for_player:
		return
	var player := node as Player
	if not player:
		return
	_waiting_for_player = false
	get_tree().node_added.disconnect(_on_node_added)
	player.trick_completed.connect(_on_trick_completed)

func _on_trick_completed(trick_name: String) -> void:
	if _level_completed:
		return
	if trick_name == SHOVE_IT_NAME:
		_shove_it_done = true
	elif trick_name == KICKFLIP_NAME:
		_kickflip_done = true
	if _shove_it_done and _kickflip_done:
		_level_completed = true
		_ensure_completion_popup()
		Global.emit_level_completed()

func _ensure_completion_popup() -> void:
	var tree := get_tree()
	if not tree:
		return
	if not tree.get_nodes_in_group("completion_popup").is_empty():
		return
	if not COMPLETION_POPUP_SCENE:
		return
	var popup := COMPLETION_POPUP_SCENE.instantiate()
	var scene_root := tree.current_scene if tree.current_scene else tree.root
	if scene_root:
		scene_root.add_child(popup)
