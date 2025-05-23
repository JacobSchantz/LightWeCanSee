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

# YouTube player reference
var youtube_player = null

# Video wall proximity detection
var video_wall_position = Vector3(-8, 2.5, 0)
var video_interaction_distance = 4.0
var video_interaction_label = null
var player_in_video_range = false

# Simple audio player
var audio_player = null

func _ready():
	super._ready()
	
	# Add this level to the "level" group for box interactions
	add_to_group("level")
	
	# Create a simple audio player
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "SimpleSoundPlayer"
	audio_player.stream = load("res://audio/sample.mp3")
	audio_player.autoplay = true
	add_child(audio_player)
	print("Added simple audio player")
	
	# Connect the download button
	download_button.pressed.connect(_on_download_button_pressed)
	
	# Connect the HTTP request completion signal
	http_request.request_completed.connect(_on_request_completed)
	
	# Initialize UI
	update_instruction("Welcome! Move around the box - the closest face will light up. Press E to extend the box in that direction, or Q to shrink it. Press SPACE to jump onto the box.")
	
	# Add video wall to the level
	create_video_wall()
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

# Handle particles on special interactions
func double_particles():
	var interactive_box = $InteractiveBox
	if interactive_box and interactive_box.has_method("setup_particles"):
		interactive_box.setup_particles(true) # Add more particles
		
		# Update instruction text
		update_instruction("Interactive mode activated! More particles added to the box.")

# Create a particle burst effect at the given position
func create_particle_burst(position):
	# Flash the box with a bright color
	var box_mesh = $InteractiveBox/MeshInstance3D
	if box_mesh:
		var original_material = box_mesh.get_surface_override_material(0)
		var flash_material = original_material.duplicate()
		flash_material.albedo_color = Color(1, 0.7, 0.3, 0.8)
		flash_material.emission_enabled = true
		flash_material.emission = Color(1, 0.7, 0.3, 1)
		flash_material.emission_energy_multiplier = 3.0
		
		# Apply the flash material
		box_mesh.set_surface_override_material(0, flash_material)
		
		# Create a tween to restore the original material
		var tween = create_tween()
		tween.tween_interval(0.3)
		tween.tween_callback(func(): box_mesh.set_surface_override_material(0, original_material))

# Handle button press to download the 3D model
func _on_download_button_pressed():
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

# Create and add the YouTube video wall to the level
func create_video_wall():
	# Video details
	var video_id = "hBfhd88DCZA"
	var start_time = 31
	
	# Create a video wall container
	var video_wall_container = Node3D.new()
	video_wall_container.name = "VideoWall"
	
	# Create a simple video wall using a MeshInstance3D with a QuadMesh
	var video_wall = MeshInstance3D.new()
	video_wall.name = "Screen"
	var quad_mesh = QuadMesh.new()
	
	# Set the size of the video screen (16:9 aspect ratio)
	quad_mesh.size = Vector2(3, 1.7)
	
	# Create a material for the video wall
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.1, 0.1, 0.1)
	material.emission_enabled = true
	material.emission = Color(0.8, 0.8, 0.8)
	material.emission_energy_multiplier = 0.5
	
	# Apply mesh and material
	video_wall.mesh = quad_mesh
	video_wall.material_override = material
	
	# Create YouTube player script
	youtube_player = preload("res://scripts/youtube_player.gd").new()
	youtube_player.name = "YouTubePlayer"
	youtube_player.video_ready.connect(func(): print("YouTube player ready"))
	youtube_player.playback_state_changed.connect(func(is_playing): update_status_label())
	video_wall.add_child(youtube_player)
	
	# Initialize the YouTube player with the video ID and start time
	youtube_player.initialize_player(video_id, start_time)
	
	# Create audio player
	audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "AudioPlayer"
	
	# Set audio player properties
	audio_player.unit_size = 3.0  # Sound carries even further
	audio_player.max_distance = 15.0
	audio_player.attenuation_filter_cutoff_hz = 5000.0
	audio_player.autoplay = false  # We'll start it manually after loading
	# Make it loop continuously
	audio_player.stream_paused = false
	audio_player.max_polyphony = 1
	
	# Add audio player to the video wall
	video_wall.add_child(audio_player)
	
	# No HTTP requests needed anymore - using local audio file
	
	# Position the video wall on the wall opposite the door
	video_wall_container.transform.origin = Vector3(-8, 2.5, 0)
	video_wall_container.rotation_degrees.y = -90 # Rotate to face inward
	
	# Add title label
	var title_label = Label3D.new()
	title_label.name = "TitleLabel"
	title_label.text = "YouTube Video\n\"Snowflake - Visual Studio Code\""
	title_label.font_size = 48
	title_label.modulate = Color(1, 1, 1)
	title_label.transform.origin = Vector3(0, 0.7, 0.01) # Top of screen
	
	# Add audio status label
	video_interaction_label = Label3D.new()
	video_interaction_label.name = "AudioStatusLabel"
	video_interaction_label.text = "Music Wall"
	video_interaction_label.font_size = 32
	video_interaction_label.modulate = Color(1, 1, 0.5) # Yellow text
	video_interaction_label.transform.origin = Vector3(0, -0.9, 0.01) # Below screen
	video_interaction_label.visible = true
	
	# Add status label (PAUSED/PLAYING)
	var status_label = Label3D.new()
	status_label.name = "StatusLabel"
	status_label.text = "PAUSED"
	status_label.font_size = 64
	status_label.modulate = Color(1, 1, 1)
	status_label.transform.origin = Vector3(0, 0, 0.01) # Center of screen
	
	# Add resume button
	var resume_button = Area3D.new()
	resume_button.name = "ResumeButton"
	var button_collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(1, 0.5, 0.1)
	button_collision.shape = box_shape
	resume_button.add_child(button_collision)
	
	# Add button visual
	var button_mesh = MeshInstance3D.new()
	var button_box = BoxMesh.new()
	button_box.size = Vector3(1, 0.5, 0.05)
	button_mesh.mesh = button_box
	
	# Button material
	var button_material = StandardMaterial3D.new()
	button_material.albedo_color = Color(0.3, 0.3, 0.3)
	button_material.emission_enabled = true
	button_material.emission = Color(0.5, 0.5, 0.5)
	button_mesh.material_override = button_material
	resume_button.add_child(button_mesh)
	
	# Add button label
	var button_label = Label3D.new()
	button_label.text = "Resume"
	button_label.font_size = 36
	button_label.transform.origin = Vector3(0, 0, 0.03) # Front of button
	resume_button.add_child(button_label)
	
	# Position button below screen
	resume_button.transform.origin = Vector3(0, -1.2, 0)
	
	# Connect button signals using a callback
	resume_button.input_event.connect(func(camera, event, position, normal, shape_idx):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_resume_button_pressed()
	)
	
	# Add all elements to the scene
	video_wall_container.add_child(video_wall)
	video_wall.add_child(title_label)
	video_wall.add_child(status_label)
	video_wall.add_child(video_interaction_label) # Add interaction label
	video_wall_container.add_child(resume_button)
	add_child(video_wall_container)
	
	# Initialize YouTube player
	youtube_player.initialize_player(video_id, start_time)
	youtube_player.playback_state_changed.connect(func(is_playing):
		status_label.text = "PLAYING" if is_playing else "PAUSED"
	)
	
	# Store reference to the player
	self.youtube_player = youtube_player

# Called when the resume button is pressed
func _on_resume_button_pressed():
	# No longer used for audio control - kept for compatibility
	pass

# Handle status label updates
func update_status_label():
	if self.youtube_player:
		var status_label = get_node("VideoWall/Screen/StatusLabel")
		if status_label:
			status_label.text = self.youtube_player.get_playback_state_text()

# All HTTP-related functions have been removed
# We're now using a local audio file with direct playback

# Check player proximity to video wall
func check_video_wall_proximity():
	# Only proceed if player exists and video wall was created
	if player_node == null or video_interaction_label == null:
		return
	
	# Calculate distance between player and video wall
	var distance = player_node.global_position.distance_to(video_wall_position)
	
	# Show interaction prompt if player is close enough
	if distance <= video_interaction_distance:
		if not player_in_video_range:
			# Player just entered range
			player_in_video_range = true
			video_interaction_label.visible = true
			# Optional: highlight the video screen when in range
			var screen = get_node("VideoWall/Screen")
			if screen and screen.material_override:
				screen.material_override.emission_energy_multiplier = 1.0
				
		# Update the player's near_video_wall variable to prevent jumping
		player_node.near_video_wall = true
	else:
		if player_in_video_range:
			# Player just left range
			player_in_video_range = false
			video_interaction_label.visible = false
			# Return screen to normal appearance
			var screen = get_node("VideoWall/Screen")
			if screen and screen.material_override:
				screen.material_override.emission_energy_multiplier = 0.5
				
		# Update the player's near_video_wall variable
		player_node.near_video_wall = false
