extends Area3D

@export var popup_path: NodePath = NodePath("CompletionPopup")
@export var one_shot: bool = true

var _player: CharacterBody3D
var _was_on_floor: bool = false
var _completed: bool = false
var _completion_timer: Timer

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	_completion_timer = Timer.new()
	_completion_timer.one_shot = true
	_completion_timer.wait_time = 0.1
	_completion_timer.timeout.connect(_on_completion_timeout)
	add_child(_completion_timer)

func _physics_process(_delta: float) -> void:
	if _completed or not _player:
		return
	if not is_instance_valid(_player):
		_player = null
		return
	var on_floor := _player.is_on_floor()
	if on_floor and not _was_on_floor:
		_complete()
		return
	_was_on_floor = on_floor

func _on_body_entered(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	_player = body as CharacterBody3D
	if _player:
		_was_on_floor = _player.is_on_floor()

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
		_was_on_floor = false

func _complete() -> void:
	_completed = true
	if _completion_timer:
		_completion_timer.start()
	else:
		Global.emit_level_completed()
	if one_shot:
		monitoring = false
		monitorable = false

func _on_completion_timeout() -> void:
	Global.emit_level_completed()
