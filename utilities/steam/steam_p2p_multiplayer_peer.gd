class_name SteamP2PMultiplayerPeer
extends RefCounted

const DEFAULT_CHANNEL := 0
const PACKET_READ_LIMIT := 32

var _unique_id: int = 0
var _host_id: int = 0
var _is_server: bool = false
var _lobby_id: int = 0
var _incoming_packets: Array[Dictionary] = []
var _handshake_sent_time: int = 0
var _handshake_confirmed: bool = false
const HANDSHAKE_RETRY_INTERVAL_MSEC := 500

func configure(local_id: int, host_id: int, lobby_id: int) -> void:
	_unique_id = local_id
	_host_id = host_id
	_is_server = local_id == host_id
	_lobby_id = lobby_id
	_incoming_packets.clear()
	_handshake_sent_time = 0
	_handshake_confirmed = false

	# Enable relay fallback
	if Steam and Steam.has_method("allowP2PPacketRelay"):
		Steam.allowP2PPacketRelay(true)

	# Send handshake to all current lobby members so they accept our P2P session
	_send_handshake()

func _send_handshake() -> void:
	var handshake := {"type": "handshake", "player_id": _unique_id}
	var payload := var_to_bytes(handshake)
	var members := _get_lobby_members()
	for member_id in members:
		if member_id == _unique_id:
			continue
		# Accept their session too (bidirectional)
		Steam.acceptP2PSessionWithUser(member_id)
		var success := Steam.sendP2PPacket(member_id, payload, Steam.P2P_SEND_RELIABLE, DEFAULT_CHANNEL)
		print("SteamP2PMultiplayerPeer: sent handshake to %s success=%s" % [member_id, success])
	_handshake_sent_time = Time.get_ticks_msec()

func confirm_handshake() -> void:
	_handshake_confirmed = true

func send_bytes_to(peer_id: int, payload: PackedByteArray, reliable: bool = true, channel: int = DEFAULT_CHANNEL) -> void:
	if peer_id == 0 or peer_id == _unique_id:
		return
	if not Steam:
		print("SteamP2PMultiplayerPeer: No Steam singleton")
		return
	var send_type := Steam.P2P_SEND_RELIABLE if reliable else Steam.P2P_SEND_UNRELIABLE
	var success := Steam.sendP2PPacket(peer_id, payload, send_type, channel)
	if not success:
		print("SteamP2PMultiplayerPeer: sendP2PPacket failed to peer %s" % peer_id)

func broadcast_bytes(payload: PackedByteArray, except_peer: int = 0, reliable: bool = false, channel: int = DEFAULT_CHANNEL) -> void:
	var members := _get_lobby_members()
	for member_id in members:
		if member_id == _unique_id:
			continue
		if member_id == except_peer:
			continue
		send_bytes_to(member_id, payload, reliable, channel)

func _poll() -> void:
	if not Steam:
		return

	# Retry handshake until confirmed
	if not _handshake_confirmed:
		var now := Time.get_ticks_msec()
		if now - _handshake_sent_time >= HANDSHAKE_RETRY_INTERVAL_MSEC:
			print("SteamP2PMultiplayerPeer: retrying handshake")
			_send_handshake()

	var read_count := 0
	while read_count < PACKET_READ_LIMIT:
		var packet_size := Steam.getAvailableP2PPacketSize(DEFAULT_CHANNEL)
		if packet_size <= 0:
			break
		var result: Dictionary = Steam.readP2PPacket(packet_size, DEFAULT_CHANNEL)
		if result.is_empty():
			break
		# GodotSteam may use different key names depending on version
		var sender_id: int = 0
		if result.has("steam_id_remote"):
			sender_id = int(result["steam_id_remote"])
		elif result.has("steamIDRemote"):
			sender_id = int(result["steamIDRemote"])
		var payload: PackedByteArray = result.get("data", PackedByteArray())
		if sender_id != 0 and not payload.is_empty():
			_incoming_packets.append({
				"peer_id": sender_id,
				"payload": payload,
			})
		read_count += 1

func get_available_packet_count() -> int:
	return _incoming_packets.size()

func pop_packet() -> Dictionary:
	if _incoming_packets.is_empty():
		return {}
	return _incoming_packets.pop_front()

func shutdown() -> void:
	_incoming_packets.clear()
	_lobby_id = 0
	_handshake_confirmed = false

func _get_lobby_members() -> Array[int]:
	var members: Array[int] = []
	if not Steam or _lobby_id == 0:
		return members
	var count := int(Steam.getNumLobbyMembers(_lobby_id))
	for i in range(count):
		var member_id := int(Steam.getLobbyMemberByIndex(_lobby_id, i))
		members.append(member_id)
	return members
