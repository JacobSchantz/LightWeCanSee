extends "res://scripts/main.gd"

# UI elements
@onready var tutorial_ui = $TutorialUI
@onready var instruction_label = $TutorialUI/InstructionPanel/InstructionLabel
@onready var progress_label = $TutorialUI/ProgressLabel
@onready var blue_box = $InteractiveBox
@onready var red_face = $InteractiveBox/RedFace
@onready var green_face = $InteractiveBox/GreenFace
@onready var yellow_face = $InteractiveBox/YellowFace
@onready var purple_face = $InteractiveBox/PurpleFace
@onready var download_button = $TutorialUI/DownloadButton
@onready var http_request = $HTTPRequest

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
var player_node = null
var detection_radius = 2.0  # Detection radius for all faces

# 3D model download
var model_url = "https://example.com/path/to/model.glb"

func _ready():
	super._ready()
	
	# Add this level to the "level" group for box interactions
	add_to_group("level")
	
	# Connect the download button
	download_button.pressed.connect(_on_download_button_pressed)
	
	
	# Connect the HTTP request completion signal
	http_request.request_completed.connect(_on_request_completed)
	
	# Initialize UI
	update_instruction("Welcome! Move around the box - the closest face will light up. Press E to extend the box in that direction, or Q to shrink it. Press SPACE to jump onto the box.")
	update_progress("Light We Can See")
	
	# Set up mouse capture for first-person control
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Find the player
	await get_tree().process_frame
	player_node = get_tree().get_nodes_in_group("player")[0]
	
	# Set up pause handling
	var level_pause_menu = $PauseMenu
	if level_pause_menu:
		level_pause_menu.visible = false

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

# Process function for handling pause - overrides the main.gd _process
func _process(delta):
	# Handle pause toggle with ESC key
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()

# Toggle pause state
func toggle_pause():
	var level_pause_menu = $PauseMenu
	if level_pause_menu:
		var level_paused = !get_tree().paused
		get_tree().paused = level_paused
		level_pause_menu.visible = level_paused
		
		# Toggle mouse mode based on pause state
		if level_paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Handle player falling out of bounds
func player_fell_out_of_bounds():
	if player_node:
		player_node.restart_level()

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

# Handle button press to download the 3D model
func _on_download_button_pressed():
	var mesh = load(temp_path) as Mesh
var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = mesh
add_child(mesh_instance)
	update_instruction("Downloading 3D model...")
	# Start the download
	http_request.request(model_url)

# Handle the HTTP request completion
func _on_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		update_instruction("Failed to download the 3D model.")
		return

	# Save the downloaded file temporarily
	var temp_path = "user://temp_model.glb"
	var file = FileAccess.open(temp_path, FileAccess.WRITE)
	file.store_buffer(body)
	file.close()
	
	# Load the model as a PackedScene
	var loaded_scene = load(temp_path) as PackedScene
	if loaded_scene:
		# Instance the model and add it to the scene
		var model_instance = loaded_scene.instantiate()
		# Position the model in a visible location
		model_instance.position = Vector3(0, 1.5, -3)  # Adjust position as needed
		add_child(model_instance)
		update_instruction("3D model loaded successfully!")
	else:
		update_instruction("Failed to load the 3D model.")
	
	# Clean up the temporary file
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("temp_model.glb")
