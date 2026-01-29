extends Area3D

@export var popup_path: NodePath = NodePath("CompletionPopup")
@export var one_shot: bool = true

var _player: CharacterBody3D
var _was_on_floor: bool = false
var _completed: bool = false

@onready var _popup: Node = get_node_or_null(popup_path)

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

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
	var popup := _popup if _popup else get_node_or_null(popup_path)
	if popup and popup.has_method("show_popup"):
		popup.call_deferred("show_popup")
	else:
		push_warning("CompletionZone: popup not found at %s" % [popup_path])
	if one_shot:
		monitoring = false
		monitorable = false
