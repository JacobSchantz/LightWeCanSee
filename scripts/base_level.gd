extends Node3D

# Signal emitted when the level is completed
signal level_completed

# Properties for each level
@export var level_name: String = "Base Level"
@export var level_description: String = "This is a base level"

# Doors and physics objects
@onready var door = $Door

# UI elements will be set up in the specific level implementations

# Called when the node enters the scene tree for the first time
func _ready():
	# Base setup for all levels
	if door:
		door.lock() # Lock the door by default

# Method to complete the level
func complete_level():
	if door:
		door.unlock()
		# Play door opening animation or sound if available
		await get_tree().create_timer(2.0).timeout
	
	# Emit the level completed signal
	emit_signal("level_completed")

# Function to create the UI for physics questions
func create_question_ui(question, options, correct_answer_index):
	# This method will be overridden in child classes
	pass

# Function to check the answer
func check_answer(selected_index, correct_index):
	if selected_index == correct_index:
		return true
	return false
