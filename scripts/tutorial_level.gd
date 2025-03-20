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

# Face interaction variables
var current_face_visible = null
var interaction_area = null
var face_areas = []

# Face data for raycast detection
var faces = []

# Proximity detection
var proximity_areas = []
var player = null
var detection_radius = 2.0  # Detection radius for all faces

func _ready():
	super._ready()
	
	# Add this level to the "level" group for box interactions
	add_to_group("level")
	
	# Initialize UI
	update_instruction("Welcome! Move around the box - the closest face will light up. Press G to toggle box size.")
	update_progress("Light We Can See")
	
	# Set up mouse capture for first-person control
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Find the player
	await get_tree().process_frame
	player = get_tree().get_nodes_in_group("player")[0]
	
	# Set up pause handling
	var pause_menu = find_child("PauseMenu", true, false)
	if pause_menu:
		pause_menu.visible = false

# Update the instruction text
func update_instruction(text):
	if instruction_label:
		instruction_label.text = text

# Update the progress text
func update_progress(text):
	if progress_label:
		progress_label.text = text

# Handle face interaction
func handle_face_interaction(face_index):
	# This function is called when a face is interacted with
	match face_index:
		0: # Red face
			update_instruction("You've interacted with the Red Face!")
		1: # Green face
			update_instruction("You've interacted with the Green Face!")
		2: # Yellow face
			update_instruction("You've interacted with the Yellow Face!")
		3: # Purple face
			update_instruction("You've interacted with the Purple Face!")

# Process function for handling pause
func _process(delta):
	# Handle pause toggle with ESC key
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()

# Toggle pause state
func toggle_pause():
	var pause_menu = find_child("PauseMenu", true, false)
	if pause_menu:
		var is_paused = !get_tree().paused
		get_tree().paused = is_paused
		pause_menu.visible = is_paused
		
		# Toggle mouse mode based on pause state
		if is_paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Handle player falling out of bounds
func player_fell_out_of_bounds():
	if player:
		player.restart_level()

# Optional respawn effect
func play_respawn_effect():
	# Simple screen flash effect
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0.5)  # Semi-transparent white
	flash.size = get_viewport().size
	add_child(flash)
	
	# Animate the flash
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)
