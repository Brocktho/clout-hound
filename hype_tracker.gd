extends Node
class_name HypeTracker

signal score_changed(current_score: float, display_score: float)
signal combo_changed(multiplier: int)
signal combo_dropped

var _score: float = 0.0
var _display_score: float = 0.0
var _combo_multiplier: int = 1
var _last_trick_time: float = 0.0
var _combo_window: float = 2.5 # Time in seconds before combo resets

var _rng = RandomNumberGenerator.new()

func _ready() -> void:
    _rng.randomize()

func _process(delta: float) -> void:
    # Smooth score display for UI
    _display_score = lerp(_display_score, _score, delta * 5.0)
    score_changed.emit(_score, _display_score)
    
    # Check combo decay
    if _combo_multiplier > 1:
        var now_sec = Time.get_ticks_msec() / 1000.0
        if now_sec - _last_trick_time > _combo_window:
            reset_combo()
            combo_dropped.emit()

func add_trick_score(base_points: float) -> void:
    _refresh_combo_timer()
    _increment_multiplier()
    _score += base_points * _combo_multiplier

func add_grind_score(tick_points: float) -> void:
    _refresh_combo_timer()
    # Grind sustains combo but uses current multiplier
    _score += tick_points * _combo_multiplier

func reset_combo() -> void:
    _combo_multiplier = 1
    combo_changed.emit(_combo_multiplier)

func fail_combo() -> void:
    reset_combo()
    # Optional: Penalties could go here

func get_multiplier() -> int:
    return _combo_multiplier

func _refresh_combo_timer() -> void:
    _last_trick_time = Time.get_ticks_msec() / 1000.0

func _increment_multiplier() -> void:
    if _combo_multiplier < 10: # Max x10
        _combo_multiplier += 1
        combo_changed.emit(_combo_multiplier)