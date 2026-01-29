extends PanelContainer

signal play_requested(level_info: LevelInformation)
signal preview_requested(level_info: LevelInformation)

@export var level_info: LevelInformation
@export var star_filled: Texture2D
@export var star_empty: Texture2D
@export var clock_icon: Texture2D
@export var score_icon: Texture2D

@onready var focus_highlight: ColorRect = $FocusHighlight
@onready var star_icon: TextureRect = $Content/LeftGroup/StarIcon
@onready var level_label: Label = $Content/LeftGroup/LevelLabel
@onready var time_icon: TextureRect = $Content/RightGroup/InfoColumn/TimeRow/TimeIcon
@onready var time_label: Label = $Content/RightGroup/InfoColumn/TimeRow/TimeLabel
@onready var score_icon_rect: TextureRect = $Content/RightGroup/InfoColumn/ScoreRow/ScoreIcon
@onready var score_label: Label = $Content/RightGroup/InfoColumn/ScoreRow/ScoreLabel
@onready var play_button: Button = $Content/RightGroup/PlayButton

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	if focus_highlight:
		focus_highlight.visible = false
	if play_button:
		play_button.focus_mode = Control.FOCUS_NONE
		play_button.pressed.connect(_on_play_pressed)
	mouse_entered.connect(_on_mouse_entered)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	_refresh()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_play_pressed()

func _on_mouse_entered() -> void:
	grab_focus()
	_emit_preview()

func _on_focus_entered() -> void:
	if focus_highlight:
		focus_highlight.visible = true
	_emit_preview()

func _on_focus_exited() -> void:
	if focus_highlight:
		focus_highlight.visible = false

func _on_play_pressed() -> void:
	if level_info:
		play_requested.emit(level_info)

func _emit_preview() -> void:
	if level_info:
		preview_requested.emit(level_info)

func setup(info: LevelInformation, icons: Dictionary) -> void:
	level_info = info
	if icons.has("star_filled"):
		star_filled = icons["star_filled"]
	if icons.has("star_empty"):
		star_empty = icons["star_empty"]
	if icons.has("clock"):
		clock_icon = icons["clock"]
	if icons.has("score"):
		score_icon = icons["score"]
	_refresh()

func _refresh() -> void:
	if not level_label or not star_icon:
		return
	if level_info:
		level_label.text = level_info.level_name
		if star_icon:
			star_icon.texture = star_filled if level_info.completed else star_empty
		if time_icon:
			time_icon.texture = clock_icon
		if score_icon_rect:
			score_icon_rect.texture = score_icon
		if time_label:
			time_label.text = _format_time(level_info.fastest_completion_seconds)
		if score_label:
			score_label.text = _format_score(level_info.high_score)
	else:
		level_label.text = ""
		if star_icon:
			star_icon.texture = star_empty
		if time_label:
			time_label.text = "--:--"
		if score_label:
			score_label.text = "N/A"

func _format_time(seconds_value: float) -> String:
	if seconds_value < 0.0:
		return "--:--"
	var total_seconds := int(seconds_value)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%d:%02d" % [minutes, seconds]

func _format_score(score_value: int) -> String:
	if score_value < 0:
		return "N/A"
	return str(score_value)
