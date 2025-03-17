extends "res://scripts/base_level.gd"

# UI elements
@onready var tutorial_ui = $TutorialUI
@onready var instruction_label = $TutorialUI/InstructionPanel/InstructionLabel
@onready var progress_label = $TutorialUI/ProgressLabel
@onready var door = $Door
@onready var blue_box = $PhysicsObjects/BlueBox
@onready var red_face = $PhysicsObjects/BlueBox/RedFace
@onready var green_face = $PhysicsObjects/BlueBox/GreenFace
@onready var yellow_face = $PhysicsObjects/BlueBox/YellowFace

# Face rotation
var face_timer = 0.0
var current_face = 0
const FACE_CHANGE_INTERVAL = 2.0  # Change face every 2 seconds
const FACE_OFFSET = 0.76      # Offset for all faces

# Face positions for red face (excluding left and right)
const RED_FACE_POSITIONS = [
	Vector3(0, 0, FACE_OFFSET),    # Front
	Vector3(0, 0, -FACE_OFFSET),   # Back
	Vector3(0, FACE_OFFSET, 0),    # Top
	Vector3(0, -FACE_OFFSET, 0)    # Bottom
]

# Face rotations for red face
const RED_FACE_ROTATIONS = [
	Vector3(0, 0, 0),       # Front (no rotation)
	Vector3(0, PI, 0),      # Back (rotate 180 degrees around Y)
	Vector3(PI/2, 0, 0),    # Top (rotate 90 degrees around X)
	Vector3(-PI/2, 0, 0)    # Bottom (rotate -90 degrees around X)
]

func _ready():
	super._ready()
	
	# Set level properties
	level_name = "Tutorial"
	level_description = "Tutorial Level"
	
	# Initialize UI
	update_instruction("Welcome to the tutorial level! The box has a red face that changes, a green left face, and a yellow right face.")
	update_progress("Tutorial Level")
	
	# Unlock the door
	if door:
		door.unlock()
	
	# Initialize faces - green on left, yellow on right
	green_face.visible = true
	yellow_face.visible = true
	
	# Set initial face positions
	red_face.position = RED_FACE_POSITIONS[0]
	red_face.rotation = RED_FACE_ROTATIONS[0]
	green_face.position = Vector3(-FACE_OFFSET, 0, 0)
	yellow_face.position = Vector3(FACE_OFFSET, 0, 0)

func _process(delta):
	# Update red face position based on timer
	if red_face:
		face_timer += delta
		if face_timer >= FACE_CHANGE_INTERVAL:
			face_timer = 0.0
			change_red_face()

func change_red_face():
	# Move the red face to the next position (excluding left and right)
	current_face = (current_face + 1) % RED_FACE_POSITIONS.size()
	
	# Update position and rotation for the red face
	red_face.position = RED_FACE_POSITIONS[current_face]
	red_face.rotation = RED_FACE_ROTATIONS[current_face]

func update_instruction(text):
	if instruction_label:
		instruction_label.text = text

func update_progress(text):
	if progress_label:
		progress_label.text = text

func complete_level():
	# Override the base level's complete_level function
	get_tree().call_group("level_manager", "load_next_level")
