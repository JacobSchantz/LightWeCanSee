extends Node2D

# Pause menu reference
@onready var pause_menu = $PauseMenu
var is_paused = false

func _ready():
	print("Light We Can See - Game Started")
	
	# Make sure the pause menu is hidden when game starts
	if pause_menu:
		pause_menu.visible = false

func _process(delta):
	# Handle pause toggle with ESC key
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()
		
func toggle_pause():
	is_paused = !is_paused
	
	# Set the global pause state
	get_tree().paused = is_paused
	
	# Show/hide the pause menu
	if pause_menu:
		pause_menu.visible = is_paused
		
	# Toggle mouse mode based on pause state
	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_button_pressed():
	toggle_pause()

# Handle restart level button
func _on_restart_button_pressed():
	# Unpause before restarting
	get_tree().paused = false
	
	# Get the current scene and reload it
	get_tree().reload_current_scene()

# Handle main menu button
func _on_main_menu_button_pressed():
	# Unpause before changing scenes
	get_tree().paused = false
	
	# Switch back to main menu scene
	# Note: Adjust the actual main menu scene path as needed
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# Handle quit button
func _on_quit_button_pressed():
	get_tree().quit()
