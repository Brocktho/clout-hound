extends Area3D

@export var enabled: bool = true
@export var one_shot: bool = false

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not enabled:
		return
	if body and body.is_in_group("player"):
		Global.kill_zone_triggered.emit(body)
		if one_shot:
			enabled = false
