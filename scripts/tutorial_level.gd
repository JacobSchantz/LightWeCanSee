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

# Spacebar toggle
var red_face_visible = false

func _ready():
	super._ready()
	
	# Set level properties
	level_name = "Tutorial"
	level_description = "Tutorial Level"
	
	# Initialize UI
	update_instruction("Welcome to the tutorial level! The box has a green left face, a yellow right face, and a purple back face. Press SPACEBAR to reveal a secret face.")
	update_progress("Tutorial Level")
	
	
	# Initialize faces - green on left, yellow on right, purple on back
	green_face.visible = true
	yellow_face.visible = true
	purple_face.visible = true
	
	# Initialize red face to be hidden
	red_face.visible = false
	red_face_visible = false
	
	# Set face positions
	red_face.position = Vector3(0, 0, FACE_OFFSET)  # Front position
	green_face.position = Vector3(-FACE_OFFSET, 0, 0)
	yellow_face.position = Vector3(FACE_OFFSET, 0, 0)
	purple_face.position = Vector3(0, 0, -FACE_OFFSET)

func _process(delta):
	# Check for spacebar input in process
	if Input.is_action_just_pressed("ui_accept"):
		blue_box.visible = false  # Make the blue box disappear
		await get_tree().create_timer(1.0).timeout # Wait 1 second
		blue_box.visible = true   # Make the blue box reappear
		toggle_red_face()

func toggle_red_face():
	# Toggle red face visibility
	red_face_visible = !red_face_visible
	red_face.visible = red_face_visible
	
	# Update instruction based on visibility
	if red_face_visible:
		update_instruction("You found the secret red face! Press SPACEBAR again to hide it.")
	else:
		update_instruction("The box has a green left face, a yellow right face, and a purple back face. Press SPACEBAR to reveal a secret face.")

func update_instruction(text):
	if instruction_label:
		instruction_label.text = text

func update_progress(text):
	if progress_label:
		progress_label.text = text

func complete_level():
	# Override the base level's complete_level function
	get_tree().call_group("level_manager", "load_next_level")
