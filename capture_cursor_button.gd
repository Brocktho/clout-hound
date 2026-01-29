extends CanvasLayer

@onready var capture_button: Button = $Control/CaptureCursorButton

func _ready() -> void:
	if capture_button:
		capture_button.pressed.connect(_on_capture_button_pressed)
	_update_button_state()

func _process(_delta: float) -> void:
	_update_button_state()

func _update_button_state() -> void:
	var is_captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if capture_button:
		var suppress_for_completion := Global.completion_popup_active
		capture_button.visible = not is_captured and not suppress_for_completion

func _on_capture_button_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_update_button_state()
