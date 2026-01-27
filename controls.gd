extends CanvasLayer

@export var show_pointer_lock_hint: bool = false
@export var embedded: bool = false
@onready var ui_change_sfx: AudioStreamPlayer = $UIChangeSfx
@onready var dim_rect: ColorRect = $Control/ColorRect
@onready var pointer_lock_hint: Label = $Control/PointerLockHint
var _ui_rng := RandomNumberGenerator.new()
var _previous_focus_path: NodePath = NodePath("")

func _ready():
	# Ensure the panel is clickable
	set_process_input(not embedded)
	process_mode = Node.PROCESS_MODE_ALWAYS # Continue processing even if paused
	if not embedded:
		get_tree().paused = true
		var focused := get_viewport().gui_get_focus_owner()
		if focused:
			_previous_focus_path = focused.get_path()
	
	# Show/Hide Main Menu button
	var close_button = $Control/CenterContainer/VBoxContainer/CloseButton
	close_button.focus_mode = Control.FOCUS_ALL
	close_button.grab_focus()

	_register_ui_change(close_button)

	pointer_lock_hint.visible = show_pointer_lock_hint and not embedded
	if embedded and dim_rect:
		dim_rect.visible = false
	if embedded:
		var base_control := $Control
		if base_control:
			base_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer = 200
		if base_control:
			base_control.modulate = Color(1, 1, 1, 1)
		var title_label := $Control/CenterContainer/VBoxContainer/Label as Label
		if title_label:
			title_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	# When showing controls, we might want to make sure mouse is visible
	if not embedded and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_ui_rng.randomize()
	if embedded and close_button:
		close_button.visible = false
		close_button.focus_mode = Control.FOCUS_NONE

func _close_controls() -> void:
	if embedded:
		return
	get_tree().paused = false
	if not _is_game_active():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if _previous_focus_path != NodePath(""):
			var root := get_tree().root
			var target := root.get_node_or_null(_previous_focus_path) as Control if root else null
			if target:
				target.call_deferred("grab_focus")
		else:
			var play_button = get_tree().current_scene.get_node_or_null("UI/MainMenu/VBoxContainer/PlayButton")
			if play_button:
				play_button.call_deferred("grab_focus")
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()

func _exit_tree():
	# Restore mouse mode if we're in a level (where it's usually captured)
	# This is a bit simplistic, but should work for now.
	# If we are in Main menu, it's already visible.
	# If we are in level, it was captured.
	if embedded:
		return
	if _is_game_active():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().paused = false

func _on_close_button_pressed():
	_close_controls()

func _input(event):
	if embedded:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_controls()

func _register_ui_change(control: Control) -> void:
	if not control:
		return
	control.focus_entered.connect(_on_ui_change)
	control.mouse_entered.connect(_on_hover_focus.bind(control))
	if control is BaseButton:
		control.pressed.connect(_on_ui_change)

func _on_ui_change() -> void:
	if ui_change_sfx:
		ui_change_sfx.pitch_scale = _ui_rng.randf_range(0.94, 1.06)
		ui_change_sfx.play()

func _on_hover_focus(control: Control) -> void:
	if not control or not control.visible:
		return
	if control.focus_mode == Control.FOCUS_NONE:
		return
	control.grab_focus()
	_on_ui_change()

func _is_game_active() -> bool:
	var current_scene := get_tree().current_scene
	if current_scene and current_scene.has_method("is_game_active"):
		return bool(current_scene.call("is_game_active"))
	return current_scene and current_scene.name != "Main"
