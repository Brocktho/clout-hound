extends CanvasLayer

@export var controls_scene: PackedScene
@export var show_pointer_lock_hint: bool = false

@onready var ui_change_sfx: AudioStreamPlayer = $UIChangeSfx
@onready var general_tab_label: Label = $Control/Panel/VBoxContainer/TabsRow/GeneralTab/GeneralTabLabel
@onready var controls_tab_label: Label = $Control/Panel/VBoxContainer/TabsRow/ControlsTab/ControlsTabLabel
@onready var q_hint_label: Label = $Control/Panel/VBoxContainer/TabsRow/QHintLabel
@onready var e_hint_label: Label = $Control/Panel/VBoxContainer/TabsRow/EHintLabel
@onready var general_panel: Control = $Control/Panel/VBoxContainer/ContentArea/GeneralPanel
@onready var controls_panel: Control = $Control/Panel/VBoxContainer/ContentArea/ControlsPanel
@onready var main_menu_button: Button = $Control/Panel/VBoxContainer/ContentArea/GeneralPanel/GeneralContent/MainMenuButton
@onready var sfx_slider: HSlider = $Control/Panel/VBoxContainer/ContentArea/GeneralPanel/GeneralContent/SfxSlider
@onready var music_slider: HSlider = $Control/Panel/VBoxContainer/ContentArea/GeneralPanel/GeneralContent/MusicSlider
@onready var disable_grind_sfx_check: CheckBox = $Control/Panel/VBoxContainer/ContentArea/GeneralPanel/GeneralContent/DisableGrindSfxCheck

var _tabs: Array[StringName] = [&"General", &"Controls"]
var _current_tab_index: int = 0
var _controls_instance: CanvasLayer
var _previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE
var _previous_focus_path: NodePath = NodePath("")
var _ui_rng := RandomNumberGenerator.new()
var _suppress_ui_change: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ui_rng.randomize()
	if not controls_scene:
		controls_scene = load("res://Controls.tscn")
	var current_scene := get_tree().current_scene
	var in_game := current_scene and current_scene.name != "Main"
	if in_game:
		_previous_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = true
		var focused := get_viewport().gui_get_focus_owner()
		if focused:
			_previous_focus_path = focused.get_path()

	main_menu_button.focus_mode = Control.FOCUS_ALL
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	if sfx_slider:
		sfx_slider.focus_mode = Control.FOCUS_ALL
		sfx_slider.value = Global.sfx_level
		sfx_slider.value_changed.connect(_on_sfx_value_changed)
		_register_ui_change(sfx_slider)
	if music_slider:
		music_slider.focus_mode = Control.FOCUS_ALL
		music_slider.value = Global.music_level
		music_slider.value_changed.connect(_on_music_value_changed)
		_register_ui_change(music_slider)
	if disable_grind_sfx_check:
		disable_grind_sfx_check.focus_mode = Control.FOCUS_ALL
		disable_grind_sfx_check.button_pressed = Global.disable_grind_sfx
		disable_grind_sfx_check.toggled.connect(_on_disable_grind_sfx_toggled)
		_register_ui_change(disable_grind_sfx_check)
	_register_ui_change(main_menu_button)

	_show_tab(_tabs[_current_tab_index])
	_apply_sfx_volume(Global.sfx_level)
	call_deferred("_enable_ui_change_sfx")
	_apply_disable_grind_sfx(Global.disable_grind_sfx)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()
	elif event.is_action_pressed("spin_left"):
		_cycle_tab(-1)
		_play_ui_change()
	elif event.is_action_pressed("spin_right"):
		_cycle_tab(1)
		_play_ui_change()

func _show_tab(tab_name: StringName) -> void:
	general_panel.visible = tab_name == &"General"
	controls_panel.visible = tab_name == &"Controls"
	if tab_name == &"Controls":
		if not _controls_instance and controls_scene:
			_controls_instance = controls_scene.instantiate()
			_set_controls_embedded(_controls_instance, true)
			_set_controls_pointer_hint(_controls_instance, show_pointer_lock_hint)
			controls_panel.add_child(_controls_instance)
			_connect_controls_close(_controls_instance)
		if _controls_instance:
			_controls_instance.visible = true
			_focus_first_in(_controls_instance)
	else:
		if _controls_instance:
			_controls_instance.visible = false
		_focus_first_in(general_panel)
	_update_tab_labels()

func _cycle_tab(direction: int) -> void:
	var count := _tabs.size()
	if count == 0:
		return
	_current_tab_index = posmod(_current_tab_index + direction, count)
	_show_tab(_tabs[_current_tab_index])

func _connect_controls_close(instance: CanvasLayer) -> void:
	var close_button := instance.get_node_or_null("Control/CenterContainer/VBoxContainer/CloseButton") as Button
	if close_button and not close_button.pressed.is_connected(_on_controls_close_pressed):
		close_button.pressed.connect(_on_controls_close_pressed)

func _on_controls_close_pressed() -> void:
	_current_tab_index = 0
	_show_tab(_tabs[_current_tab_index])

func _set_controls_embedded(instance: CanvasLayer, value: bool) -> void:
	if not instance:
		return
	if _has_property(instance, "embedded"):
		instance.set("embedded", value)

func _set_controls_pointer_hint(instance: CanvasLayer, value: bool) -> void:
	if not instance:
		return
	if _has_property(instance, "show_pointer_lock_hint"):
		instance.set("show_pointer_lock_hint", value)

func _has_property(obj: Object, property_name: String) -> bool:
	for item in obj.get_property_list():
		if item.name == property_name:
			return true
	return false

func _focus_first_in(root: Node) -> void:
	for child in root.get_children():
		var control := child as Control
		if control and control.focus_mode != Control.FOCUS_NONE and control.visible:
			control.grab_focus()
			return
		if child.get_child_count() > 0:
			_focus_first_in(child)
			if get_viewport().gui_get_focus_owner():
				return

func _update_tab_labels() -> void:
	var general_active := _tabs[_current_tab_index] == &"General"
	var controls_active := _tabs[_current_tab_index] == &"Controls"
	general_tab_label.text = "[General]" if general_active else "General"
	controls_tab_label.text = "[Controls]" if controls_active else "Controls"
	q_hint_label.text = "[Q]" if controls_active else "Q"
	e_hint_label.text = "[E]" if general_active else "E"

func _register_ui_change(control: Control) -> void:
	if not control:
		return
	control.focus_entered.connect(_play_ui_change)
	control.mouse_entered.connect(_play_ui_change)
	if control is BaseButton:
		control.pressed.connect(_play_ui_change)

func _play_ui_change() -> void:
	if _suppress_ui_change:
		return
	if not is_inside_tree():
		return
	if ui_change_sfx and ui_change_sfx.is_inside_tree():
		ui_change_sfx.pitch_scale = _ui_rng.randf_range(0.94, 1.06)
		ui_change_sfx.play()

func _enable_ui_change_sfx() -> void:
	_suppress_ui_change = false

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")

func _exit_tree() -> void:
	var current_scene := get_tree().current_scene
	if current_scene and current_scene.name != "Main":
		get_tree().paused = false
		Input.mouse_mode = _previous_mouse_mode
		if _previous_focus_path != NodePath(""):
			var target := current_scene.get_node_or_null(_previous_focus_path) as Control
			if target:
				target.grab_focus()

func _on_sfx_value_changed(value: float) -> void:
	Global.sfx_level = clamp(value, 0.0, 2.0)
	_apply_sfx_volume(Global.sfx_level)

func _on_music_value_changed(_value: float) -> void:
	Global.set_music_level(_value)

func _on_disable_grind_sfx_toggled(pressed: bool) -> void:
	Global.disable_grind_sfx = pressed
	_apply_disable_grind_sfx(pressed)

func _apply_sfx_volume(value: float) -> void:
	var db := -80.0 if value <= 0.001 else linear_to_db(value)
	var bus_index := Global.ensure_bus(&"SFX")
	AudioServer.set_bus_volume_db(bus_index, db)

func _apply_disable_grind_sfx(disabled: bool) -> void:
	var scene := get_tree().current_scene
	if not scene:
		return
	var grind_player := scene.find_child("GrindSfx", true, false) as AudioStreamPlayer3D
	if not grind_player:
		return
	if disabled:
		grind_player.stop()
		grind_player.volume_db = -80.0
	else:
		grind_player.volume_db = 0.0
