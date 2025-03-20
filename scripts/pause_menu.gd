extends Control

# This script handles the pause menu functionality directly

func _ready():
	# Connect button signals directly to our local functions
	$CenterContainer/VBoxContainer/ResumeButton.pressed.connect(_on_resume_button_pressed)
	$CenterContainer/VBoxContainer/RestartButton.pressed.connect(_on_restart_button_pressed)
	$CenterContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)
	
	# Initial state: hidden
	visible = false
	
	# Important: Set process mode to Always so we can process input while game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

# Called when resume button is pressed
func _on_resume_button_pressed():
	print("Resume button pressed")
	toggle_pause()

# Called when restart button is pressed
func _on_restart_button_pressed():
	print("Restart button pressed")
	# Unpause the game
	get_tree().paused = false
	visible = false
	
	# Reload the current scene
	get_tree().reload_current_scene()

# Called when quit button is pressed
func _on_quit_button_pressed():
	print("Quit button pressed")
	# Quit the game
	get_tree().quit()

# Toggle pause state
func toggle_pause():
	var tree = get_tree()
	tree.paused = !tree.paused
	visible = tree.paused
	
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Process input to toggle pause with ESC key
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
