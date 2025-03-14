extends Control

# This script handles the pause menu functionality directly

func _ready():
	# Connect button signals directly to our local functions
	$CenterContainer/VBoxContainer/ResumeButton.pressed.connect(_on_resume_button_pressed)
	$CenterContainer/VBoxContainer/RestartButton.pressed.connect(_on_restart_button_pressed)
	$CenterContainer/VBoxContainer/MainMenuButton.pressed.connect(_on_main_menu_button_pressed)
	
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
	
	# Get the level manager
	var level_manager = get_parent()
	if level_manager and level_manager.has_method("load_level"):
		var current_level = level_manager.current_level
		level_manager.load_level(current_level)
	else:
		print("Could not find level manager or load_level method")

# Called when main menu button is pressed
func _on_main_menu_button_pressed():
	print("Main menu button pressed")
	# Unpause the game
	get_tree().paused = false
	visible = false
	
	# Try to load the main menu scene
	if ResourceLoader.exists("res://scenes/main_menu.tscn"):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		# Fallback: just restart the first level
		var level_manager = get_parent()
		if level_manager and level_manager.has_method("load_level"):
			level_manager.load_level(0)
		else:
			print("Could not find level manager or load_level method")

# Input handling for ESC key
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

# Toggle pause state
func toggle_pause():
	var new_paused_state = !get_tree().paused
	get_tree().paused = new_paused_state
	visible = new_paused_state
	
	# Toggle mouse mode based on pause state
	if new_paused_state:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
