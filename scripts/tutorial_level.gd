extends "res://scripts/base_level.gd"

# UI elements
@onready var tutorial_ui = $TutorialUI
@onready var instruction_label = $TutorialUI/InstructionPanel/InstructionLabel
@onready var progress_label = $TutorialUI/ProgressLabel
@onready var door = $Door
@onready var blue_box = $PhysicsObjects/BlueBox
@onready var red_face = $PhysicsObjects/BlueBox/RedFace

func _ready():
	super._ready()
	
	# Set level properties
	level_name = "Tutorial"
	level_description = "Tutorial Level"
	
	# Initialize UI
	update_instruction("Welcome to the tutorial level! Check out the blue box with a red face.")
	update_progress("Tutorial Level")
	
	# Unlock the door
	if door:
		door.unlock()

func update_instruction(text):
	if instruction_label:
		instruction_label.text = text

func update_progress(text):
	if progress_label:
		progress_label.text = text

func complete_level():
	# Override the base level's complete_level function
	get_tree().call_group("level_manager", "load_next_level")
