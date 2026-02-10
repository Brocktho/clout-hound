extends Node
class_name HypeTracker

signal score_changed(current_score: float, display_score: float)
signal combo_changed(multiplier: int)
signal combo_dropped

var _score: float = 0.0 # Secure, banked score
var _pending_score: float = 0.0 # Current combo accumulation
var _display_score: float = 0.0
var _combo_multiplier: int = 1
var _trick_history: Dictionary = {} # Tracks usage counts: { "Kickflip": 3 }

var _rng = RandomNumberGenerator.new()

func _ready() -> void:
    _rng.randomize()

func _process(delta: float) -> void:
    # Smooth score display for UI (lerping)
    # Display shows Banked + (Pending * Multiplier)
    var total_potential = _score + (_pending_score * _combo_multiplier)
    _display_score = lerp(_display_score, total_potential, delta * 5.0)
    score_changed.emit(total_potential, _display_score)
    
func add_trick_score(trick_name: String, base_points: float) -> void:
    # 1. Calculate Staleness
    var count = _trick_history.get(trick_name, 0)
    var decay_factor = pow(0.85, count) # 15% reduction per use
    var final_points = base_points * decay_factor
    
    # Update History
    _trick_history[trick_name] = count + 1
    
    # 2. Add to Pending
    _pending_score += final_points
    _increment_multiplier()

func add_grind_score(tick_points: float) -> void:
    # Grinds add raw score to the pending pot
    _pending_score += tick_points

func bank_combo() -> void:
    if _pending_score > 0:
        _score += _pending_score * _combo_multiplier
        _reset_combo_state()

func fail_combo() -> void:
    _reset_combo_state()
    combo_dropped.emit()

func _reset_combo_state() -> void:
    _pending_score = 0.0
    _combo_multiplier = 1
    # Clear staleness history when combo resets (landing or bailing)
    _trick_history.clear()
    combo_changed.emit(_combo_multiplier)

func get_multiplier() -> int:
    return _combo_multiplier

func _increment_multiplier() -> void:
    if _combo_multiplier < 10: # Max x10
        _combo_multiplier += 1
        combo_changed.emit(_combo_multiplier)