extends Node3D

# Pause menu reference
@onready var pause_menu = $CanvasLayer/PauseMenu
var is_paused = false

# Level manager variables
var current_level = 0
var levels = []
@onready var transition_animation = $CanvasLayer/TransitionAnimation if has_node("CanvasLayer/TransitionAnimation") else null
@onready var level_container = $LevelContainer if has_node("LevelContainer") else null

# Base level properties
signal level_completed
@export var level_name: String = "Base Level"
@export var level_description: String = "This is a base level"

func _ready():
	print("Light We Can See - Game Started")
	
	# Make sure the pause menu is hidden when game starts
	if pause_menu:
		pause_menu.visible = false
		
		# Connect pause menu button signals
		var resume_button = pause_menu.get_node("CenterContainer/VBoxContainer/ResumeButton")
		var restart_button = pause_menu.get_node("CenterContainer/VBoxContainer/RestartButton")
		
		if resume_button:
			resume_button.pressed.connect(_on_resume_button_pressed)
		if restart_button:
			restart_button.pressed.connect(_on_restart_button_pressed)
	
	# Initialize level management if we have a level container
	if level_container:
		# Register the levels
		levels = [
			preload("res://scenes/tutorial_level.tscn")
			# Add more levels here as needed
		]
		
		load_level(current_level)
		
	# Base level setup - lock door if present
	var door = find_child("Door", true, false)
	if door:
		door.lock() # Lock the door by default

func _process(delta):
	# Handle pause toggle with ESC key
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()

# ---- PAUSE MENU FUNCTIONS ----
		
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

# ---- LEVEL MANAGER FUNCTIONS ----

func load_level(level_index):
	if not level_container:
		print("No level container found!")
		return
		
	if level_index < 0 or level_index >= levels.size():
		print("Level index out of range!")
		return
		
	# Clear any existing level
	for child in level_container.get_children():
		level_container.remove_child(child)
		child.queue_free()
		
	# Instantiate and add the new level
	var level_instance = levels[level_index].instantiate()
	level_container.add_child(level_instance)
	
	# Connect the level completed signal
	if level_instance.has_signal("level_completed"):
		level_instance.connect("level_completed", Callable(self, "_on_level_completed"))
	
	current_level = level_index
	print("Loaded level: ", current_level + 1)

func _on_level_completed():
	# Play transition animation if we have one
	if transition_animation:
		transition_animation.play("fade_out")
		await transition_animation.animation_finished
		
	# Go to next level
	var next_level = current_level + 1
	if next_level < levels.size():
		load_level(next_level)
	else:
		# Game completed
		print("Congratulations! All levels completed!")
		# TODO: Show game completion screen
		
	if transition_animation:
		transition_animation.play("fade_in")

# ---- BASE LEVEL FUNCTIONS ----

# Method to complete the level
func complete_level():
	var door = find_child("Door", true, false)
	if door:
		door.unlock()
		# Play door opening animation or sound if available
		await get_tree().create_timer(2.0).timeout
	
	# Emit the level completed signal
	emit_signal("level_completed")
