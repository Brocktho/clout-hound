extends Node
class_name PlayerFeedback

var player: Player

const GRIND_SFX_END_TRIM: float = 0.1
const GRIND_SFX_NEXT_START: float = 0.1
const MOVING_SFX_MIN_SPEED: float = 0.5
const MOVING_SFX_SLIDE_PITCH_MIN: float = 0.8
const MOVING_SFX_SLIDE_PITCH_MAX: float = 0.9

var grind_sfx_play_id: int = 0
var was_sliding: bool = false
var sfx_rng: RandomNumberGenerator = RandomNumberGenerator.new()

var grind_sparks: GPUParticles3D
var ragdoll_sfx_player: AudioStreamPlayer3D
var jump_sfx_player: AudioStreamPlayer3D
var landing_sfx_player: AudioStreamPlayer3D
var airborne_sfx_player: AudioStreamPlayer3D
var moving_sfx_player: AudioStreamPlayer3D
var grind_sfx_player: AudioStreamPlayer3D
var trick_completion_sfx_player: AudioStreamPlayer3D

func _ready() -> void:
	if not player:
		push_error("PlayerFeedback requires a Player reference.")
		queue_free()
		return
	grind_sparks = player.get_node_or_null("GrindSparks")
	ragdoll_sfx_player = player.get_node_or_null("RagdollSfx")
	jump_sfx_player = player.get_node_or_null("JumpSfx")
	landing_sfx_player = player.get_node_or_null("LandingSfx")
	airborne_sfx_player = player.get_node_or_null("AirborneSfx")
	moving_sfx_player = player.get_node_or_null("MovingSfx")
	grind_sfx_player = player.get_node_or_null("GrindSfx")
	trick_completion_sfx_player = player.get_node_or_null("TrickCompletionSfx")
	sfx_rng.randomize()
	_connect_player_signals()
	if grind_sfx_player and not grind_sfx_player.finished.is_connected(_on_grind_sfx_finished):
		grind_sfx_player.finished.connect(_on_grind_sfx_finished)
	if moving_sfx_player and not moving_sfx_player.finished.is_connected(_on_moving_sfx_finished):
		moving_sfx_player.finished.connect(_on_moving_sfx_finished)
	_apply_grind_sfx_setting()

func _connect_player_signals() -> void:
	player.jump_started.connect(_on_jump_started)
	player.airborne_started.connect(_on_airborne_started)
	player.landed.connect(_on_landed)
	player.grind_started.connect(_on_grind_started)
	player.grind_tick.connect(_on_grind_tick)
	player.grind_ended.connect(_on_grind_ended)
	player.ragdoll_started.connect(_on_ragdoll_started)
	player.ragdoll_ended.connect(_on_ragdoll_ended)
	player.slide_started.connect(_on_slide_started)
	player.slide_ended.connect(_on_slide_ended)
	player.trick_completed.connect(_on_trick_completed)
	player.locomotion_state_updated.connect(_on_locomotion_state_updated)

func _on_jump_started() -> void:
	_play_jump_sfx()
	_start_airborne_sfx()

func _on_airborne_started() -> void:
	_start_airborne_sfx()

func _on_landed(_success: bool, rail_landing: bool) -> void:
	_stop_airborne_sfx()
	_play_landing_sfx(rail_landing)

func _on_grind_started(_speed: float) -> void:
	_stop_airborne_sfx()
	_stop_moving_sfx()
	if not player.is_ragdolling:
		_play_landing_sfx(true)
	_start_grind_sfx()
	if grind_sparks:
		grind_sparks.emitting = true

func _on_grind_tick(speed: float, velocity: Vector3) -> void:
	if not grind_sparks:
		return
	if velocity.length() > 0.1:
		grind_sparks.look_at(player.global_position - velocity.normalized(), Vector3.UP)
	var speed_ratio = clamp(speed / (player.max_speed * 4.0), 0.0, 1.0)
	var speed_factor = clamp(pow(speed_ratio, 2.0), 0.05, 1.0)
	grind_sparks.amount_ratio = speed_factor

func _on_grind_ended() -> void:
	_stop_grind_sfx()
	if grind_sparks:
		grind_sparks.emitting = false

func _on_ragdoll_started(_severity: float) -> void:
	_stop_grind_sfx()
	_stop_airborne_sfx()
	_stop_moving_sfx()
	if grind_sparks:
		grind_sparks.emitting = false
	_play_ragdoll_bail_sfx()

func _on_ragdoll_ended() -> void:
	_stop_grind_sfx()
	_stop_airborne_sfx()
	_stop_moving_sfx()

func _on_slide_started(_speed: float) -> void:
	pass

func _on_slide_ended() -> void:
	pass

func _on_trick_completed(_trick_name: String) -> void:
	_play_trick_completion_sfx()

func _on_locomotion_state_updated(state: int, speed: float) -> void:
	var is_ragdolling := state == Player.LocomotionState.RAGDOLL
	var is_grinding := state == Player.LocomotionState.GRIND
	var is_sliding := state == Player.LocomotionState.SLIDE
	var is_air := state == Player.LocomotionState.AIR
	var on_floor := state == Player.LocomotionState.GROUND or is_sliding

	if is_ragdolling:
		_stop_airborne_sfx()
		_stop_moving_sfx()
		was_sliding = is_sliding
		return
	if is_grinding:
		_stop_airborne_sfx()
		_stop_moving_sfx()
		was_sliding = false
		return
	if is_air:
		_stop_moving_sfx()
		_start_airborne_sfx()
	else:
		_stop_airborne_sfx()
		if on_floor and speed > MOVING_SFX_MIN_SPEED:
			_start_moving_sfx()
			if is_sliding and not was_sliding:
				_stop_moving_sfx()
				_play_moving_sfx_once(MOVING_SFX_SLIDE_PITCH_MIN, MOVING_SFX_SLIDE_PITCH_MAX)
		else:
			_stop_moving_sfx()

	was_sliding = is_sliding

func _play_ragdoll_bail_sfx() -> void:
	if not ragdoll_sfx_player or player.ragdoll_bail_sfx.is_empty():
		return
	var clip_index := sfx_rng.randi_range(0, player.ragdoll_bail_sfx.size() - 1)
	_play_sfx_with_variation(ragdoll_sfx_player, player.ragdoll_bail_sfx[clip_index], 0.93, 1.02, -2.0, 0.5)

func _play_jump_sfx() -> void:
	if not jump_sfx_player or player.jump_sfx.is_empty():
		return
	var clip_index := sfx_rng.randi_range(0, player.jump_sfx.size() - 1)
	_play_sfx_with_variation(jump_sfx_player, player.jump_sfx[clip_index], 0.97, 1.05, -1.5, 0.5)

func _play_landing_sfx(use_rail: bool) -> void:
	if not landing_sfx_player:
		return
	var clips := player.land_rail_sfx if use_rail else player.landing_sfx
	if clips.is_empty():
		return
	var clip_index := sfx_rng.randi_range(0, clips.size() - 1)
	_play_sfx_with_variation(landing_sfx_player, clips[clip_index], 0.95, 1.03, -1.5, 0.5)

func _play_trick_completion_sfx() -> void:
	if not trick_completion_sfx_player or player.trick_completion_sfx.is_empty():
		return
	var clip_index := sfx_rng.randi_range(0, player.trick_completion_sfx.size() - 1)
	_play_sfx_with_variation(trick_completion_sfx_player, player.trick_completion_sfx[clip_index], 0.95, 1.05, -6.0, -2.0)

func _start_grind_sfx() -> void:
	if Global.disable_grind_sfx or not grind_sfx_player or player.grind_sfx.is_empty():
		return
	_play_grind_sfx_once(0.0)

func _stop_grind_sfx() -> void:
	if not grind_sfx_player:
		return
	if grind_sfx_player.playing:
		grind_sfx_player.stop()
	grind_sfx_player.stream = null
	grind_sfx_play_id += 1

func _start_airborne_sfx() -> void:
	if not airborne_sfx_player or not player.airborne_sfx:
		return
	if airborne_sfx_player.playing:
		return
	var stream := player.airborne_sfx
	if stream is AudioStreamWAV:
		var wav := (stream as AudioStreamWAV).duplicate()
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
		stream = wav
	_play_sfx_with_variation(airborne_sfx_player, stream, 0.98, 1.02, -10.0, -6.0)

func _stop_airborne_sfx() -> void:
	if not airborne_sfx_player:
		return
	if airborne_sfx_player.playing:
		airborne_sfx_player.stop()
	airborne_sfx_player.stream = null

func _start_moving_sfx() -> void:
	if not moving_sfx_player or player.moving_sfx.is_empty():
		return
	if moving_sfx_player.playing:
		return
	_play_moving_sfx_once()

func _stop_moving_sfx() -> void:
	if not moving_sfx_player:
		return
	if moving_sfx_player.playing:
		moving_sfx_player.stop()
	moving_sfx_player.stream = null

func _play_moving_sfx_once(pitch_min: float = 0.98, pitch_max: float = 1.02) -> void:
	if not moving_sfx_player or player.moving_sfx.is_empty():
		return
	var clip_index := sfx_rng.randi_range(0, player.moving_sfx.size() - 1)
	var stream := player.moving_sfx[clip_index]
	_play_sfx_with_variation(moving_sfx_player, stream, pitch_min, pitch_max, -3.0, 0.0)

func _play_grind_sfx_once(start_offset: float) -> void:
	if not grind_sfx_player or player.grind_sfx.is_empty():
		return
	grind_sfx_play_id += 1
	var play_id := grind_sfx_play_id
	var clip_index := sfx_rng.randi_range(0, player.grind_sfx.size() - 1)
	var stream := player.grind_sfx[clip_index]
	_play_sfx_with_variation(grind_sfx_player, stream, 0.98, 1.02, -36.0, -18.0, start_offset)
	var clip_length := stream.get_length()
	var play_duration := maxf(0.0, clip_length - GRIND_SFX_END_TRIM - start_offset)
	_schedule_grind_sfx_stop(play_id, play_duration)

func _on_grind_sfx_finished() -> void:
	_handle_grind_sfx_end()

func _on_moving_sfx_finished() -> void:
	if _should_play_moving_sfx():
		_play_moving_sfx_once()

func _apply_grind_sfx_setting() -> void:
	if not grind_sfx_player:
		return
	if Global.disable_grind_sfx:
		grind_sfx_player.stop()
		grind_sfx_player.volume_db = -80.0
	else:
		var base_db := 0.0
		if grind_sfx_player.has_meta("sfx_base_db"):
			base_db = float(grind_sfx_player.get_meta("sfx_base_db"))
		grind_sfx_player.volume_db = Global.get_sfx_volume_db(base_db)

func _handle_grind_sfx_end() -> void:
	if player.is_grinding:
		_play_grind_sfx_once(GRIND_SFX_NEXT_START)

func _should_play_moving_sfx() -> bool:
	if player.is_grinding or player.is_ragdolling:
		return false
	if player.locomotion_state == Player.LocomotionState.AIR:
		return false
	var horizontal_speed := Vector2(player.velocity.x, player.velocity.z).length()
	return horizontal_speed > MOVING_SFX_MIN_SPEED

func _schedule_grind_sfx_stop(play_id: int, duration: float) -> void:
	if duration <= 0.0:
		return
	await get_tree().create_timer(duration).timeout
	if play_id != grind_sfx_play_id:
		return
	if not player.is_grinding or not grind_sfx_player or not grind_sfx_player.playing:
		return
	grind_sfx_player.stop()
	_handle_grind_sfx_end()

func _play_sfx_with_variation(
	player_node: AudioStreamPlayer3D,
	stream: AudioStream,
	pitch_min: float,
	pitch_max: float,
	vol_min_db: float,
	vol_max_db: float,
	start_pos: float = 0.0
) -> void:
	player_node.stream = stream
	player_node.pitch_scale = sfx_rng.randf_range(pitch_min, pitch_max)
	var base_db := sfx_rng.randf_range(vol_min_db, vol_max_db)
	player_node.set_meta("sfx_base_db", base_db)
	player_node.volume_db = Global.get_sfx_volume_db(base_db)
	player_node.play(start_pos)
