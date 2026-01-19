extends CanvasLayer

func _ready():
	# Ensure the panel is clickable
	set_process_input(true)
	
	# Show/Hide Main Menu button
	var main_menu_button = $Control/CenterContainer/VBoxContainer/MainMenuButton
	if get_tree().current_scene.name == "Main":
		main_menu_button.visible = false
	else:
		main_menu_button.visible = true
	
	# When showing controls, we might want to make sure mouse is visible
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		process_mode = Node.PROCESS_MODE_ALWAYS # Continue processing even if paused
		get_tree().paused = true

func _exit_tree():
	# Restore mouse mode if we're in a level (where it's usually captured)
	# This is a bit simplistic, but should work for now.
	# If we are in Main menu, it's already visible.
	# If we are in level, it was captured.
	if get_tree().current_scene.name != "Main":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().paused = false

func _on_close_button_pressed():
	queue_free()

func _on_main_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Main.tscn")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()
