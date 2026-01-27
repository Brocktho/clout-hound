extends Node

@export var music_stream: AudioStream = preload("res://Assets/Audio/Music/ElectronicLoop.wav")
@export var music_autoplay: bool = true

var sfx_level: float = 1.0
var music_level: float = 1.0
var disable_grind_sfx: bool = false
var _music_player: AudioStreamPlayer
var _needs_user_gesture: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("Global ready, autoload ok")
	ensure_bus(&"SFX")
	ensure_bus(&"Music")
	_setup_music_player()
	_apply_music_volume(music_level)
	_try_start_music()

func set_music_level(value: float) -> void:
	music_level = clamp(value, 0.0, 2.0)
	_apply_music_volume(music_level)

func _input(event: InputEvent) -> void:
	if not _needs_user_gesture:
		return
	if event is InputEventKey and event.pressed:
		_try_start_music()
	elif event is InputEventMouseButton and event.pressed:
		_try_start_music()
	elif event is InputEventJoypadButton and event.pressed:
		_try_start_music()

func _setup_music_player() -> void:
	if not _music_player:
		_music_player = AudioStreamPlayer.new()
		_music_player.name = "GlobalMusicPlayer"
		_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_music_player)
		print("GlobalMusicPlayer created")
	if not music_stream:
		music_stream = load("res://Assets/Audio/Music/ElectronicLoop.wav")
	if music_stream:
		_music_player.stream = _prepare_music_stream(music_stream)
		print("Music stream set, length=", _music_player.stream.get_length())
	_music_player.bus = &"Music"
	_music_player.stream_paused = false

func ensure_bus(bus_name: StringName) -> int:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		var insert_index := AudioServer.get_bus_count()
		AudioServer.add_bus(insert_index)
		AudioServer.set_bus_name(insert_index, bus_name)
		AudioServer.set_bus_send(insert_index, "Master")
		AudioServer.set_bus_mute(insert_index, false)
		bus_index = insert_index
	return bus_index

func _prepare_music_stream(stream: AudioStream) -> AudioStream:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		return wav
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	return stream

func _apply_music_volume(value: float) -> void:
	var db := -80.0 if value <= 0.001 else linear_to_db(value)
	if _music_player:
		_music_player.volume_db = db

func _try_start_music() -> void:
	_setup_music_player()
	if not _music_player:
		return
	if music_stream:
		_print_bus_state(&"Master")
		_print_bus_state(&"Music")
		print("GlobalMusicPlayer attempting play, autoplay=", music_autoplay, " playing(before)=", _music_player.playing)
		AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), false)
		AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), false)
		_music_player.play()
		print("GlobalMusicPlayer play() called, playing(after)=", _music_player.playing, " stream=", _music_player.stream, " bus=", _music_player.bus, " vol_db=", _music_player.volume_db)
		call_deferred("_report_music_signal")
	if _music_player.playing:
		_needs_user_gesture = false

func _print_bus_state(bus_name: StringName) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		print("Bus missing:", bus_name)
		return
	var db := AudioServer.get_bus_volume_db(bus_index)
	var mute := AudioServer.is_bus_mute(bus_index)
	var send := AudioServer.get_bus_send(bus_index)
	print("Bus state:", bus_name, " index=", bus_index, " db=", db, " mute=", mute, " send=", send)

func _report_music_signal() -> void:
	await get_tree().create_timer(0.3).timeout
	_print_bus_peaks(&"Music")
	_print_bus_peaks(&"Master")
	if _music_player:
		print("Music playback position=", _music_player.get_playback_position(), " playing=", _music_player.playing)
	await get_tree().create_timer(0.7).timeout
	_print_bus_peaks(&"Music")
	_print_bus_peaks(&"Master")
	if _music_player:
		print("Music playback position(after)=", _music_player.get_playback_position(), " playing=", _music_player.playing)

func _print_bus_peaks(bus_name: StringName) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	var peak_l := AudioServer.get_bus_peak_volume_left_db(bus_index, 0)
	var peak_r := AudioServer.get_bus_peak_volume_right_db(bus_index, 0)
	print("Bus peaks:", bus_name, " L=", peak_l, " R=", peak_r)
