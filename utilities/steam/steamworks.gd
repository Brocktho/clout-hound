extends Node

signal lobby_joined(lobby_id: int)
signal lobby_left(lobby_id: int)

var steam_initialized := false
var steam_id: int = 0
var player_name := ""
var player_avatar: Texture2D

var current_lobby_id: int = 0
var target_level_name := ""

const DEFAULT_APP_ID := 480
const DEFAULT_LOBBY_SIZE := 16


func _ready() -> void:
	initialize_steam()
	if steam_initialized:
		_register_callbacks()


func _process(_delta: float) -> void:
	if steam_initialized:
		Steam.run_callbacks()


func initialize_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx(DEFAULT_APP_ID, true)
	var status := int(initialize_response.get("status", 0))
	steam_initialized = status == 0
	print("Did Steam initialize?: %s" % initialize_response)
	if not steam_initialized:
		return
	
	steam_id = int(Steam.getSteamID())
	player_name = str(Steam.getPersonaName())
	_load_local_avatar()


func start_multiplayer(level_name: String) -> void:
	if not steam_initialized:
		return
	target_level_name = level_name
	Steam.addRequestLobbyListStringFilter("level", level_name, Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()


func leave_lobby() -> void:
	if current_lobby_id == 0:
		return
	var lobby_id := current_lobby_id
	current_lobby_id = 0
	Steam.leaveLobby(lobby_id)
	emit_signal("lobby_left", lobby_id)


func get_current_player_name() -> String:
	return player_name


func get_current_player_avatar() -> Texture2D:
	return player_avatar


func _register_callbacks() -> void:
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)


func _on_lobby_match_list(lobbies: Array) -> void:
	if lobbies.is_empty():
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, DEFAULT_LOBBY_SIZE)
		return

	var lobby_id := int(lobbies[0])
	Steam.joinLobby(lobby_id)


func _on_lobby_created(connect_type: int, lobby_id: int) -> void:
	if connect_type != 1 or lobby_id == 0:
		print("Steam lobby create failed: %s" % connect_type)
		return
	current_lobby_id = lobby_id
	if target_level_name != "":
		Steam.setLobbyData(lobby_id, "level", target_level_name)
	emit_signal("lobby_joined", lobby_id)


func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != 1:
		print("Steam lobby join failed: %s" % response)
		return
	current_lobby_id = lobby_id
	emit_signal("lobby_joined", lobby_id)
	_print_current_members(lobby_id)


func _on_lobby_chat_update(lobby_id: int, changed_id: int, _making_change_id: int, chat_state: int) -> void:
	if lobby_id != current_lobby_id:
		return
	if (chat_state & Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED) != 0:
		print("Player joined lobby: %s" % Steam.getFriendPersonaName(changed_id))
	elif (chat_state & Steam.CHAT_MEMBER_STATE_CHANGE_LEFT) != 0:
		print("Player left lobby: %s" % Steam.getFriendPersonaName(changed_id))
	elif (chat_state & Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED) != 0:
		print("Player disconnected lobby: %s" % Steam.getFriendPersonaName(changed_id))


func _print_current_members(lobby_id: int) -> void:
	var member_count := int(Steam.getNumLobbyMembers(lobby_id))
	for i in range(member_count):
		var member_id := Steam.getLobbyMemberByIndex(lobby_id, i)
		print("Lobby member: %s" % Steam.getFriendPersonaName(member_id))


func _load_local_avatar() -> void:
	var image_id := int(Steam.getLargeFriendAvatar(steam_id))
	if image_id <= 0:
		return
	var size: Dictionary = Steam.getImageSize(image_id)
	var width := int(size.get("width", 0))
	var height := int(size.get("height", 0))
	if width <= 0 or height <= 0:
		return
	var rgba_data = Steam.getImageRGBA(image_id)
	var rgba: PackedByteArray
	if rgba_data is PackedByteArray:
		rgba = rgba_data
	elif rgba_data is Dictionary:
		if not bool(rgba_data.get("success", false)):
			return
		rgba = rgba_data.get("buffer", PackedByteArray())
	if rgba.is_empty():
		return
	var image := Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, rgba)
	player_avatar = ImageTexture.create_from_image(image)
