extends MultiplayerPeerExtension
class_name SteamP2PMultiplayerPeer

const DEFAULT_CHANNEL := 0
const MAX_MESSAGES_PER_POLL := 64

var _unique_id: int = 0
var _is_server: bool = false
var _connection_status: int = MultiplayerPeer.CONNECTION_DISCONNECTED
var _incoming_packets: Array[Dictionary] = []
var _packet_peer: int = 0
var _packet_channel: int = DEFAULT_CHANNEL
var _packet_mode: int = MultiplayerPeer.TRANSFER_MODE_UNRELIABLE
var _last_payload: PackedByteArray = PackedByteArray()
var _target_peer: int = 0
var _transfer_mode: int = MultiplayerPeer.TRANSFER_MODE_UNRELIABLE
var _transfer_channel: int = DEFAULT_CHANNEL
var _peers: Dictionary = {}
var _steam_channel: int = DEFAULT_CHANNEL

func configure(local_id: int, host_id: int, member_ids: Array[int]) -> void:
	_unique_id = local_id
	_is_server = local_id == host_id
	_connection_status = MultiplayerPeer.CONNECTION_CONNECTED
	_peers.clear()
	for member_id in member_ids:
		if member_id == local_id:
			continue
		_peers[member_id] = true

func add_peer(peer_id: int) -> void:
	if peer_id == _unique_id:
		return
	_peers[peer_id] = true

func remove_peer(peer_id: int) -> void:
	_peers.erase(peer_id)

func get_peer_ids() -> Array[int]:
	return _peers.keys()

func send_bytes_to(peer_id: int, payload: PackedByteArray, reliable: bool = false, channel: int = DEFAULT_CHANNEL) -> void:
	if peer_id == 0:
		return
	if not Steam or not Steam.has_method("sendMessageToUser"):
		return
	var flags := Steam.NETWORKING_SEND_UNRELIABLE
	if reliable:
		flags = Steam.NETWORKING_SEND_RELIABLE
	Steam.sendMessageToUser(peer_id, payload, flags, channel)

func broadcast_bytes(payload: PackedByteArray, except_peer: int = 0, reliable: bool = false, channel: int = DEFAULT_CHANNEL) -> void:
	for peer_id in _peers.keys():
		if peer_id == except_peer:
			continue
		send_bytes_to(peer_id, payload, reliable, channel)

func _poll() -> void:
	if not Steam or not Steam.has_method("receiveMessagesOnChannel"):
		return
	var messages = Steam.receiveMessagesOnChannel(_steam_channel, MAX_MESSAGES_PER_POLL)
	if messages is Array:
		for message in messages:
			if message is Dictionary:
				var sender_id := 0
				if message.has("steam_id"):
					sender_id = int(message["steam_id"])
				elif message.has("identity"):
					sender_id = int(message["identity"])
				elif message.has("peer_id"):
					sender_id = int(message["peer_id"])
				var payload: PackedByteArray = message.get("payload", PackedByteArray())
				if sender_id != 0 and not payload.is_empty():
					_incoming_packets.append({
						"peer_id": sender_id,
						"payload": payload,
						"channel": _steam_channel,
						"mode": MultiplayerPeer.TRANSFER_MODE_UNRELIABLE
					})

func _get_available_packet_count() -> int:
	return _incoming_packets.size()

func _get_packet(r_buffer, r_channel) -> Error:
	if _incoming_packets.is_empty():
		return ERR_UNAVAILABLE
	var packet: Dictionary = _incoming_packets.pop_front()
	_packet_peer = int(packet.get("peer_id", 0))
	_packet_channel = int(packet.get("channel", DEFAULT_CHANNEL))
	_packet_mode = int(packet.get("mode", MultiplayerPeer.TRANSFER_MODE_UNRELIABLE))
	_last_payload = packet.get("payload", PackedByteArray())
	if r_buffer is PackedByteArray:
		r_buffer.resize(0)
		r_buffer.append_array(_last_payload)
	return OK

func _put_packet(p_buffer, p_channel) -> Error:
	if not (p_buffer is PackedByteArray):
		return ERR_INVALID_PARAMETER
	if p_buffer.is_empty():
		return ERR_INVALID_PARAMETER
	if _target_peer == 0:
		var channel := _transfer_channel
		if p_channel is int and p_channel != 0:
			channel = p_channel
		broadcast_bytes(p_buffer, 0, _transfer_mode == MultiplayerPeer.TRANSFER_MODE_RELIABLE, channel)
	else:
		var channel := _transfer_channel
		if p_channel is int and p_channel != 0:
			channel = p_channel
		send_bytes_to(_target_peer, p_buffer, _transfer_mode == MultiplayerPeer.TRANSFER_MODE_RELIABLE, channel)
	return OK

func _set_transfer_channel(channel: int) -> void:
	_transfer_channel = channel

func _get_transfer_channel() -> int:
	return _transfer_channel

func _set_transfer_mode(mode: int) -> void:
	_transfer_mode = mode

func _get_transfer_mode() -> int:
	return _transfer_mode

func _set_target_peer(peer_id: int) -> void:
	_target_peer = peer_id

func _get_target_peer() -> int:
	return _target_peer

func _get_packet_peer() -> int:
	return _packet_peer

func _get_packet_channel() -> int:
	return _packet_channel

func _get_packet_mode() -> int:
	return _packet_mode

func pop_packet() -> Dictionary:
	if _incoming_packets.is_empty():
		return {}
	var packet: Dictionary = _incoming_packets.pop_front()
	_packet_peer = int(packet.get("peer_id", 0))
	_packet_channel = int(packet.get("channel", DEFAULT_CHANNEL))
	_packet_mode = int(packet.get("mode", MultiplayerPeer.TRANSFER_MODE_UNRELIABLE))
	_last_payload = packet.get("payload", PackedByteArray())
	return {
		"peer_id": _packet_peer,
		"channel": _packet_channel,
		"mode": _packet_mode,
		"payload": _last_payload
	}

func _get_unique_id() -> int:
	return _unique_id

func _get_connection_status() -> int:
	return _connection_status

func _close() -> void:
	_connection_status = MultiplayerPeer.CONNECTION_DISCONNECTED
	_peers.clear()
	_incoming_packets.clear()
