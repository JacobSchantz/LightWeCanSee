extends Control

func _ready():
	# Connect all button signals
	$CenterContainer/VBoxContainer/StartButton.pressed.connect(_on_start_button_pressed)
	$CenterContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)
	
	# Make sure mouse is visible in menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# Start the game by loading level 1
func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/level_manager.tscn")



# Quit the game
func _on_quit_button_pressed():
	get_tree().quit()
