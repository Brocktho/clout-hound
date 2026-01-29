extends CanvasLayer

@export var message: String = "Completed!"
@export var return_button_text: String = "Main Menu"

@onready var message_label: Label = $Control/PanelContainer/VBoxContainer/CompletedLabel
@onready var return_button: Button = $Control/PanelContainer/VBoxContainer/ReturnButton

func _ready() -> void:
	visible = false
	add_to_group("completion_popup")
	if message_label:
		message_label.text = message
	if return_button:
		return_button.text = return_button_text
		return_button.pressed.connect(_on_return_pressed)

func show_popup() -> void:
	if visible:
		return
	Global.completion_popup_active = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if return_button:
		return_button.grab_focus()

func _on_return_pressed() -> void:
	Global.completion_popup_active = false
	var current_scene := get_tree().current_scene
	if current_scene and current_scene.has_method("return_to_menu"):
		current_scene.call_deferred("return_to_menu")
		return
	get_tree().change_scene_to_file("res://Main.tscn")

func _exit_tree() -> void:
	if Global.completion_popup_active:
		Global.completion_popup_active = false
