extends Node3D

@export var playground_scene: PackedScene
@export var desert_scene: PackedScene
@export var controls_scene: PackedScene

func _ready():
	# Load scenes if not set in editor (though usually set via editor)
	if not playground_scene: playground_scene = load("res://grind_level_expanded.tscn")
	if not desert_scene: desert_scene = load("res://Desert.tscn")
	if not controls_scene: controls_scene = load("res://Controls.tscn")
	# Ensure mouse is visible for the menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_playground_button_pressed():
	get_tree().change_scene_to_packed(playground_scene)

func _on_desert_button_pressed():
	get_tree().change_scene_to_packed(desert_scene)

func _on_controls_button_pressed():
	var controls_instance = controls_scene.instantiate()
	add_child(controls_instance)
