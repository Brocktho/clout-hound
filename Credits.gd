extends CanvasLayer

@export var embedded_mode: bool = false
@onready var sfx_player: AudioStreamPlayer = $UIChangeSfx
@onready var backdrop: ColorRect = $Control/ColorRect
var _pitch_rng := RandomNumberGenerator.new()
var _stored_focus: NodePath = NodePath("")

func _ready():
    _pitch_rng.randomize()
    set_process_input(not embedded_mode)
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    if not embedded_mode:
        get_tree().paused = true
        var current_focus := get_viewport().gui_get_focus_owner()
        if current_focus:
            _stored_focus = current_focus.get_path()
        if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    
    var dismiss_btn = $Control/CenterContainer/VBoxContainer/CloseButton
    dismiss_btn.focus_mode = Control.FOCUS_ALL
    dismiss_btn.grab_focus()
    _setup_button_feedback(dismiss_btn)
    
    if embedded_mode:
        if backdrop:
            backdrop.visible = false
        dismiss_btn.visible = false
        dismiss_btn.focus_mode = Control.FOCUS_NONE
        layer = 200

func _dismiss_panel() -> void:
    if embedded_mode:
        return
    get_tree().paused = false
    var game_running := _check_game_state()
    if not game_running:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        _restore_previous_focus()
    else:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    queue_free()

func _restore_previous_focus() -> void:
    if _stored_focus == NodePath(""):
        return
    var scene_root := get_tree().root
    if not scene_root:
        return
    var focus_target := scene_root.get_node_or_null(_stored_focus) as Control
    if focus_target:
        focus_target.call_deferred("grab_focus")

func _exit_tree():
    if embedded_mode:
        return
    if _check_game_state():
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        get_tree().paused = false

func _on_close_button_pressed():
    _dismiss_panel()

func _input(event):
    if embedded_mode:
        return
    if event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        _dismiss_panel()

func _setup_button_feedback(btn: Control) -> void:
    if not btn:
        return
    btn.focus_entered.connect(_play_feedback_sound)
    btn.mouse_entered.connect(_handle_hover.bind(btn))
    if btn is BaseButton:
        btn.pressed.connect(_play_feedback_sound)

func _play_feedback_sound() -> void:
    if sfx_player:
        sfx_player.pitch_scale = _pitch_rng.randf_range(0.94, 1.06)
        sfx_player.play()

func _handle_hover(btn: Control) -> void:
    if not btn or not btn.visible or btn.focus_mode == Control.FOCUS_NONE:
        return
    btn.grab_focus()
    _play_feedback_sound()

func _check_game_state() -> bool:
    var active_scene := get_tree().current_scene
    if active_scene and active_scene.has_method("is_game_active"):
        return bool(active_scene.call("is_game_active"))
    return active_scene and active_scene.name != "Main"