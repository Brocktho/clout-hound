extends Node

const ACTION_INPUT_STATE := "input_state"
const ACTION_EVENT := "action_event"
const ACTION_BUFFERED_TRICK := "buffered_trick"
const ACTION_SPAWN_REQUEST := "spawn_request"
const ACTION_SPAWN := "spawn"
const ACTION_DESPAWN_REQUEST := "despawn_request"
const ACTION_DESPAWN := "despawn"
const ACTION_HEARTBEAT := "heartbeat"

const HISTORY_TICKS_PER_PLAYER := 100
const HEARTBEAT_INTERVAL_MSEC := 500
const TIMEOUT_MSEC := 5000

const NETWORK_PLAYER_SCENE := preload("res://entities/player/network_player.tscn")

var active: bool = false
var is_host: bool = false
var lobby_id: int = 0
var local_steam_id: int = 0
var host_steam_id: int = 0
var peer: SteamP2PMultiplayerPeer

var local_player: Player
var players: Dictionary = {}
var action_history: Dictionary = {}
var last_heard_msec: Dictionary = {}
var last_input_state: Dictionary = {}
var timed_out: Dictionary = {}

var _steamworks: Node
var _last_heartbeat_msec: int = 0
var _last_local_action_tick: Dictionary = {}
var _local_spawn_sent: bool = false

func _ready() -> void:
	_steamworks = get_node_or_null("/root/Steamworks")

func start_session(new_lobby_id: int, host_id: int = 0) -> void:
	if active:
		print("MultiplayerSession: Already active")
		return
	lobby_id = new_lobby_id
	if not _steamworks:
		print("No Steamworks node found. Cannot start session.")
		return
	local_steam_id = int(_steamworks.get("steam_id"))
	host_steam_id = host_id
	if host_steam_id == 0:
		host_steam_id = _get_lobby_owner(new_lobby_id)
	is_host = local_steam_id == host_steam_id
	if is_host:
		print("MultiplayerSession: You are the host (local_id=%s lobby_id=%s)" % [local_steam_id, lobby_id])
	peer = SteamP2PMultiplayerPeer.new()
	peer.configure(local_steam_id, host_steam_id, new_lobby_id)
	active = true
	_last_heartbeat_msec = Time.get_ticks_msec()

func stop_session() -> void:
	if not active:
		return
	active = false
	local_player = null
	players.clear()
	action_history.clear()
	last_heard_msec.clear()
	last_input_state.clear()
	timed_out.clear()
	_local_spawn_sent = false
	if peer:
		peer.close()
	peer = null

func queue_local_action(action: StringName, tick: int) -> void:
	if not active or use_networked_local():
		return
	var last_tick := int(_last_local_action_tick.get(action, -1))
	if last_tick == tick:
		return
	_last_local_action_tick[action] = tick
	var packet := {
		"type": ACTION_EVENT,
		"tick": tick,
		"player_id": local_steam_id,
		"action": StringName(action)
	}
	_record_action(local_steam_id, packet)
	_send_to_host(packet)

func notify_local_buffered_trick(trick_name: String) -> void:
	if not active or use_networked_local():
		return
	var packet := {
		"type": ACTION_BUFFERED_TRICK,
		"tick": Engine.get_physics_frames(),
		"player_id": local_steam_id,
		"trick": trick_name
	}
	_record_action(local_steam_id, packet)
	_send_to_host(packet)

func request_despawn() -> void:
	if not active:
		return
	var packet := {
		"type": ACTION_DESPAWN_REQUEST,
		"player_id": local_steam_id
	}
	_send_to_host(packet)

func use_networked_local() -> bool:
	return local_player != null and local_player.use_network_input

func _process(_delta: float) -> void:
	if not active:
		return
	_refresh_local_player()
	_send_heartbeat_if_needed()
	_poll_packets()
	_update_timeouts()
	_send_local_input_state()

func _refresh_local_player() -> void:
	if local_player and is_instance_valid(local_player):
		return
	if local_player and not is_instance_valid(local_player):
		local_player = null
	var candidates := get_tree().get_nodes_in_group("player")
	for candidate in candidates:
		var player := candidate as Player
		if not player:
			continue
		if players.has(player.player_id) and player.player_id != 0:
			continue
		local_player = player
		local_player.set_player_id(local_steam_id)
		players[local_steam_id] = local_player
		if not local_player.buffered_trick_completed.is_connected(notify_local_buffered_trick):
			local_player.buffered_trick_completed.connect(notify_local_buffered_trick)
		if is_host:
			_announce_local_spawn()
		else:
			_request_spawn()
		return

func _send_local_input_state() -> void:
	if not local_player or not is_instance_valid(local_player):
		return
	if not active:
		return
	var move_input : Vector2 = local_player.get_move_vector()
	var slide_pressed : bool = local_player.is_action_pressed(&"slide")
	var yaw := local_player.spring_arm.global_rotation.y if local_player.spring_arm else local_player.global_rotation.y
	var packet := {
		"type": ACTION_INPUT_STATE,
		"tick": Engine.get_physics_frames(),
		"player_id": local_steam_id,
		"move": move_input,
		"slide": slide_pressed,
		"yaw": yaw
	}
	_record_action(local_steam_id, packet)
	_send_to_host(packet)

func _poll_packets() -> void:
	if not peer:
		return
	peer._poll()
	while peer.get_available_packet_count() > 0:
		var raw := peer.pop_packet()
		if raw.is_empty():
			continue
		var payload: PackedByteArray = raw.get("payload", PackedByteArray())
		if payload.is_empty():
			continue
		var packet = bytes_to_var(payload)
		if packet is Dictionary:
			_handle_packet(packet, int(raw.get("peer_id", 0)))

func _handle_packet(packet: Dictionary, sender_id: int) -> void:
	var packet_type := String(packet.get("type", ""))
	var player_id := int(packet.get("player_id", 0))
	if player_id == 0:
		player_id = sender_id

	# Diagnostic: log ALL packets (remove this after debugging)
	if packet_type != ACTION_HEARTBEAT:
		print("MultiplayerSession: recv type=%s from=%s player_id=%s" % [packet_type, sender_id, player_id])

	last_heard_msec[player_id] = Time.get_ticks_msec()
	timed_out[player_id] = false
	match packet_type:
		"handshake":
			print("MultiplayerSession: handshake from %s" % player_id)
			# Accept their session back
			Steam.acceptP2PSessionWithUser(player_id)
		ACTION_SPAWN_REQUEST:
			if is_host:
				_handle_spawn_request(packet, player_id)
		ACTION_SPAWN:
			if not is_host:
				_handle_spawn(packet)
		ACTION_DESPAWN_REQUEST:
			if is_host:
				_handle_despawn_request(packet, player_id)
		ACTION_DESPAWN:
			if not is_host:
				_handle_despawn(packet)
		ACTION_INPUT_STATE:
			_handle_input_state(packet, player_id, sender_id)
		ACTION_EVENT:
			_handle_action_event(packet, player_id, sender_id)
		ACTION_BUFFERED_TRICK:
			_handle_buffered_trick(packet, player_id, sender_id)
		ACTION_HEARTBEAT:
			pass

func _handle_spawn_request(packet: Dictionary, player_id: int) -> void:
	if players.has(player_id):
		_send_existing_spawns(player_id)
		return
	var spawn_pos: Vector3 = packet.get("initial_position", Vector3.ZERO)
	_spawn_remote_player(player_id, spawn_pos)
	_send_existing_spawns(player_id)
	_broadcast_spawn(player_id, spawn_pos)

func _handle_spawn(packet: Dictionary) -> void:
	var player_id := int(packet.get("player_id", 0))
	if player_id == 0 or player_id == local_steam_id:
		return
	if players.has(player_id):
		return
	var spawn_pos: Vector3 = packet.get("initial_position", Vector3.ZERO)
	_spawn_remote_player(player_id, spawn_pos)

func _handle_despawn_request(_packet: Dictionary, player_id: int) -> void:
	_remove_player(player_id)
	_broadcast_packet({
		"type": ACTION_DESPAWN,
		"player_id": player_id
	}, player_id, true)

func _handle_despawn(packet: Dictionary) -> void:
	var player_id := int(packet.get("player_id", 0))
	_remove_player(player_id)

func _handle_input_state(packet: Dictionary, player_id: int, sender_id: int) -> void:
	if is_host:
		_apply_input_state(packet, player_id)
		_broadcast_packet(packet, sender_id)
	else:
		if player_id == local_steam_id:
			return
		_apply_input_state(packet, player_id)

func _handle_action_event(packet: Dictionary, player_id: int, sender_id: int) -> void:
	if is_host:
		_apply_action_event(packet, player_id)
		_broadcast_packet(packet, sender_id)
	else:
		if player_id == local_steam_id:
			return
		_apply_action_event(packet, player_id)

func _handle_buffered_trick(packet: Dictionary, player_id: int, sender_id: int) -> void:
	if is_host:
		_apply_buffered_trick(packet, player_id)
		_broadcast_packet(packet, sender_id)
	else:
		if player_id == local_steam_id:
			return
		_apply_buffered_trick(packet, player_id)

func _apply_input_state(packet: Dictionary, player_id: int) -> void:
	var player := players.get(player_id) as Player
	if not player:
		return
	var move_input: Vector2 = packet.get("move", Vector2.ZERO)
	var slide_pressed: bool = bool(packet.get("slide", false))
	var yaw: float = float(packet.get("yaw", 0.0))
	player.set_network_input_state(move_input, slide_pressed, yaw)
	last_input_state[player_id] = packet
	_record_action(player_id, packet)

func _apply_action_event(packet: Dictionary, player_id: int) -> void:
	var player := players.get(player_id) as Player
	if not player:
		return
	var action := StringName(packet.get("action", ""))
	if action != &"":
		player.queue_network_action(action)
	_record_action(player_id, packet)

func _apply_buffered_trick(packet: Dictionary, player_id: int) -> void:
	var player := players.get(player_id) as Player
	if not player:
		return
	var trick_name := String(packet.get("trick", ""))
	if trick_name != "":
		player.apply_buffered_trick_completion(trick_name)
	_record_action(player_id, packet)

func _send_to_host(packet: Dictionary) -> void:
	if not peer:
		return
	var payload := var_to_bytes(packet)
	if is_host:
		peer.broadcast_bytes(payload, local_steam_id)
	else:
		print("MultiplayerSession: sending packet type=%s to=%s" % [packet.get("type", ""), host_steam_id])
		peer.send_bytes_to(host_steam_id, payload)

func _broadcast_packet(packet: Dictionary, except_peer: int = 0, reliable: bool = false) -> void:
	if not peer:
		return
	var payload := var_to_bytes(packet)
	peer.broadcast_bytes(payload, except_peer, reliable)

func _send_existing_spawns(target_peer_id: int) -> void:
	for entry in players:
		var player_id := int(entry)
		var player := players[player_id] as Player
		if not player:
			continue
		var packet := {
			"type": ACTION_SPAWN,
			"player_id": player_id,
			"initial_position": player.global_position
		}
		var payload := var_to_bytes(packet)
		peer.send_bytes_to(target_peer_id, payload, true)

func _announce_local_spawn() -> void:
	if _local_spawn_sent or not local_player:
		return
	_local_spawn_sent = true
	_broadcast_spawn(local_steam_id, local_player.global_position)

func _broadcast_spawn(player_id: int, spawn_pos: Vector3) -> void:
	var packet := {
		"type": ACTION_SPAWN,
		"player_id": player_id,
		"initial_position": spawn_pos
	}
	_broadcast_packet(packet, 0, true)

func _request_spawn() -> void:
	if not local_player:
		return
	var packet := {
		"type": ACTION_SPAWN_REQUEST,
		"player_id": local_steam_id,
		"initial_position": local_player.global_position
	}
	_send_to_host(packet)

func _spawn_remote_player(player_id: int, spawn_pos: Vector3) -> void:
	var parent := _get_player_parent()
	if not parent:
		return
	var instance := NETWORK_PLAYER_SCENE.instantiate() as NetworkPlayer
	if not instance:
		return
	instance.configure(player_id, false)
	instance.global_position = spawn_pos
	instance.remove_from_group("player")
	parent.add_child(instance)
	players[player_id] = instance

func _remove_player(player_id: int) -> void:
	if player_id == local_steam_id:
		return
	var player := players.get(player_id) as Player
	if player and is_instance_valid(player):
		player.queue_free()
	players.erase(player_id)

func _get_player_parent() -> Node:
	if local_player and is_instance_valid(local_player):
		return local_player.get_parent()
	return get_tree().current_scene

func _record_action(player_id: int, action: Dictionary) -> void:
	var history: Array = action_history.get(player_id, [])
	history.append(action)
	if history.size() > HISTORY_TICKS_PER_PLAYER:
		history = history.slice(history.size() - HISTORY_TICKS_PER_PLAYER)
	action_history[player_id] = history

func _send_heartbeat_if_needed() -> void:
	if not peer:
		return
	var now := Time.get_ticks_msec()
	if now - _last_heartbeat_msec < HEARTBEAT_INTERVAL_MSEC:
		return
	_last_heartbeat_msec = now
	var packet := {
		"type": ACTION_HEARTBEAT,
		"player_id": local_steam_id,
		"tick": Engine.get_physics_frames()
	}
	if is_host:
		_broadcast_packet(packet, 0)
	else:
		_send_to_host(packet)

func _update_timeouts() -> void:
	if not is_host:
		return
	var now := Time.get_ticks_msec()
	for player_id in last_heard_msec.keys():
		if player_id == local_steam_id:
			continue
		var last_seen := int(last_heard_msec[player_id])
		if now - last_seen < TIMEOUT_MSEC:
			continue
		if bool(timed_out.get(player_id, false)):
			continue
		timed_out[player_id] = true
		var player := players.get(player_id) as Player
		if not player:
			continue
		var yaw := player.global_rotation.y
		player.set_network_input_state(Vector2.ZERO, false, yaw)
		var packet := {
			"type": ACTION_INPUT_STATE,
			"tick": Engine.get_physics_frames(),
			"player_id": player_id,
			"move": Vector2.ZERO,
			"slide": false,
			"yaw": yaw
		}
		_broadcast_packet(packet, 0)

func _get_lobby_owner(target_lobby_id: int) -> int:
	if not Steam or not Steam.has_method("getLobbyOwner"):
		return local_steam_id
	return int(Steam.getLobbyOwner(target_lobby_id))

func _get_lobby_members(target_lobby_id: int) -> Array[int]:
	var members: Array[int] = []
	if not Steam or not Steam.has_method("getNumLobbyMembers"):
		return members
	var count := int(Steam.getNumLobbyMembers(target_lobby_id))
	for i in range(count):
		var member_id := int(Steam.getLobbyMemberByIndex(target_lobby_id, i))
		members.append(member_id)
	return members
