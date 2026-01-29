extends CanvasLayer

@export var level_row_scene: PackedScene
@export var tutorial_levels: Array[LevelInformation] = []
@export var challenge_levels: Array[LevelInformation] = []
@export var free_skate_levels: Array[LevelInformation] = []

@export var star_filled: Texture2D
@export var star_empty: Texture2D
@export var clock_icon: Texture2D
@export var score_icon: Texture2D
@export var preview_placeholder: Texture2D

@onready var ui_change_sfx: AudioStreamPlayer = $UIChangeSfx
@onready var tutorials_tab_label: Label = $Control/Panel/VBoxContainer/TabsRow/TutorialsTab/TutorialsTabLabel
@onready var challenges_tab_label: Label = $Control/Panel/VBoxContainer/TabsRow/ChallengesTab/ChallengesTabLabel
@onready var free_skate_tab_label: Label = $Control/Panel/VBoxContainer/TabsRow/FreeSkateTab/FreeSkateTabLabel
@onready var tutorials_tab_panel: Control = $Control/Panel/VBoxContainer/TabsRow/TutorialsTab
@onready var challenges_tab_panel: Control = $Control/Panel/VBoxContainer/TabsRow/ChallengesTab
@onready var free_skate_tab_panel: Control = $Control/Panel/VBoxContainer/TabsRow/FreeSkateTab
@onready var q_hint_label: Label = $Control/Panel/VBoxContainer/TabsRow/QHintLabel
@onready var e_hint_label: Label = $Control/Panel/VBoxContainer/TabsRow/EHintLabel
@onready var close_button_top: Button = $Control/Panel/VBoxContainer/TabsRow/CloseButtonTop
@onready var tutorials_panel: Control = $Control/Panel/VBoxContainer/ContentArea/TutorialsPanel
@onready var challenges_panel: Control = $Control/Panel/VBoxContainer/ContentArea/ChallengesPanel
@onready var free_skate_panel: Control = $Control/Panel/VBoxContainer/ContentArea/FreeSkatePanel
@onready var tutorial_rows_container: VBoxContainer = $Control/Panel/VBoxContainer/ContentArea/TutorialsPanel/ContentRow/LevelsScroll/LevelsContent
@onready var preview_texture_rect: TextureRect = $Control/Panel/VBoxContainer/ContentArea/TutorialsPanel/ContentRow/PreviewPanel/PreviewTexture

var _tabs: Array[StringName] = [&"Tutorials", &"Challenges", &"FreeSkate"]
var _current_tab_index: int = 0
var _ui_rng := RandomNumberGenerator.new()
var _suppress_ui_change: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ui_rng.randomize()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not level_row_scene:
		level_row_scene = load("res://LevelRow.tscn")
	_register_ui_change(tutorials_tab_panel)
	_register_ui_change(challenges_tab_panel)
	_register_ui_change(free_skate_tab_panel)
	if tutorials_tab_panel and not tutorials_tab_panel.gui_input.is_connected(_on_tab_gui_input):
		tutorials_tab_panel.gui_input.connect(_on_tab_gui_input.bind(0))
	if challenges_tab_panel and not challenges_tab_panel.gui_input.is_connected(_on_tab_gui_input):
		challenges_tab_panel.gui_input.connect(_on_tab_gui_input.bind(1))
	if free_skate_tab_panel and not free_skate_tab_panel.gui_input.is_connected(_on_tab_gui_input):
		free_skate_tab_panel.gui_input.connect(_on_tab_gui_input.bind(2))
	if close_button_top:
		close_button_top.focus_mode = Control.FOCUS_ALL
		close_button_top.pressed.connect(_on_close_pressed)
		_register_ui_change(close_button_top)
	_show_tab(_tabs[_current_tab_index])
	call_deferred("_enable_ui_change_sfx")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()
	elif event.is_action_pressed("spin_left"):
		_cycle_tab(-1)
		_play_ui_change()
	elif event.is_action_pressed("spin_right"):
		_cycle_tab(1)
		_play_ui_change()

func _show_tab(tab_name: StringName) -> void:
	tutorials_panel.visible = tab_name == &"Tutorials"
	challenges_panel.visible = tab_name == &"Challenges"
	free_skate_panel.visible = tab_name == &"FreeSkate"
	if tab_name == &"Tutorials":
		_populate_rows(tutorial_levels)
		_focus_first_row()
	elif tab_name == &"Challenges":
		_clear_rows()
		_focus_first_in(challenges_panel)
	else:
		_clear_rows()
		_focus_first_in(free_skate_panel)
	_update_tab_labels()

func _cycle_tab(direction: int) -> void:
	var count := _tabs.size()
	if count == 0:
		return
	_current_tab_index = posmod(_current_tab_index + direction, count)
	_show_tab(_tabs[_current_tab_index])

func _on_tab_gui_input(event: InputEvent, tab_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_current_tab_index = tab_index
		_show_tab(_tabs[_current_tab_index])
		_play_ui_change()

func _populate_rows(levels: Array[LevelInformation]) -> void:
	_clear_rows()
	var icons := {
		"star_filled": star_filled,
		"star_empty": star_empty,
		"clock": clock_icon,
		"score": score_icon
	}
	for level_info in levels:
		if not level_info:
			continue
		var row := level_row_scene.instantiate() as Control
		if row and row.has_method("setup"):
			row.call("setup", level_info, icons)
			row.connect("play_requested", _on_play_requested)
			row.connect("preview_requested", _on_preview_requested)
			tutorial_rows_container.add_child(row)
	if preview_placeholder and preview_texture_rect:
		preview_texture_rect.texture = preview_placeholder

func _clear_rows() -> void:
	if not tutorial_rows_container:
		return
	for child in tutorial_rows_container.get_children():
		child.queue_free()

func _on_play_requested(level_info: LevelInformation) -> void:
	if not level_info or level_info.scene_path == "":
		return
	var current_scene := get_tree().current_scene
	if current_scene and current_scene.has_method("start_level"):
		current_scene.call_deferred("start_level", level_info.scene_path)
	else:
		get_tree().change_scene_to_file(level_info.scene_path)
	queue_free()

func _on_preview_requested(level_info: LevelInformation) -> void:
	if not preview_texture_rect:
		return
	if not level_info or level_info.preview_image_path == "":
		preview_texture_rect.texture = preview_placeholder
		return
	var tex := load(level_info.preview_image_path) as Texture2D
	if tex:
		preview_texture_rect.texture = tex
	else:
		preview_texture_rect.texture = preview_placeholder

func _update_tab_labels() -> void:
	var tutorials_active := _tabs[_current_tab_index] == &"Tutorials"
	var challenges_active := _tabs[_current_tab_index] == &"Challenges"
	var free_skate_active := _tabs[_current_tab_index] == &"FreeSkate"
	tutorials_tab_label.text = "[Tutorials]" if tutorials_active else "Tutorials"
	challenges_tab_label.text = "[Challenges]" if challenges_active else "Challenges"
	free_skate_tab_label.text = "[Free Skate]" if free_skate_active else "Free Skate"
	q_hint_label.text = "[Q]" if challenges_active or free_skate_active else "Q"
	e_hint_label.text = "[E]" if tutorials_active or challenges_active else "E"

func _register_ui_change(control: Control) -> void:
	if not control:
		return
	control.focus_entered.connect(_play_ui_change)
	control.mouse_entered.connect(_on_hover_focus.bind(control))
	if control is BaseButton:
		control.pressed.connect(_play_ui_change)

func _on_hover_focus(control: Control) -> void:
	if not control or not control.visible:
		return
	if control.focus_mode == Control.FOCUS_NONE:
		return
	control.grab_focus()
	_play_ui_change()

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

func _on_close_pressed() -> void:
	var current_scene := get_tree().current_scene
	if current_scene and current_scene.has_method("return_to_menu"):
		current_scene.call_deferred("return_to_menu")
	queue_free()

func _focus_first_row() -> void:
	if not tutorial_rows_container:
		return
	for child in tutorial_rows_container.get_children():
		var control := child as Control
		if control and control.focus_mode != Control.FOCUS_NONE and control.visible:
			control.grab_focus()
			return

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
