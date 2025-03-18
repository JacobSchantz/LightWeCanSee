extends "res://scripts/base_level.gd"

# UI elements
@onready var tutorial_ui = $TutorialUI
@onready var instruction_label = $TutorialUI/InstructionPanel/InstructionLabel
@onready var progress_label = $TutorialUI/ProgressLabel
@onready var blue_box = $PhysicsObjects/BlueBox
@onready var red_face = $PhysicsObjects/BlueBox/RedFace
@onready var green_face = $PhysicsObjects/BlueBox/GreenFace
@onready var yellow_face = $PhysicsObjects/BlueBox/YellowFace
@onready var purple_face = $PhysicsObjects/BlueBox/PurpleFace

# Face offset
const FACE_OFFSET = 0.76  # Offset for all faces

# Simple toggle for red face
var red_face_visible = false
var interaction_area = null

func _ready():
	super._ready()
	
	# Set level properties
	level_name = "Tutorial"
	level_description = "Tutorial Level"
	
	# Initialize UI
	update_instruction("Welcome to the tutorial level! Walk near the box and press E to reveal the secret red face.")
	update_progress("Tutorial Level")
	
	# Make all side faces visible
	green_face.visible = true
	yellow_face.visible = true
	purple_face.visible = true
	
	# Initialize red face to be hidden
	red_face.visible = false
	
	# Set face positions
	red_face.position = Vector3(0, 0, FACE_OFFSET)  # Front position
	green_face.position = Vector3(-FACE_OFFSET, 0, 0)  # Left position
	yellow_face.position = Vector3(FACE_OFFSET, 0, 0)  # Right position
	purple_face.position = Vector3(0, 0, -FACE_OFFSET)  # Back position
	
	# Create simple interaction area
	create_interaction_area()

func create_interaction_area():
	# Create a large Area3D around the box
	interaction_area = Area3D.new()
	interaction_area.name = "BoxInteractionArea"
	interaction_area.collision_layer = 2  # Set to interactable layer
	interaction_area.collision_mask = 1   # Detect player
	add_child(interaction_area)
	
	# Create and set up collision shape for the area
	var shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(3.5, 3.5, 3.5)  # Large enough to be detected from ~1 cube away
	shape.shape = box_shape
	interaction_area.add_child(shape)
	
	# Center it on the box
	interaction_area.global_position = blue_box.global_position
	
	# Add interact method to the area
	interaction_area.set_script(preload("res://scripts/box_interaction.gd"))

# Method to toggle the red face when player presses E
func toggle_red_face():
	red_face_visible = !red_face_visible
	red_face.visible = red_face_visible
	
	if red_face_visible:
		update_instruction("You found the secret red face! Press E again to hide it.")
	else:
		update_instruction("Walk near the box and press E to reveal the secret red face.")

func update_instruction(text):
	if instruction_label:
		instruction_label.text = text

func update_progress(text):
	if progress_label:
		progress_label.text = text

func complete_level():
	# Override the base level's complete_level function
	get_tree().call_group("level_manager", "load_next_level")
